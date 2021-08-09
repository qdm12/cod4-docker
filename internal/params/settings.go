package params

import (
	"errors"
	"fmt"

	libparams "github.com/qdm12/golibs/params"
)

type Settings struct {
	HTTPServer HTTPServer
}

var (
	ErrHTTPServer = errors.New("cannot read HTTP server settings")
)

func (s *Settings) Read(env libparams.Env) (err error) {
	err = s.HTTPServer.read(env)
	if err != nil {
		return fmt.Errorf("%w: %s", ErrHTTPServer, err)
	}

	return nil
}
