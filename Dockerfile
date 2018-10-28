FROM debian:stretch-slim
LABEL maintainer="quentin.mcgaw@gmail.com" \
      description="Runs a Call of duty 4X Modern Warfare dedicated server" \
      download="105.4MB" \
      size="305MB" \
      ram="350MB to 500MB" \
      cpu_usage="Low" \
      github="https://github.com/qdm12/cod4-docker"
EXPOSE 28960/udp
WORKDIR /cod4
RUN apt-get update -qq > /dev/null && \
    apt-get install --no-install-recommends unzip wget ca-certificates g++-multilib -qq > /dev/null && \
    wget -q https://cod4x.me/downloads/cod4x_server-linux.zip && \
    unzip -q -o cod4x_server-linux.zip && \
    rm cod4x_server-linux.zip && \
    chmod 700 cod4x18_dedrun && \
    mv main/xbase_00.iwd ./xbase_00.iwd && \
    rm -rf main && \
    apt-get remove unzip wget ca-certificates -qq > /dev/null && \
    apt-get autoremove -qq > /dev/null && \ 
    rm -rf /var/lib/apt/lists/*
VOLUME /cod4/main /cod4/zone /cod4/mods /cod4/usermaps
COPY server.cfg .
ENV ARGS +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate
ENTRYPOINT ln -sf xbase_00.iwd main/xbase_00.iwd && \
           ln -sf server.cfg main/server.cfg && \
           echo "Arguments are: ${ARGS}" && \
           ./cod4x18_dedrun "${ARGS}"
