#!/bin/sh

# /cod4/main is now mounted so move xbase_00.iwd
mv /cod4/xbase_00.iwd /cod4/main/xbase_00.iwd
if [ -z "${ARGS}" ]; then
    ARGS="+map_rotate"
fi
echo "Arguments are: ${ARGS}"
./cod4x18_dedrun "${ARGS}"