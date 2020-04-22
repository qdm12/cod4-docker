ARG DEBIAN_VERSION=buster-slim
ARG ALPINE_VERSION=3.11

FROM debian:${DEBIAN_VERSION} AS builder
ARG COD4X_VERSION=abf470469e8ff24d65cc5d28ab804b8621d43c9e
RUN dpkg --add-architecture i386 && \
    apt-get -qq update && \
    apt-get -qq install -y nasm:i386 build-essential gcc-multilib g++-multilib unzip paxctl wget git
WORKDIR /cod4
RUN wget -q https://github.com/callofduty4x/CoD4x_Server/archive/${COD4X_VERSION}.tar.gz && \
    tar -xzf ${COD4X_VERSION}.tar.gz --strip-components=1 && \
    rm ${COD4X_VERSION}.tar.gz && \
    sed -i 's/LINUX_LFLAGS=/LINUX_LFLAGS=-static /' makefile && \
    make

FROM alpine:${ALPINE_VERSION}
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
    org.opencontainers.image.title="cod4" \
    org.opencontainers.image.description="Call of duty 4X Modern Warfare dedicated server"
EXPOSE 28960/udp
WORKDIR /home/user/cod4
COPY --chown=1000 --from=builder /cod4/bin/cod4x18_dedrun .
COPY --chown=1000 entrypoint.sh server.cfg vendor/xbase_00.iwd ./
RUN adduser -S user -h /home/user -u 1000 && \
    chown -R user /home/user && \
    chmod -R 700 /home/user && \
    chown -R user /home/user/cod4 && \
    chmod -R 700 /home/user/cod4 && \
    chmod 500 entrypoint.sh cod4x18_dedrun
ENTRYPOINT [ "/home/user/cod4/entrypoint.sh" ]
CMD +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate
USER user
