package server

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/qdm12/golibs/logging"
)

func newHandler(rootURL string, logger logging.Logger) http.Handler {
	fileServer := http.NewServeMux()
	modsHandler := http.FileServer(http.Dir("./mods"))
	modsHandler = http.StripPrefix(rootURL+"/mods/", modsHandler)
	usermapsHandler := http.FileServer(http.Dir("./usermaps"))
	usermapsHandler = http.StripPrefix(rootURL+"/usermaps/", usermapsHandler)
	fileServer.Handle(rootURL+"/mods/", modsHandler)
	fileServer.Handle(rootURL+"/usermaps/", usermapsHandler)

	return &handler{
		rootURL:    rootURL,
		logger:     logger, // TODO log middleware
		fileServer: fileServer,
	}
}

type handler struct {
	rootURL    string
	logger     logging.Logger
	fileServer *http.ServeMux
}

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	h.logger.Info("HTTP file server: request URI " + r.RequestURI)
	allowedExtensions := []string{"ff", "iwd"}
	allowed := false
	for _, allowedExtension := range allowedExtensions {
		if strings.HasSuffix(r.RequestURI, allowedExtension) {
			allowed = true
		}
	}
	if !allowed {
		h.logger.Warn("HTTP file server: blocked request URI " + r.RequestURI)
		w.WriteHeader(http.StatusForbidden)
		_, err := w.Write([]byte(fmt.Sprintf(
			"You can only access URIs ending with one of the following extensions: %s",
			strings.Join(allowedExtensions, ", "))))
		if err != nil {
			h.logger.Error(err.Error())
		}
		return
	}
	h.fileServer.ServeHTTP(w, r)
}
