package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"os/user"
	"strings"

	oslib "github.com/qdm12/cod4-docker/internal/os"
	"github.com/qdm12/cod4-docker/internal/params"
	"github.com/qdm12/cod4-docker/internal/server"
	"github.com/qdm12/golibs/command"
	"github.com/qdm12/golibs/files"
	libparams "github.com/qdm12/golibs/params"
	"github.com/qdm12/gosplash"
	"github.com/qdm12/log"
)

var (
	version   string
	buildDate string
	commit    string
)

func main() {
	logger := log.New(log.SetLevel(log.LevelInfo))

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	splashSettings := gosplash.Settings{
		User:       "qdm12",
		Repository: "cod4-docker",
		Emails:     []string{"quentin.mcgaw@gmail.com"},
		Version:    version,
		Commit:     commit,
		BuildDate:  buildDate,
		// Sponsor information
		PaypalUser:    "qmcgaw",
		GithubSponsor: "qdm12",
	}
	for _, line := range gosplash.MakeLines(splashSettings) {
		fmt.Println(line)
	}

	fatal := func(err error) {
		logger.Error(err.Error())
		os.Exit(1)
	}

	user, err := user.Current()
	if err != nil {
		fatal(err)
	}
	uid, gid, err := oslib.ExtractIDs(user)
	if err != nil {
		fatal(err)
	}

	fileManager := files.NewFileManager()

	if err := checkAreWritable(fileManager, uid, gid, "main", "mods"); err != nil {
		fatal(err)
	}

	if err := checkAreReadable(fileManager, uid, gid,
		"zone", "usermaps", "cod4x18_dedrun",
		"steam_api.so", "steamclient.so"); err != nil {
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

	jCod4xExists, err := fileManager.FileExists("main/jcod4x_00.iwd")
	if err != nil {
		fatal(err)
	} else if !jCod4xExists {
		if err := fileManager.CopyFile("jcod4x_00.iwd", "main/jcod4x_00.iwd"); err != nil {
			fatal(err)
		}
	}

	cod4xPatchv2Exists, err := fileManager.FileExists("zone/cod4x_patchv2.ff")
	if err != nil {
		fatal(err)
	} else if !cod4xPatchv2Exists {
		if err := fileManager.CopyFile("cod4x_patchv2.ff", "zone/cod4x_patchv2.ff"); err != nil {
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
	logger.Info("COD4x arguments: " + strings.Join(cod4xArguments, " "))

	settings := params.Settings{}
	env := libparams.NewEnv()
	if err := settings.Read(env); err != nil {
		fatal(err)
	}

	cmd := exec.CommandContext(ctx, "./cod4x18_dedrun", cod4xArguments...)
	cmder := command.NewCmder()

	stdoutLines, stderrLines, waitError, err := cmder.Start(cmd)
	if err != nil {
		fatal(err)
	}

	streamCtx, streamCancel := context.WithCancel(context.Background())
	logStreamLinesDone := make(chan struct{})
	go logStreamLines(streamCtx, logStreamLinesDone, logger, stdoutLines, stderrLines)

	serverDone := make(chan struct{})
	if settings.HTTPServer.Enabled {
		logger.Info("HTTP static files server enabled")
		server := server.New("0.0.0.0:8000", settings.HTTPServer.RootURL, logger)
		go server.Run(ctx, serverDone)
	} else {
		close(serverDone)
	}

	select {
	case <-ctx.Done():
		stop()
	case err := <-waitError:
		close(waitError)
		if err != nil {
			logger.Warn("cod4x server crashed: " + err.Error())
		} else {
			logger.Warn("cod4x server crashed")
		}
		stop()
		cancel()
	}

	<-serverDone
	logger.Info("http server terminated")

	<-waitError
	logger.Info("cod4x server terminated")

	streamCancel()
	<-logStreamLinesDone
	logger.Info("log streaming terminated")
}

var (
	errNotWritable  = errors.New("file is not writable")
	errNotReadable  = errors.New("file is not readable")
	errNotExcutable = errors.New("file is not executable")
)

func checkAreWritable(fileManager files.FileManager, uid, gid int, filePaths ...string) error {
	for _, filePath := range filePaths {
		writable, err := fileManager.IsWritable(filePath, uid, gid)
		if err != nil {
			return err
		} else if !writable {
			return fmt.Errorf("%w: %s, by user with uid %d and gid %d",
				errNotWritable, filePath, uid, gid)
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
			return fmt.Errorf("%w: %s by user with uid %d and gid %d",
				errNotReadable, filePath, uid, gid)
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
			return fmt.Errorf("%w: %s by user with uid %d and gid %d",
				errNotExcutable, filePath, uid, gid)
		}
	}
	return nil
}

func logStreamLines(ctx context.Context, done chan<- struct{},
	logger *log.Logger, stdoutLines, stderrLines chan string) {
	defer close(done)
	for {
		select {
		case <-ctx.Done():
			close(stdoutLines)
			close(stderrLines)
			return
		case line := <-stdoutLines:
			logger.Info(line)
		case line := <-stderrLines: // cod4x logs to stderr
			logger.Info(line)
		}
	}
}
