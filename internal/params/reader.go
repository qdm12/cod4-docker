package params

import libparams "github.com/qdm12/golibs/params"

var _ Reader = (*Settings)(nil)

type Reader interface {
	Read(env libparams.Env) (err error)
}
