ARG DEBIAN_VERSION=stretch-slim

FROM debian:${DEBIAN_VERSION}
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.schema-version="1.0.0-rc1" \
      maintainer="quentin.mcgaw@gmail.com" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/qdm12/cod4-docker" \
      org.label-schema.url="https://github.com/qdm12/cod4-docker" \
      org.label-schema.vcs-description="Call of duty 4X Modern Warfare dedicated server" \
      org.label-schema.vcs-usage="https://github.com/qdm12/cod4-docker/blob/master/README.md#setup" \
      org.label-schema.docker.cmd="docker run -d --name=cod4 -p 28960:28960/udp -v $(pwd)/main:/cod4/main -v $(pwd)/zone:/cod4/zone:ro -v $(pwd)/mods:/cod4/mods -v $(pwd)/usermaps:/cod4/usermaps:ro -e 'ARGS=+map mp_shipment' qmcgaw/cod4" \
      org.label-schema.docker.cmd.devel="docker run -it --rm --name=cod4 -p 28960:28960/udp -v $(pwd)/main:/cod4/main -v $(pwd)/zone:/cod4/zone:ro -v $(pwd)/mods:/cod4/mods -v $(pwd)/usermaps:/cod4/usermaps:ro -e 'ARGS=+map mp_shipment' qmcgaw/cod4" \
      org.label-schema.docker.params="ARGS=arguments provided to cod4x binary" \
      org.label-schema.version="" \
      image-size="357MB" \
      ram-usage="350MB to 500MB" \
      cpu-usage="Low"
EXPOSE 28960/udp
WORKDIR /cod4
RUN apt-get update -y && \
    apt-get install --no-install-recommends unzip wget ca-certificates g++-multilib -qq > /dev/null && \
    wget -q https://cod4x.me/downloads/cod4x_server-linux.zip && \
    unzip -q -o cod4x_server-linux.zip && \
    rm cod4x_server-linux.zip && \
    chmod 500 cod4x18_dedrun && \
    mv main/xbase_00.iwd ./xbase_00.iwd && \
    rm -rf main && \
    apt-get remove unzip wget ca-certificates -qq > /dev/null && \
    apt-get autoremove -qq > /dev/null && \ 
    rm -rf /var/lib/apt/lists/*
VOLUME /cod4/main /cod4/zone /cod4/mods /cod4/usermaps
ENV ARGS +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate
COPY entrypoint.sh server.cfg ./
RUN chown -R 1000 /cod4 && \
    chmod 500 /cod4/entrypoint.sh
USER 1000
ENTRYPOINT /cod4/entrypoint.sh
