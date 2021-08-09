package os

import (
	"errors"
	"fmt"
	"os/user"
	"strconv"
)

var (
	ErrParseUID = errors.New("cannot parse user UID")
	ErrParseGID = errors.New("cannot parse user GID")
)

func ExtractIDs(u *user.User) (uid, gid int, err error) {
	uid, err = strconv.Atoi(u.Uid)
	if err != nil {
		return 0, 0, fmt.Errorf("%w: %s", ErrParseUID, err)
	}
	gid, err = strconv.Atoi(u.Gid)
	if err != nil {
		return 0, 0, fmt.Errorf("%w: %s", ErrParseGID, err)
	}
	return uid, gid, nil
}
