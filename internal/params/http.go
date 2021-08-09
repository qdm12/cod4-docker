package params

import (
	"fmt"

	libparams "github.com/qdm12/golibs/params"
)

type HTTPServer struct {
	Enabled bool
	RootURL string
}

func (settings *HTTPServer) read(env libparams.Env) (err error) {
	settings.Enabled, err = env.OnOff("HTTP_SERVER", libparams.Default("on"))
	if err != nil {
		return fmt.Errorf("environment variable HTTP_SERVER: %w", err)
	}

	settings.RootURL, err = env.RootURL("ROOT_URL")
	if err != nil {
		return fmt.Errorf("environment variable ROOT_URL: %w", err)
	}

	return nil
}
