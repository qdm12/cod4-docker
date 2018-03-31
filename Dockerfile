FROM debian
LABEL maintainer="quentin.mcgaw@gmail.com" \
      description="Runs a Call of duty 4 Modern Warfare dedicated server in a Docker container" \
      size="363MB" \
      ram="350MB to 500MB" \
      github="https://github.com/qdm12/cod4-docker"
EXPOSE 28960
RUN mkdir /cod4 && cd /cod4 && \
    apt-get update -qq > /dev/null && \
    apt-get install --no-install-recommends \
    unzip wget ca-certificates g++-multilib -qq > /dev/null && \
    wget -q https://cod4x.me/downloads/cod4x_server-linux.zip && \
    unzip -q -o cod4x_server-linux.zip && \
    rm cod4x_server-linux.zip && \
    chmod +x cod4x18_dedrun && \
    mv main/xbase_00.iwd ./xbase_00.iwd && \
    rm -rf main && \
    apt-get remove unzip wget ca-certificates -qq > /dev/null && \
    apt-get autoremove  -qq > /dev/null && \ 
    rm -rf /var/lib/apt/lists/*
COPY server.cfg /cod4
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
WORKDIR /cod4
ENTRYPOINT ["/entrypoint.sh"]
VOLUME /cod4/main /cod4/zone /cod4/mods /cod4/usermaps
ENV ARGS +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate