package settings

import (
	"fmt"
)

type Settings struct {
	HTTPServer HTTPServer
}

func (s *Settings) SetDefaults() {
	s.HTTPServer.setDefaults()
}

func (s *Settings) Validate() (err error) {
	err = s.HTTPServer.validate()
	if err != nil {
		return fmt.Errorf("HTTP server: %w", err)
	}

	return nil
}
