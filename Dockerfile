FROM ubuntu
MAINTAINER quentin.mcgaw@gmail.com
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y unzip curl
RUN apt-get install -y nasm:i386 build-essential gcc-multilib g++-multilib
RUN mkdir /home/server
WORKDIR /home/server
RUN useradd server
RUN chown -R server:server /home/server
COPY script.sh ./
RUN chmod +x script.sh
ENTRYPOINT ["/home/server/script.sh"]
# CMD ["+set sv_authorizemode '-1'", "+set fs_game mods/SERVER"]