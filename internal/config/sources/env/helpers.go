package env

import (
	"os"
	"strings"

	"github.com/qdm12/govalid/binary"
)

// getCleanedEnv returns an environment variable value with
// surrounding spaces and trailing new line characters removed.
func getCleanedEnv(envKey string) (value string) {
	value = os.Getenv(envKey)
	value = strings.TrimSpace(value)
	value = strings.TrimSuffix(value, "\r\n")
	value = strings.TrimSuffix(value, "\n")
	return value
}

func envToBoolPtr(envKey string) (boolPtr *bool, err error) {
	s := getCleanedEnv(envKey)
	if s == "" {
		return nil, nil //nolint:nilnil
	}
	value, err := binary.Validate(s)
	if err != nil {
		return nil, err
	}
	return &value, nil
}

func envToStringPtr(envKey string) (stringPtr *string) {
	s := getCleanedEnv(envKey)
	if s == "" {
		return nil
	}
	return &s
}
