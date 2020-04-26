package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/qdm12/golibs/command"
	"github.com/qdm12/golibs/files"
	"github.com/qdm12/golibs/logging"
	"github.com/qdm12/golibs/server"

	"github.com/qdm12/cod4-docker/internal/constants"
	oslib "github.com/qdm12/cod4-docker/internal/os"
	"github.com/qdm12/cod4-docker/internal/params"
	"github.com/qdm12/cod4-docker/internal/splash"
)

func main() {
	logger, err := logging.NewLogger(logging.ConsoleEncoding, logging.InfoLevel, -1)
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
	streamMerger := command.NewStreamMerger(ctx)
	go func() {
		err := streamMerger.CollectLines(func(line string) {
			logger.Info(line)
		})
		if err != nil {
			logger.Error(err)
			cancel()
		}
	}()
	stdout, stderr, wait, err := commander.Start(ctx, "./cod4x18_dedrun", cod4xArguments...)
	if err != nil {
		fatal(err)
	}
	go streamMerger.Merge(stdout, command.MergeColor(constants.ColorStdout()))
	go streamMerger.Merge(stderr, command.MergeColor(constants.ColorStderr()))
	httpServer, err := paramsReader.GetHTTPServer()
	if err != nil {
		fatal(err)
	}
	if httpServer {
		logger.Info("HTTP static files server enabled")
		rootURL, err := paramsReader.GetHTTPServerRootURL()
		if err != nil {
			fatal(err)
		}
		fsHandler := makeFileServerHandler(rootURL, logger)
		go func() {
			errs := server.RunServers(ctx, server.Settings{Name: "file server", Addr: "0.0.0.0:8000", Handler: fsHandler})
			for _, err := range errs {
				logger.Error(err)
			}
		}()
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

func makeFileServerHandler(rootURL string, logger logging.Logger) http.HandlerFunc {
	fileServer := http.NewServeMux()
	modsHandler := http.FileServer(http.Dir("./mods"))
	modsHandler = http.StripPrefix(rootURL+"/mods/", modsHandler)
	usermapsHandler := http.FileServer(http.Dir("./usermaps"))
	usermapsHandler = http.StripPrefix(rootURL+"/usermaps/", usermapsHandler)
	fileServer.Handle(rootURL+"/mods/", modsHandler)
	fileServer.Handle(rootURL+"/usermaps/", usermapsHandler)
	return func(w http.ResponseWriter, r *http.Request) {
		uri := r.URL.RequestURI()
		logger.Info("HTTP file server: request URI %s", uri)
		allowedExtensions := []string{"ff", "iwd"}
		allowed := false
		for _, allowedExtension := range allowedExtensions {
			if strings.HasSuffix(uri, allowedExtension) {
				allowed = true
			}
		}
		if !allowed {
			logger.Warn("HTTP file server: blocked request URI %s", uri)
			w.WriteHeader(http.StatusForbidden)
			_, err := w.Write([]byte(fmt.Sprintf("You can only access URIs ending with one of the following extensions: %s", strings.Join(allowedExtensions, ", "))))
			if err != nil {
				logger.Error(err)
			}
			return
		}
		fileServer.ServeHTTP(w, r)
	}
}
