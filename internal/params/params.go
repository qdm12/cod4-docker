package params

import (
	"github.com/qdm12/golibs/logging"
	libparams "github.com/qdm12/golibs/params"
)

// Reader contains methods to obtain parameters.
type Reader interface {
	GetHTTPServer() (bool, error)
	GetHTTPServerRootURL() (string, error)
}

type reader struct {
	envParams libparams.Env
	logger    logging.Logger
}

// Newreader returns a paramsReadeer object to read parameters from
// environment variables.
func NewReader(logger logging.Logger) Reader {
	return &reader{
		envParams: libparams.NewEnv(),
		logger:    logger,
	}
}

func (p *reader) GetHTTPServer() (bool, error) {
	return p.envParams.OnOff("HTTP_SERVER", libparams.Default("on"))
}

func (p *reader) GetHTTPServerRootURL() (rootURL string, err error) {
	return p.envParams.RootURL("ROOT_URL")
}
