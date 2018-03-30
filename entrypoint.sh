#!/bin/sh

# /cod4/main is now mounted so move files in there
cp -f /cod4/xbase_00.iwd /cod4/main/xbase_00.iwd && rm /cod4/xbase_00.iwd
cp /cod4/server.cfg /cod4/main/server.cfg && rm /cod4/server.cfg
echo "Arguments are: ${ARGS}"
./cod4x18_dedrun "${ARGS}"