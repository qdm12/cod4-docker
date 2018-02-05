#!/usr/bin/env bash

if [ ! -f cod4x18_dedrun ]; then
    echo "Downloading codx18 (cod4x18_dedrun not found)..."
    curl https://cod4x.me/downloads/cod4x_server-linux.zip > cod4x.zip && unzip -o cod4x.zip && rm cod4x.zip
    chmod +x cod4x18_dedrun
else
    echo "cod4x18_dedrun found, not downloading anything."
fi
ARGS=
echo -e "\n\nLaunching Cod4X server...\n\n"
if [[ -z "${ARGS}" ]]; then
    ARGS="+set dedicated 2+set sv_punkbuster 0+set sv_maxclient 4+sv_authorizemode 0+map mp_shipment"
fi
su server -c ./cod4x18_dedrun "$ARGS"