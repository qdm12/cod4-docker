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
	uid, err = strconv.Atoi(u.Uid)
	if err != nil {
		return 0, 0, fmt.Errorf("cannot parse UID: %w", err)
	}
	gid, err = strconv.Atoi(u.Gid)
	if err != nil {
		return 0, 0, fmt.Errorf("cannot parse GID: %w", err)
	}
	return uid, gid, nil
}
