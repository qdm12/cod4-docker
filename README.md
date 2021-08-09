# COD4 Docker dedicated server

Call of duty 4 dedicated server in a 24MB Docker image

[![Docker Cod4](https://github.com/qdm12/cod4-docker/raw/master/images/title.png)](https://hub.docker.com/r/qmcgaw/cod4/)

[![Build status](https://github.com/qdm12/cod4-docker/workflows/Buildx%20latest/badge.svg)](https://github.com/qdm12/cod4-docker/actions?query=workflow%3A%22Buildx+latest%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/qmcgaw/cod4.svg)](https://hub.docker.com/r/qmcgaw/cod4)
[![Docker Stars](https://img.shields.io/docker/stars/qmcgaw/cod4.svg)](https://hub.docker.com/r/qmcgaw/cod4)

[![GitHub last commit](https://img.shields.io/github/last-commit/qdm12/cod4-docker.svg)](https://github.com/qdm12/cod4-docker/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/y/qdm12/cod4-docker.svg)](https://github.com/qdm12/cod4-docker/issues)
[![GitHub issues](https://img.shields.io/github/issues/qdm12/cod4-docker.svg)](https://github.com/qdm12/cod4-docker/issues)

[![Join Slack channel](https://img.shields.io/badge/slack-@qdm12-yellow.svg?logo=slack)](https://join.slack.com/t/qdm12/shared_invite/enQtOTE0NjcxNTM1ODc5LTYyZmVlOTM3MGI4ZWU0YmJkMjUxNmQ4ODQ2OTAwYzMxMTlhY2Q1MWQyOWUyNjc2ODliNjFjMDUxNWNmNzk5MDk)

[![Donate PayPal](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/qmcgaw)

## Requirements

- COD4 Client game
- COD4 running on version 1.7 have to [update to 1.8-19.0](#update-your-game)
- Original COD4 **main** and **zone** files required (from the client installation directory)

⚠️ Version v19.x and up requires to bind mount `zone` without read only `:ro`

## Features

- [Cod4x server features](https://github.com/callofduty4x/CoD4x_Server#the-most-prominent-features-are)
- Works with custom mods and maps (see the [Mods section](#Mods))
- Built-in HTTP file server for usermaps and mods (only works with .ff and .iwd files for security reasons)
- Runs without root (safer)
- Default cod4 configuration file [server.cfg](https://github.com/qdm12/cod4-docker/blob/master/server.cfg) when not using mods, with `exec server.cfg`
- Multiple Docker images
  - `qmcgaw/cod4:steam`:
    - 368MB and based on Debian Buster Slim
      - Works with the cod4x masterlist
      - [Cod4x](https://github.com/callofduty4x/CoD4x_Server) server built from source statically
      - Other Cod4x files server downloaded from [cod4x.me](https://cod4x.me)
  - `qmcgaw/cod4`, `qmcgaw/cod4:alpine`:
    - Only **24MB** and based on Alpine 3.14
      - Does not work with the cod4x masterlist, see [this](https://github.com/qdm12/cod4-docker/issues/8)
      - [Cod4x](https://github.com/callofduty4x/CoD4x_Server) server built from source statically
  - For each [Github release tag](https://github.com/qdm12/cod4-docker/releases) there are two Docker images built:
    - `:<tag-name>` is the Alpine based image
    - `:<tag-name>-steam` is the larger Debian based image which supports steam and other features
  - Feel free to open an issue for another Docker tag if you need one

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
    chmod -R 700 main mods usermaps zone
    ```

    You can also run the container with `--user="root"` (unadvised!) if this doesn't work

1. Run the following command as root user on your host:

    ```bash
    docker run -d --name=cod4 -p 28960:28960/tcp -p 28960:28960/udp -p 8000:8000/tcp \
        -v /mycod4path/main:/home/user/cod4/main \
        -v /mycod4path/zone:/home/user/cod4/zone \
        -v /mycod4path/mods:/home/user/cod4/mods \
        -v /mycod4path/usermaps:/home/user/cod4/usermaps:ro \
        qmcgaw/cod4 +map mp_shipment
    ```

    The command line argument `+map mp_shipment` is optional and defaults to `+set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate`

    You can also download and modify the [*docker-compose.yml*](https://raw.githubusercontent.com/qdm12/cod4-docker/master/docker-compose.yml) file and run

    ```bash
    docker-compose up -d
    ```

### HTTP server for custom mods and maps

By default, the container runs with an HTTP file server for mods and usermaps on port `8000`.

- You can disable it with `-e HTTP_SERVER=off`
- You can change its published port with for example `-p 9000:8000/tcp`
- You can change its root URL with for example `-e ROOT_URL=/cod4`. This is useful if you use a reverse proxy.

1. Locate the relevant cod4 configuration file - for example `main/server.cfg` or `mods/mymod/server.cfg`
1. Modify/add the following lines & change `youraddress` to your IP or domain name:

    ```c
    set sv_allowdownload "1"
    set sv_wwwDownload "1"
    set sv_wwwBaseURL "http://youraddress:8000" // supports http, https and ftp addresses
    set sv_wwwDlDisconnected "0"
    ```

1. Feel free to open an issue for help setting this up, such as port forwarding or reverse proxy setup help

## Update your game

1. Make sure you updated your game to version 1.7 first (see [this](https://cod4x.me/index.php?/forums/topic/12-how-to-install-cod4x/))
1. Download the [COD4x client ZIP file](https://cod4x.me/downloads/cod4x_client_19_0.zip)
1. Using Winrar / 7Zip / Winzip, extract **cod4x_client_19_0.zip** to your COD4 game directory
1. Go in the extracted directory *cod4-client-manualinstall_19.0* and double click on **install.cmd**
1. When launching the multiplayer game, you should see at the bottom right `19.0`

## Testing

1. Make sure you [updated your COD4 Game to 1.8-19.0](#update-your-game)
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
and must be in the command passed to the container:

- `+set dedicated 2` - 2: open to internet, 1: LAN, 0: localhost
- `+set sv_cheats "1"` - 1 to allow cheats, 0 otherwise
- `+set sv_maxclients "64"` - number of maximum clients
- `+exec server.cfg` if using a configuration file
- `+set fs_game mods/mymod` if using a custom mod
- `+set com_hunkMegs "512"` don't use if not needed
- `+set net_ip 127.0.0.1` don't use if not needed
- `+set net_port 28961` don't use if not needed
- `+map_rotate` OR i.e. `+map mp_shipment` **should be the last launch argument**

By default, the Docker image uses [this command](https://github.com/qdm12/cod4-docker/blob/master/Dockerfile#L68).

## TODOs

- UDP proxy for Windows
- Reload ability of cod4x
- Docker Healthcheck + HTTP healthcheck endpoint (i.e. for K8s)
- Add extra ping with udp proxy
- More env variables
  - Plugins
- [Plugins](https://hub.docker.com/r/callofduty4x/cod4x18-server/)
- Built-in mods?

## Acknowledgements

- Credits to the developers of Cod4x server
- The help I had on [Cod4x.me forums](https://cod4x.me/index.php?/forums/)
