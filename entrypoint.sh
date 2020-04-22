#!/bin/sh

printf " =========================================\n"
printf " =========================================\n"
printf " ======== COD4X Dedicated Server =========\n"
printf " =========================================\n"
printf " =========================================\n"
printf " == by github.com/qdm12 - Quentin McGaw ==\n\n"

exitOnError(){
  # $1 must be set to $?
  status=$1
  message=$2
  [ "$message" != "" ] || message="Error!"
  if [ $status != 0 ]; then
    printf "$message (status $status)\n"
    exit $status
  fi
}

test -w "./main"
if [ $? != 0 ]; then
  test -w "/cod4/main"
  if [ $? != 0 ]; then
    exitOnError $? "main is not writable, please fix its ownership and/or permissions"
  fi
  printf "Compatibility: linking /cod4/main to /home/user/cod4/main\n"
  ln -s /cod4/main ./main
  exitOnError $? "linking of /cod4/main to /home/user/cod4/main failed"
fi
test -w "./mods"
if [ $? != 0 ]; then
  test -w "/cod4/mods"
  if [ $? != 0 ]; then
    exitOnError $? "mods is not writable, please fix its ownership and/or permissions"
  fi
  printf "Compatibility: linking /cod4/mods to /home/user/cod4/mods\n"
  ln -s /cod4/mods ./mods
  exitOnError $? "linking of /cod4/mods to /home/user/cod4/mods failed"
fi
test -r "./usermaps"
if [ $? != 0 ]; then
  test -r "/cod4/usermaps"
  if [ $? != 0 ]; then
    exitOnError $? "usermaps is not readable, please fix its ownership and/or permissions"
  fi
  printf "Compatibility: linking /cod4/usermaps to /home/user/cod4/usermaps\n"
  ln -s /cod4/usermaps ./usermaps
  exitOnError $? "linking of /cod4/usermaps to /home/user/cod4/usermaps failed"
fi
test -r "./zone"
if [ $? != 0 ]; then
  test -r "/cod4/zone"
  if [ $? != 0 ]; then
    exitOnError $? "zone is not readable, please fix its ownership and/or permissions"
  fi
  printf "Compatibility: linking /cod4/zone to /home/user/cod4/zone\n"
  ln -s /cod4/zone ./zone
  exitOnError $? "linking of /cod4/zone to /home/user/cod4/zone failed"
fi
# TODO More checks
# No sym links as they don't work on remote shares in example
if [ ! -f main/xbase_00.iwd ]; then
  cp xbase_00.iwd main/xbase_00.iwd
fi
exitOnError $?
if [ ! -f main/server.cfg ]; then
  cp server.cfg main/server.cfg
fi
exitOnError $?
printf "COD4X arguments are: $@\n\n"
./cod4x18_dedrun +set fs_homepath /home/user/cod4 "$@"
status=$?
printf "\n =========================================\n"
printf " Exit with status $status\n"
printf " =========================================\n"