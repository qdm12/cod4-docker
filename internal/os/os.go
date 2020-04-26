package os

import (
	"fmt"
	"os/user"
	"strconv"
)

type Manager interface {
	GetCurrentUser() (uid, gid int, err error)
}

type manager struct {
	currentUser func() (*user.User, error)
}

func NewManager() Manager {
	return &manager{
		currentUser: user.Current,
	}
}

func (m *manager) GetCurrentUser() (uid, gid int, err error) {
	u, err := m.currentUser()
	if err != nil {
		return 0, 0, err
	}
	uid64, err := strconv.ParseInt(u.Uid, 10, 64)
	if err != nil {
		return 0, 0, fmt.Errorf("cannot parse UID: %w", err)
	}
	gid64, err := strconv.ParseInt(u.Gid, 10, 64)
	if err != nil {
		return 0, 0, fmt.Errorf("cannot parse GID: %w", err)
	}
	return int(uid64), int(gid64), nil
}
