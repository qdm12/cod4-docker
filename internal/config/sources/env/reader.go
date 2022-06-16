package env

import (
	"fmt"

	"github.com/qdm12/cod4-docker/internal/config/settings"
)

type Reader struct{}

func New() *Reader {
	return &Reader{}
}

func (r *Reader) String() string { return "environment variables" }

func (r *Reader) Read() (settings settings.Settings, err error) {
	settings.HTTPServer, err = r.readHTTPServer()
	if err != nil {
		return settings, fmt.Errorf("HTTP server: %w", err)
	}

	return settings, nil
}
