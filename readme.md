# COD4 Docker dedicated server

Runs a Call of duty 4 Modern Warfare dedicated server in a Docker container.

[![Docker Cod4](https://github.com/qdm12/cod4-docker/raw/master/readme/title.png)](https://hub.docker.com/r/qmcgaw/cod4/)

Docker build:
[![Build Status](https://travis-ci.org/qdm12/cod4-docker.svg?branch=master)](https://travis-ci.org/qdm12/cod4-docker)

Cod4x build:
[![Build Status](https://travis-ci.org/callofduty4x/CoD4x_Server.svg?branch=master)](https://travis-ci.org/callofduty4x/CoD4x_Server)

This image is **373 MB** and consumes **368 MB** of RAM (no player)

It is based on:
- [Cod4x](https://cod4x.me/) Linux Server
- Debian
- g++-multilib
    
## Requirements

- COD4 running on version 1.7 have to [update to 1.8](#update-your-game)
- Original COD4 **main** and **zone** files required
- COD4 Client game running on Windows

## Features

- [Cod4x server features](https://github.com/callofduty4x/CoD4x_Server#the-most-prominent-features-are)
- Works with custom mods and maps (see the [Mods section](#Mods))
- Easily configurable with [docker-compose](#using-docker-compose)
- Run a lightweight Apache HTTP server for your clients to download your mods and usermaps

## Installation

We assume your *call of duty 4 game* is installed at `/mycod4path`

1. On your host, create the following directories:
    - `/yourpath/main`
    - `/yourpath/zone`
    - `/yourpath/mods`
    - `/yourpath/usermaps`
1. From your Call of Duty 4 installation directory:
    1. Copy all the `.iwd` files from `/mycod4path/main` to `/yourpath/main`
    1. Copy all the files from `/mycod4path/zone` to `/yourpath/zone`
    1. (Optional) Copy the mods you want to use from `/mycod4path/mods` to `/yourpath/mods`
    1. (Optional) Copy the maps you want to use from `/mycod4path/usermaps` to `/yourpath/usermaps`

### Option 1 of 2: Using Docker Compose

1. Download [docker-compose.yml](https://raw.githubusercontent.com/qdm12/cod4-docker/master/docker-compose.yml)
1. Edit *docker-compose.yml* and replace:
    - `/yourpath` with your actual host path
    - (Optional) the port mappings of each of the 2 containers
    - (Optional) `+map mp_shipment` with the argument you want (i.e. to use mods)
1. In your configuration file, say `server.cfg`, add the following lines:

    ```c
    set sv_allowdownload "1"
    set sv_wwwDownload "1"
    set sv_wwwBaseURL "http://youraddress"
    set sv_wwwDlDisconnected "0"
    ```

    Note that `http://youraddress` can be:
    - A LAN IP address `http://192.168.1.16:8000`
    - An external IP address `http://124.265.140.25:8000` (depends on port forwarding on your router)
    - A domain name `http://mydomain.com:8000` (depends on port forwarding on your router)
    - A domain name with https `https://mydomain.com:8000` (depends on port forwarding on your router)
    - Even FTP (unsure) `ftp://mydomain.com:8001` (depends on port forwarding on your router)
1. Launch the two containers with:

    ```bash   
    docker-compose up -d
    ```

### Option 2 of 2: Using Docker only

#### Cod4x Server

In a terminal, enter (make sure to change paths):

```bash   
docker run -d --name=cod4 --restart=always -p 28960:28960/udp \
    -v /yourpath/main:/cod4/main -v /yourpath/zone:/cod4/zone \
    -v /yourpath/mods:/cod4/mods -v /yourpath/usermaps:/cod4/usermaps \
    -e 'ARGS=+map mp_shipment' qmcgaw/cod4
```

- The container UDP port 28960 is forwarded to the host UDP port 28960
- The environment variable ARGS is optional and defaults to `+map_rotate`

#### Apache HTTP server (Optional)

If you want your clients to automatically download your mods and usermaps:
1. Launch a lightweight HTTP server container with:

    ```bash
    docker run -d --name=cod4-http -p 8000:80/tcp --restart=always \
    -v /yourpath/mods:/usr/local/apache2/htdocs/mods \
    -v /yourpath/usermaps:/usr/local/apache2/htdocs/usermaps httpd:alpine
    ```
    
    Note that you can change the `8000` port to any port you like.
1. In your configuration file, say `server.cfg`, add the following lines:

    ```c
    set sv_allowdownload "1"
    set sv_wwwDownload "1"
    set sv_wwwBaseURL "http://youraddress"
    set sv_wwwDlDisconnected "0"
    ```

    Note that `http://youraddress` can be:
    - A LAN IP address `http://192.168.1.16:8000`
    - An external IP address `http://124.265.140.25:8000` (depends on port forwarding on your router)
    - A domain name `http://mydomain.com:8000` (depends on port forwarding on your router)
    - A domain name with https `https://mydomain.com:8000` (depends on port forwarding on your router)
    - Even FTP (unsure) `ftp://mydomain.com:8001` (depends on port forwarding on your router)

## Mods

Assuming:
- Your mod directory is `mymod` in `/yourpath/mods/`
- Your main configuration file is `server.cfg` in `/yourpath/mods/mymod/`

Set the environment variable `ARGS` to:
```
+set fs_game mods/mymod +exec server.cfg +map_rotate
```

## Update your game

1. Make sure you updated your game to version 1.7 first (see [this](https://cod4x.me/index.php?/forums/topic/12-how-to-install-cod4x/))
1. Download the [COD4x client ZIP file](https://cod4x.me/downloads/cod4x_client.zip)
1. Using Winrar / 7Zip / Winzip, extract the **cod4x_client.zip** to your COD4 game directory
1. Double click on **install.cmd** that you just extracted
1. When launching the multiplayer game, you should see at the bottom right:

![Bottom right screen cod4x](https://github.com/qdm12/cod4-docker/blob/master/readme/cod4x-update.png)

## Testing

1. Make sure you [updated your COD4 Game to 1.8](#update-your-game)
1. Launch the COD4 multiplayer game (iw3mp.exe)
1. Click on **Join Game**
1. Click on **Source** at the top until it's set on *Favourites*
1. Click on **New Favourite** on the top right
1. Enter your host LAN IP Address (i.e. `192.168.1.26`)
    - Add the port if you run it on something else than port UDP 28960 (i.e. `192.168.1.26:28961`)
1. Click on **Refresh** and try to connect to the server in the list

## To dos

- docker-compose section
- Finish readme and add screenshots
- Allow 64 players for ROTU servers i.e.
- Leetmode
- Run on Alpine (half the image size)
- Show online status

## Acknowledgements

- Credits to the developers of Cod4x server
- The help I had on [Cod4x.me forums](https://cod4x.me/index.php?/forums/)

