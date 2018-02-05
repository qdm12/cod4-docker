#!/usr/bin/env bash

if [ ! -f cod4x18_dedrun ]; then
    echo "Downloading codx18 (cod4x18_dedrun not found)..."
    curl https://cod4x.me/downloads/cod4x_server-linux.zip > cod4x.zip && unzip -o cod4x.zip && rm cod4x.zip
    chmod +x cod4x18_dedrun
else
    echo "cod4x18_dedrun found, not downloading anything."
fi
if [[ -z "${ARGS}" ]]; then
    ARGS="+set net_port 28961 +map mp_killhousey"
fi
su server -c ./cod4x18_dedrun "$ARGS"