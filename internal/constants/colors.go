package constants

import "github.com/fatih/color"

func ColorStdout() color.Color {
	return *color.New(color.FgCyan)
}

func ColorStderr() color.Color {
	return *color.New(color.FgHiRed)
}
