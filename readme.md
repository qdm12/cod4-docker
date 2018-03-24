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

- Clients running 1.7 have to [update to 1.8](#client-update)
- Original COD4 **main** and **zone** files required

## Features

- [Cod4x server features](https://github.com/callofduty4x/CoD4x_Server#the-most-prominent-features-are)
- Works with custom mods and maps
- Easily configurable
- Docker compose runs a HTTP server for your clients to download your mods and usermaps

## Installation

### Using Docker only

#### Cod4x Server

We assume your *call of duty 4 game* is installed at `/mycod4path`

Two options:

- Directly mount your call of duty 4 directories
    1. Create the directories `mods` and `usermaps` in `mycod4path` if they don't exist
    1. Enter (make sure to change paths):

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
    1. Enter (make sure to change paths):

        ```bash   
        docker run -d --name=cod4 --restart=always -p 28960:28960/udp \
            -v /yourpath/main:/cod4/main -v /yourpath/zone:/cod4/zone \
            -v /yourpath/mods:/cod4/mods -v /yourpath/usermaps:/cod4/usermaps \
            -e 'ARGS=+map mp_shipment' qmcgaw/cod4
        ```

A few notes:
- The container UDP port 28960 is forwarded to the host UDP port 28960
- The environment variable ARGS is optional and defaults to `+map_rotate`

#### Apache HTTP server

If you want your clients to automatically download your mods and usermaps launch a container with:

```bash
docker run -d --name=cod4-http -p 8000/tcp:80/tcp --restart=always \
-v /yourpath/mods:/usr/local/apache2/htdocs/mods \
-v /yourpath/usermaps:/usr/local/apache2/htdocs/usermaps httpd:alpine
```

Note that you can change the `8000` port to any port you like and you will have to reflect the changes 
in the configuration of your server. TODO

### Using Docker Compose




### Mods

Set the environment variable `ARGS` to `+set fs_game mods/YourModName +exec yourConfigurationName.cfg +map_rotate`

## Testing

Run a COD4 client and try to connect to your host LAN IP Address (i.e. `192.168.1.26`)

Note that you need to append `:28967` to the server name if you set the port to something else
than 28960 (default port).


## To dos

- Instructions for client to update
- Finish mods section
- FInish Apache FTP doc and test
- Combine FTP server in docker-compose
- Finish readme and add screenshots
- Run on Alpine (half the image size)
- Show online status
