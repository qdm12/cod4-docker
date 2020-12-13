package main

import (
	"context"
	"fmt"
	"os"
	"strings"
	"sync"

	"github.com/qdm12/cod4-docker/internal/constants"
	oslib "github.com/qdm12/cod4-docker/internal/os"
	"github.com/qdm12/cod4-docker/internal/params"
	"github.com/qdm12/cod4-docker/internal/server"
	"github.com/qdm12/cod4-docker/internal/splash"
	"github.com/qdm12/golibs/command"
	"github.com/qdm12/golibs/files"
	"github.com/qdm12/golibs/logging"
)

func main() {
	logger, err := logging.NewLogger(logging.ConsoleEncoding, logging.InfoLevel)
	if err != nil {
		panic(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	paramsReader := params.NewReader(logger)
	fmt.Println(splash.Splash(paramsReader))

	fatal := func(args ...interface{}) {
		logger.Error(args...)
		os.Exit(1)
	}

	osManager := oslib.NewManager()
	uid, gid, err := osManager.GetCurrentUser()
	if err != nil {
		fatal(err)
	}

	fileManager := files.NewFileManager()

	if err := checkAreWritable(fileManager, uid, gid, "main", "mods"); err != nil {
		fatal(err)
	}

	if err := checkAreReadable(fileManager, uid, gid, "zone", "usermaps", "cod4x18_dedrun", "steam_api.so", "steamclient.so"); err != nil {
		fatal(err)
	}

	if err := checkAreExecutable(fileManager, uid, gid, "cod4x18_dedrun", "steam_api.so", "steamclient.so"); err != nil {
		fatal(err)
	}

	// TODO better checks for files, maybe using checksums

	xBaseExists, err := fileManager.FileExists("main/xbase_00.iwd")
	if err != nil {
		fatal(err)
	} else if !xBaseExists {
		if err := fileManager.CopyFile("xbase_00.iwd", "main/xbase_00.iwd"); err != nil {
			fatal(err)
		}
	}

	defaultServerConfigExists, err := fileManager.FileExists("main/server.cfg")
	if err != nil {
		fatal(err)
	} else if !defaultServerConfigExists {
		if err := fileManager.CopyFile("server.cfg", "main/server.cfg"); err != nil {
			fatal(err)
		}
	}

	cod4xArguments := make([]string, len(os.Args))
	cod4xArguments[0] = "+set fs_homepath /home/user/cod4"
	for i := 1; i < len(cod4xArguments); i++ {
		cod4xArguments[i] = os.Args[i]
	}
	logger.Info("COD4x arguments: %s", strings.Join(cod4xArguments, " "))

	commander := command.NewCommander()
	streamMerger := command.NewStreamMerger()
	go streamMerger.CollectLines(ctx, func(line string) {
		logger.Info(line)
	}, func(err error) {
		logger.Error(err)
		cancel()
	})
	stdout, stderr, wait, err := commander.Start(ctx, "./cod4x18_dedrun", cod4xArguments...)
	if err != nil {
		fatal(err)
	}
	go streamMerger.Merge(ctx, stdout, command.MergeColor(constants.ColorStdout()))
	go streamMerger.Merge(ctx, stderr, command.MergeColor(constants.ColorStderr()))
	httpServer, err := paramsReader.GetHTTPServer()
	if err != nil {
		fatal(err)
	}

	wg := &sync.WaitGroup{}

	if httpServer {
		logger.Info("HTTP static files server enabled")
		rootURL, err := paramsReader.GetHTTPServerRootURL()
		if err != nil {
			fatal(err)
		}
		server := server.New("0.0.0.0:8000", rootURL, logger)
		go server.Run(ctx, wg)
	}
	if err := wait(); err != nil {
		fatal(err)
	}
}

func checkAreWritable(fileManager files.FileManager, uid, gid int, filePaths ...string) error {
	for _, filePath := range filePaths {
		writable, err := fileManager.IsWritable(filePath, uid, gid)
		if err != nil {
			return err
		} else if !writable {
			return fmt.Errorf("%s is not writable by user with uid %d and gid %d", filePath, uid, gid)
		}
	}
	return nil
}

func checkAreReadable(fileManager files.FileManager, uid, gid int, filePaths ...string) error {
	for _, filePath := range filePaths {
		readable, err := fileManager.IsReadable(filePath, uid, gid)
		if err != nil {
			return err
		} else if !readable {
			return fmt.Errorf("%s is not readable by user with uid %d and gid %d", filePath, uid, gid)
		}
	}
	return nil
}

func checkAreExecutable(fileManager files.FileManager, uid, gid int, filePaths ...string) error {
	for _, filePath := range filePaths {
		executable, err := fileManager.IsExecutable(filePath, uid, gid)
		if err != nil {
			return err
		} else if !executable {
			return fmt.Errorf("%s is not executable by user with uid %d and gid %d", filePath, uid, gid)
		}
	}
	return nil
}
