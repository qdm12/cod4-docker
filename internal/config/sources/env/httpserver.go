package env

import (
	"fmt"

	"github.com/qdm12/cod4-docker/internal/config/settings"
)

func (r *Reader) readHTTPServer() (settings settings.HTTPServer, err error) {
	settings.Enabled, err = envToBoolPtr("HTTP_SERVER")
	if err != nil {
		return settings, fmt.Errorf("environment variable HTTP_SERVER: %w", err)
	}

	settings.RootURL = envToStringPtr("ROOT_URL")

	return settings, nil
}
