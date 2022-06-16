package settings

import (
	"errors"
	"fmt"
	"path"
	"regexp"
)

type HTTPServer struct {
	Enabled *bool
	RootURL *string
}

func (h *HTTPServer) setDefaults() {
	if h.Enabled == nil {
		h.Enabled = new(bool)
		*h.Enabled = true
	}

	if h.RootURL == nil {
		h.RootURL = new(string)
		*h.RootURL = "" // already have / from paths of router
	}
}

var regexRootURL = regexp.MustCompile(`^\/[a-zA-Z0-9\-_/\+]*$`)

var (
	ErrRootURLMalformed = errors.New("root URL is malformed")
)

func (h *HTTPServer) validate() error {
	rootURL := path.Clean(*h.RootURL)
	if !regexRootURL.MatchString(rootURL) {
		return fmt.Errorf("%w: %s", ErrRootURLMalformed, *h.RootURL)
	}

	return nil
}
