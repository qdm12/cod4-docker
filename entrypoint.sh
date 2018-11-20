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

test -w "/cod4/main"
exitOnError $? "/cod4/main is not writable, please fix its ownership and/or permissions"
test -w "/cod4/mods"
exitOnError $? "/cod4/mods is not writable, please fix its ownership and/or permissions"
test -r "/cod4/usermaps"
exitOnError $? "/cod4/usermaps is not readable, please fix its ownership and/or permissions"
test -r "/cod4/zone"
exitOnError $? "/cod4/zone is not readable, please fix its ownership and/or permissions"
# TODO More checks
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