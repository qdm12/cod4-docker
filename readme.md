# COD4 Docker dedicated server

Runs a Call of duty 4 Modern Warfare dedicated server in a Docker container.

- Based on:
    - [Cod4x](https://cod4x.me/) server program
    - [Ubuntu](https://www.docker.com/docker-ubuntu)
    - Unzip and curl to download the latest Cod4x
    - Cod4x dependencies: nasm build-essential gcc-multilib g++-multilib
- Compatible with COD4 1.7 clients
- Original COD4 **main** and **zone** files required
- Works with custom mods and usermaps

## Installation

1. Make sure you have [Docker](https://docs.docker.com/install/) installed
2. Obtaining the Docker image
    - Option 1 of 2: Docker Hub Registry
        1. You can check my [Docker Hub page](https://hub.docker.com/r/qmcgaw/cod4/) for more information.
            
            [![Docker Hub page](readme/dockerhub.png)](https://hub.docker.com/r/qmcgaw/cod4/)
        
        2. In a terminal, download the image with:
            ```bash
            sudo docker pull qmcgaw/cod4
            ```
    - Option 2 of 2: Build the image
        1. Download the repository files or `git clone` them
        2. With a terminal, go in the directory where the *Dockerfile* is located
        3. Build the image with:
            ```bash
            sudo docker build -t qmcgaw/cod4 ./
            ```
3. Launching the Docker container from the image (replace the values below):
    ```bash
    sudo docker run -d --name=cod4 --restart=always -p 28960:28960/udp -v /cod4/main:/home/server/main -v /cod4/zone:/home/server/zone -v /cod4/mods:/home/server/mods -v /cod4/usermaps:/home/server/usermaps -e 'ARGS=+map mp_shipment' qmcgaw/cod4
    ```

Note the following.
- The container port UDP 28960 is forwarded to the host port UDP 28960
- The following environment variables are set with the flag `-e`:

| **Environement variable** | **Value** | *Optional* |
| --- | --- | --- |
| ARGS | Arguments to cod4x executable | Yes, see *script.sh* for the default |

- The following paths are mounted with the flag `-v` (the host path can be different !):

| **Host path** | **Container path** | *Optional* |
| --- | --- | --- |
| /cod4/main | /home/server/main | No (only **iwd** files are required) |
| /cod4/zone | /home/server/zone | No |
| /cod4/mods | /home/server/mods | Yes, only if you want to run mods with `ARGS` |
| /cod4/usermaps | /home/server/usermaps | Yes, only if you want to run custom maps with `ARGS` |


You can also run the container interactively to test it with:

```bash
sudo docker run -it --rm --name=cod4 -p 28960:28960/udp -v /cod4/main:/home/server/main -v /cod4/zone:/home/server/zone -v /cod4/mods:/home/server/mods -v /cod4/usermaps:/home/server/usermaps -e 'ARGS=+map mp_shipment' qmcgaw/cod4
```

### Mods

Set `ARGS` to `+set fs_game mods/SERVER+map_rotate`

## Testing

1. Run a COD4 client and try to connect to `yourhostIPaddress:28960`

## How does it work

1. Installs required packages: unzip, curl, nasm, etc.
2. Creates *server* user with its home directory
3. Runs a shell script a startup
    1. Downloads Cod4x if necessary
    2. Launches Cod4x server with arguments defined in optional environment variable `ARGS` with the username *server*
    
