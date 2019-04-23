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
  ln -s /cod4/main ./main
fi
test -w "./mods"
if [ $? != 0 ]; then
  test -w "/cod4/mods"
  if [ $? != 0 ]; then
    exitOnError $? "mods is not writable, please fix its ownership and/or permissions"
  fi
  ln -s /cod4/mods ./mods
fi
test -r "./usermaps"
if [ $? != 0 ]; then
  test -r "/cod4/usermaps"
  if [ $? != 0 ]; then
    exitOnError $? "usermaps is not readable, please fix its ownership and/or permissions"
  fi
  ln -s /cod4/usermaps ./usermaps
fi
test -r "./zone"
if [ $? != 0 ]; then
  test -r "/cod4/zone"
  if [ $? != 0 ]; then
    exitOnError $? "zone is not readable, please fix its ownership and/or permissions"
  fi
  ln -s /cod4/zone ./zone
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
./cod4x18_dedrun "$@"
status=$?
printf "\n =========================================\n"
printf " Exit with status $status\n"
printf " =========================================\n"