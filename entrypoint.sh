#!/bin/sh

wget https://cod4x.me/downloads/cod4x_server-linux.zip
unzip -o cod4x_server-linux.zip
rm cod4x_server-linux.zip
chmod +x cod4x18_dedrun
if [ -z "${ARGS}" ]; then
    ARGS="+map_rotate"
fi
echo "Arguments are: ${ARGS}"
./cod4x18_dedrun "${ARGS}"