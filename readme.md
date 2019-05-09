# COD4 Docker dedicated server

*Call of duty 4 dedicated server in a 21MB Docker image*

[![Docker Cod4](https://github.com/qdm12/cod4-docker/raw/master/images/title.png)](https://hub.docker.com/r/qmcgaw/cod4/)

[![Docker Build Status](https://img.shields.io/docker/build/qmcgaw/cod4.svg)](https://hub.docker.com/r/qmcgaw/cod4)

[![GitHub last commit](https://img.shields.io/github/last-commit/qdm12/cod4-docker.svg)](https://github.com/qdm12/cod4-docker/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/y/qdm12/cod4-docker.svg)](https://github.com/qdm12/cod4-docker/issues)
[![GitHub issues](https://img.shields.io/github/issues/qdm12/cod4-docker.svg)](https://github.com/qdm12/cod4-docker/issues)

[![Docker Pulls](https://img.shields.io/docker/pulls/qmcgaw/cod4.svg)](https://hub.docker.com/r/qmcgaw/cod4)
[![Docker Stars](https://img.shields.io/docker/stars/qmcgaw/cod4.svg)](https://hub.docker.com/r/qmcgaw/cod4)
[![Docker Automated](https://img.shields.io/docker/automated/qmcgaw/cod4.svg)](https://hub.docker.com/r/qmcgaw/cod4)

[![Image size](https://images.microbadger.com/badges/image/qmcgaw/cod4.svg)](https://microbadger.com/images/qmcgaw/cod4)
[![Image version](https://images.microbadger.com/badges/version/qmcgaw/cod4.svg)](https://microbadger.com/images/qmcgaw/cod4)

[![Donate PayPal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/qdm12)

| Image size | RAM usage | CPU usage |
| --- | --- | --- |
| 20.9MB | 80MB to 150MB | Low |

It is based on:

- [Alpine 3.9](https://alpinelinux.org)
- [Cod4x](https://github.com/callofduty4x/CoD4x_Server) server built from source

## Requirements

- COD4 Client game
- COD4 running on version 1.7 have to [update to 1.8](#update-your-game)
- Original COD4 **main** and **zone** files required (from the client installation directory)

## Features

- **21MB** image
- [Cod4x server features](https://github.com/callofduty4x/CoD4x_Server#the-most-prominent-features-are)
- Works with custom mods and maps (see the [Mods section](#Mods))
- Easily configurable with [docker-compose](#using-docker-compose)
- Runs without root (safer)
- Run a lightweight Apache HTTP server for your clients to download your mods and usermaps with docker-compose.yml
- Default cod4 configuration file [server.cfg](https://github.com/qdm12/cod4-docker/blob/master/server.cfg)
    - Placed into `./main`
    - Launched by default when not using mods with `exec server.cfg`
    - Easily changeable

## Setup

We assume your *call of duty 4 game* is installed at `/mycod4path`

1. On your host, create the directories `./main`, `./zone`, `./mods` and `./usermaps`.
1. From your Call of Duty 4 installation directory:
    - Copy all the `.iwd` files from `/mycod4path/main` to `./main`
    - Copy all the files from `/mycod4path/zone` to `./zone`
    - (Optional) Copy the mods you want to use from `/mycod4path/mods` to `./mods`
    - (Optional) Copy the maps you want to use from `/mycod4path/usermaps` to `./usermaps`
1. As the container runs as user ID 1000 by default, fix the ownership and permissions:

    ```bash
    chown -R 1000 main mods usermaps zone
    chmod -R 400 zone usermaps
    chmod -R 700 main mods
    ```

    You can also run the container with `--user="root"` (unadvised!)

1. Run the following command as root user on your host:

    ```bash
    docker run -d --name=cod4 -p 28960:28960/udp \
        -v $(pwd)/main:/home/user/cod4/main \
        -v $(pwd)/zone:/home/user/cod4/zone:ro \
        -v $(pwd)/mods:/home/user/cod4/mods \
        -v $(pwd)/usermaps:/home/user/cod4/usermaps:ro \
        qmcgaw/cod4 +map mp_shipment
    ```

    The command line argument `+map mp_shipment` is optional and defaults to `+set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate`

    You can also download and modify the [*docker-compose.yml*](https://raw.githubusercontent.com/qdm12/cod4-docker/master/docker-compose.yml) file and run

    ```bash
    docker-compose up -d
    ```

### HTTP server for custom mods and maps

1. Locate the relevant configuration file - for example `main/server.cfg` or `mods/mymod/server.cfg`
1. Modify/add the following lines & change `youraddress` to your IP or domain name:

    ```c
    set sv_allowdownload "1"
    set sv_wwwDownload "1"
    set sv_wwwBaseURL "http://youraddress:8000" // supports http, https and ftp addresses
    set sv_wwwDlDisconnected "0"
    ```

1. Run the following Docker command:

    ```bash
    docker run -d --name=cod4-http -p 8000:80/tcp --restart=always \
    -v $(pwd)/mods:/usr/local/apache2/htdocs/mods:ro \
    -v $(pwd)/usermaps:/usr/local/apache2/htdocs/usermaps:ro httpd:alpine
    ```

    You can also uncomment the HTTP section in the the [*docker-compose.yml*](https://raw.githubusercontent.com/qdm12/cod4-docker/master/docker-compose.yml) file and run

    ```bash
    docker-compose up -d
    ```

1. You will have to setup port forwarding on your router. Ask me or Google if you need help.

## Update your game

1. Make sure you updated your game to version 1.7 first (see [this](https://cod4x.me/index.php?/forums/topic/12-how-to-install-cod4x/))
1. Download the [COD4x client ZIP file](https://cod4x.me/downloads/cod4x_client.zip)
1. Using Winrar / 7Zip / Winzip, extract the **cod4x_client.zip** to your COD4 game directory
1. Double click on **install.cmd** that you just extracted
1. When launching the multiplayer game, you should see at the bottom right:

![Bottom right screen cod4x](https://github.com/qdm12/cod4-docker/blob/master/images/cod4x-update.png?raw=true)

## Testing

1. Make sure you [updated your COD4 Game to 1.8](#update-your-game)
1. Launch the COD4 multiplayer game
1. Click on **Join Game**
1. Click on **Source** at the top until it's set on *Favourites*
1. Click on **New Favourite** on the top right
1. Enter your host LAN IP Address (i.e. `192.168.1.26`)
    - Add the port if you run it on something else than port UDP 28960 (i.e. `192.168.1.26:28961`)
1. Click on **Refresh** and try to connect to the server in the list

![COD4 screenshot](https://github.com/qdm12/cod4-docker/blob/master/images/test.png?raw=true)

## Mods

Assuming:

- Your mod directory is `./mymod`
- Your main mod configuration file is `./mymod/server.cfg`

Set the command line option to `+set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+set fs_game mods/mymod+exec server.cfg +map_rotate`

## Write protected args

The following parameters are write protected and **can't be placed in the server configuration file**, 
and must be in the `ARGS` environment variable:

- `+set dedicated 2` - 2: open to internet, 1: LAN, 0: localhost
- `+set sv_cheats "1"` - 1 to allow cheats, 0 otherwise
- `+set sv_maxclients "64"` - number of maximum clients
- `+exec server.cfg` if using a configuration file
- `+set fs_game mods/mymod` if using a custom mod
- `+set com_hunkMegs "512"` don't use if not needed
- `+set net_ip 127.0.0.1` don't use if not needed
- `+set net_port 28961` don't use if not needed
- `+map_rotate` OR i.e. `+map mp_shipment` **should be the last launch argument**

## TODOs

- Env variables for plugins etc.
- Replace Apache with Nginx
- Plugins (see https://hub.docker.com/r/callofduty4x/cod4x18-server/)
- Easily switch between mods: script file or management tool
- Built-in mods?

## Acknowledgements

- Credits to the developers of Cod4x server
- The help I had on [Cod4x.me forums](https://cod4x.me/index.php?/forums/)
