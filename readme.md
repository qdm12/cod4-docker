# COD4 Docker dedicated server

Runs a Call of duty 4 Modern Warfare dedicated server in a Docker container.

[![Docker Cod4](https://github.com/qdm12/cod4-docker/raw/master/readme/title.png)](https://hub.docker.com/r/qmcgaw/cod4/)

Docker build:
[![Build Status](https://travis-ci.org/qdm12/cod4-docker.svg?branch=master)](https://travis-ci.org/qdm12/cod4-docker)

Cod4x build:
[![Build Status](https://travis-ci.org/callofduty4x/CoD4x_Server.svg?branch=master)](https://travis-ci.org/callofduty4x/CoD4x_Server)

This image is **351 MB** and consumes **443 MB** of RAM (no player)

It is based on:
- [Cod4x](https://cod4x.me/) server program
- Debian
- Unzip and wget to download the latest Cod4x
- Cod4x dependencies: *g++-multilib*
    
## Requirements

- Clients running 1.7 have to [update to 1.8](#client-update)
- Original COD4 **main** and **zone** files required

## Features

- [Cod4x server features](https://github.com/callofduty4x/CoD4x_Server#the-most-prominent-features-are)
- Works with custom mods and maps
- Easily configurable

## Installation

[![Docker container](https://github.com/qdm12/cod4-docker/raw/master/readme/docker.png)](https://www.docker.com/)

1. Make sure you have [Docker](https://docs.docker.com/install/) installed

### Using Docker only

We assume your call of duty 4 game is installed at `/mycod4path`

Two options:

- Directly mount your call of duty 4 directories
    1. Make sure to create the directories `mods` and `usermaps` in `mycod4path` if they don't exist
    1. Enter

        ```bash   
        docker run -d --name=cod4 --restart=always -p 28960:28960/udp \
            -v /mycod4path/main:/cod4/main -v /mycod4path/zone:/cod4/zone \
            -v /mycod4path/mods:/cod4/mods -v /mycod4path/usermaps:/cod4/usermaps \
            -e 'ARGS=+map mp_shipment' qmcgaw/cod4
        ```

- Copy some call of duty 4 directories for a fresh server install
    1. On your host, create the following directories:
        - `yourpath/main`
        - `yourpath/zone`
        - `yourpath/mods`
        - `yourpath/usermaps`
    1. From your Call of Duty 4 installation directory:
        1. Copy all the `.iwd` files from `/mycod4path/main` to `yourpath/main`
        1. Copy all the files from `/mycod4path/zone` to `yourpath/zone`
        1. Copy the mods you want to use from `/mycod4path/mods` to `yourpath/mods`
        1. Copy the maps you want to use from `/mycod4path/usermaps` to `yourpath/usermaps`
    1. Enter

        ```bash   
        docker run -d --name=cod4 --restart=always -p 28960:28960/udp \
            -v /yourpath/main:/cod4/main -v /yourpath/zone:/cod4/zone \
            -v /yourpath/mods:/cod4/mods -v /yourpath/usermaps:/cod4/usermaps \
            -e 'ARGS=+map mp_shipment' qmcgaw/cod4
        ```

- The container port UDP 28960 is forwarded to the host port UDP 28960
- The following environment variables are set with the flag `-e`:

| **Environement variable** | **Value** | *Optional* |
| --- | --- | --- |
| ARGS | Arguments to cod4x executable | Yes, `+map_rotate` |


### Using Docker Compose




### Mods

Set `ARGS` to `+set fs_game mods/SERVER+map_rotate`

## Testing

1. Run a COD4 client and try to connect to `yourhostIPaddress:28960`

## To dos

- Run on Alpine (half the image size)
- Finish readme and add screenshots
- Combine FTP server in docker-compose
- Show online status
