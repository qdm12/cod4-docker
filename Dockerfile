ARG DEBIAN_VERSION=buster-slim
ARG ALPINE_VERSION=3.11
ARG GO_VERSION=1.14

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS entrypoint
RUN apk --update add git
ENV CGO_ENABLED=0
ARG GOLANGCI_LINT_VERSION=v1.25.0
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s ${GOLANGCI_LINT_VERSION}
WORKDIR /tmp/gobuild
COPY .golangci.yml .
COPY go.mod go.sum ./
RUN go mod download 2>&1
COPY cmd/main.go .
COPY internal/ ./internal/
RUN go test ./...
RUN golangci-lint run --timeout=10m
RUN go build -ldflags="-s -w" -o entrypoint main.go

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

FROM alpine:${ALPINE_VERSION} AS downloader
WORKDIR /tmp
RUN apk add --update --no-cache -q --progress unzip && \
    wget -q https://cod4x.me/downloads/cod4x_server-linux.zip && \
    unzip -q cod4x_server-linux.zip -d cod4x && \
    rm cod4x_server-linux.zip && \
    apk del unzip && \
    mv cod4x/main/xbase_00.iwd ./ && \
    rm -r cod4x

FROM alpine:${ALPINE_VERSION} AS files
WORKDIR /tmp
RUN touch steam_api.so steamclient.so
COPY --from=downloader /tmp/xbase_00.iwd .
COPY --from=builder /cod4/bin/cod4x18_dedrun .
COPY server.cfg .
COPY --from=entrypoint /tmp/gobuild/entrypoint .
RUN chown 1000 * && \
    chmod 500 entrypoint cod4x18_dedrun steam_api.so steamclient.so && \
    chmod 400 xbase_00.iwd server.cfg

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
RUN mkdir -p /home/user && \
    adduser -S user -h /home/user -u 1000 && \
    chown -R user /home/user && \
    chmod -R 700 /home/user
WORKDIR /home/user/cod4
ENTRYPOINT [ "/home/user/cod4/entrypoint" ]
CMD +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate
EXPOSE 28960/udp 8000/tcp
ENV \
    HTTP_SERVER=on \
    ROOT_URL=/
COPY --from=files /tmp/ ./
USER user
