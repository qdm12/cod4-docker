ARG DEBIAN_VERSION=buster-slim
ARG ALPINE_VERSION=3.14
ARG GO_VERSION=1.16

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS entrypoint
RUN apk --update add git
ENV CGO_ENABLED=0
ARG GOLANGCI_LINT_VERSION=v1.41.1
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s ${GOLANGCI_LINT_VERSION}
WORKDIR /tmp/gobuild
ARG VERSION=unknown
ARG BUILD_DATE="an unknown date"
ARG COMMIT=unknown
COPY .golangci.yml .
COPY go.mod go.sum ./
RUN go mod download 2>&1
COPY cmd/main.go .
COPY internal/ ./internal/
RUN go test ./...
RUN golangci-lint run --timeout=10m
RUN go build -trimpath -ldflags="-s -w \
    -X 'main.version=$VERSION' \
    -X 'main.buildDate=$BUILD_DATE' \
    -X 'main.commit=$COMMIT' \
    " -o entrypoint main.go

FROM debian:${DEBIAN_VERSION} AS builder
RUN dpkg --add-architecture i386 && \
    apt-get -qq update && \
    apt-get -qq install -y nasm:i386 build-essential gcc-multilib g++-multilib paxctl wget
WORKDIR /cod4
ARG COD4X_VERSION=v19.2.0
RUN wget -qO- https://github.com/callofduty4x/CoD4x_Server/archive/${COD4X_VERSION}.tar.gz | \
    tar -xz --strip-components=1 && \
    make

FROM alpine:${ALPINE_VERSION} AS downloader
WORKDIR /tmp
ARG COD4X_VERSION=19.2
RUN apk add --update --no-cache -q --progress unzip && \
    wget -qO cod4x_server-linux.zip https://cod4x.me/downloads/cod4x_server-linux_${COD4X_VERSION}.zip && \
    unzip -q cod4x_server-linux.zip -d . && \
    rm cod4x_server-linux.zip && \
    apk del unzip && \
    mv \
    cod4x-linux-server/main/xbase_00.iwd \
    cod4x-linux-server/main/jcod4x_00.iwd \
    cod4x-linux-server/zone/cod4x_patchv2.ff \
    cod4x-linux-server/steam_api.so \
    cod4x-linux-server/steamclient.so \
    ./ && \
    rm -r cod4x-linux-server

FROM alpine:${ALPINE_VERSION} AS files
WORKDIR /tmp
COPY --from=downloader \
    /tmp/xbase_00.iwd \
    /tmp/jcod4x_00.iwd \
    /tmp/cod4x_patchv2.ff \
    /tmp/steam_api.so \
    /tmp/steamclient.so \
    ./
COPY --from=builder /cod4/bin/cod4x18_dedrun .
COPY server.cfg .
COPY --from=entrypoint /tmp/gobuild/entrypoint .
RUN touch autoupdate.lock
RUN chown 1000 * && \
    chmod 500 entrypoint cod4x18_dedrun steam_api.so steamclient.so && \
    chmod 400 xbase_00.iwd jcod4x_00.iwd cod4x_patchv2.ff server.cfg

FROM debian:${DEBIAN_VERSION}
ARG VERSION=unknown
ARG BUILD_DATE="an unknown date"
ARG COMMIT=unknown
LABEL \
    org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.url="https://github.com/qdm12/cod4-docker" \
    org.opencontainers.image.documentation="https://github.com/qdm12/cod4-docker/blob/master/README.md" \
    org.opencontainers.image.source="https://github.com/qdm12/cod4-docker" \
    org.opencontainers.image.title="cod4 with steam" \
    org.opencontainers.image.description="Call of duty 4X Modern Warfare dedicated server"
RUN apt-get update -qq > /dev/null && \
    apt-get install --no-install-recommends g++-multilib ca-certificates -qq > /dev/null && \
    apt-get autoremove -qq > /dev/null && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /home/user/.callofduty4/main && \
    adduser --system user --home /home/user --uid 1000 && \
    chown -R user /home/user && \
    chmod -R 700 /home/user
WORKDIR /home/user/cod4
ENTRYPOINT [ "/home/user/cod4/entrypoint" ]
CMD +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate
EXPOSE 28960/udp 28960/tcp 8000/tcp
ENV \
    HTTP_SERVER=on \
    ROOT_URL=/
COPY --from=files --chown=1000 /tmp/ ./
USER user
