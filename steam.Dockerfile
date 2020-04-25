ARG DEBIAN_VERSION=buster-slim
ARG ALPINE_VERSION=3.11

FROM alpine:${ALPINE_VERSION} AS downloader
WORKDIR /tmp
RUN apk add --update --no-cache -q --progress unzip && \
    wget -q https://cod4x.me/downloads/cod4x_server-linux.zip && \
    unzip -q cod4x_server-linux.zip -d cod4x && \
    rm cod4x_server-linux.zip && \
    apk del unzip && \
    mv cod4x/cod4x18_dedrun cod4x/main/xbase_00.iwd cod4x/steam_api.so cod4x/steamclient.so ./ && \
    rm -r cod4x

FROM debian:${DEBIAN_VERSION}
ARG BUILD_DATE
ARG VCS_REF
LABEL \
    org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.url="https://github.com/qdm12/cod4-docker" \
    org.opencontainers.image.documentation="https://github.com/qdm12/cod4-docker/blob/master/README.md" \
    org.opencontainers.image.source="https://github.com/qdm12/cod4-docker" \
    org.opencontainers.image.title="cod4 with steam" \
    org.opencontainers.image.description="Call of duty 4X Modern Warfare dedicated server"
EXPOSE 28960/udp
WORKDIR /home/user/cod4
COPY --chown=1000 --from=downloader /tmp/xbase_00.iwd /tmp/steam_api.so /tmp/steamclient.so /tmp/cod4x18_dedrun ./
COPY --chown=1000 entrypoint.sh server.cfg ./
RUN apt-get update -qq > /dev/null && \
    apt-get install --no-install-recommends g++-multilib ca-certificates -qq > /dev/null && \
    apt-get autoremove -qq > /dev/null && \
    rm -rf /var/lib/apt/lists/*
RUN adduser --system user --home /home/user --uid 1000 && \
    chown -R user /home/user && \
    chmod -R 700 /home/user && \
    chmod 500 entrypoint.sh cod4x18_dedrun steam_api.so steamclient.so && \
    chmod 600 xbase_00.iwd
ENTRYPOINT [ "/home/user/cod4/entrypoint.sh" ]
CMD +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate
USER user
