ARG BUILDPLATFORM=linux/amd64
ARG DEBIAN_VERSION=buster-slim
ARG ALPINE_VERSION=3.16
ARG GO_VERSION=1.17
ARG GOLANGCI_LINT_VERSION=v1.46.2
ARG XCPUTRANSLATE_VERSION=v0.6.0

FROM --platform=${BUILDPLATFORM} qmcgaw/xcputranslate:${XCPUTRANSLATE_VERSION} AS xcputranslate
FROM --platform=${BUILDPLATFORM} qmcgaw/binpot:golangci-lint-${GOLANGCI_LINT_VERSION} AS golangci-lint

FROM --platform=${BUILDPLATFORM} golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS entrypoint
ENV CGO_ENABLED=0
WORKDIR /tmp/gobuild
RUN apk --update add git
COPY --from=xcputranslate /xcputranslate /usr/local/bin/xcputranslate
COPY --from=golangci-lint /bin /go/bin/golangci-lint
COPY .golangci.yml .
COPY go.mod go.sum ./
RUN go mod download 2>&1
COPY cmd/main.go .
COPY internal/ ./internal/
RUN go test ./...
RUN golangci-lint run --timeout=10m
ARG VERSION=unknown
ARG BUILD_DATE="an unknown date"
ARG COMMIT=unknown
ARG TARGETPLATFORM
RUN GOARCH="$(xcputranslate translate -field arch -targetplatform ${TARGETPLATFORM})" \
    GOARM="$(xcputranslate translate -field arm -targetplatform ${TARGETPLATFORM})" \
    go build -trimpath -ldflags="-s -w \
    -X 'main.version=$VERSION' \
    -X 'main.buildDate=$BUILD_DATE' \
    -X 'main.commit=$COMMIT' \
    " -o entrypoint main.go

FROM debian:${DEBIAN_VERSION} AS builder
RUN dpkg --add-architecture i386 && \
    apt-get -qq update && \
    apt-get -qq install -y nasm:i386 build-essential gcc-multilib g++-multilib paxctl wget
WORKDIR /cod4
ARG COD4X_VERSION=20.1
RUN wget -qO- https://github.com/callofduty4x/CoD4x_Server/archive/${COD4X_VERSION}.tar.gz | \
    tar -xz --strip-components=1 && \
    # sed -i 's/LINUX_LFLAGS=/LINUX_LFLAGS=-static /' makefile && \
    make

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS downloader
WORKDIR /tmp
ARG COD4X_VERSION=20.1
RUN apk add --update --no-cache -q --progress unzip && \
    wget -qO cod4x_server-linux.zip https://cod4x.me/downloads/cod4x_server-linux_${COD4X_VERSION}.zip && \
    unzip -q cod4x_server-linux.zip -d . && \
    rm cod4x_server-linux.zip && \
    apk del unzip && \
    dirname="cod4x_server-linux_20.0" && \
    mv \
    ${dirname}/cod4x-linux-server/main/xbase_00.iwd \
    ${dirname}/cod4x-linux-server/main/jcod4x_00.iwd \
    ${dirname}/cod4x-linux-server/zone/cod4x_patchv2.ff \
    ${dirname}/cod4x-linux-server/steam_api.so \
    ${dirname}/cod4x-linux-server/steamclient.so \
    ./ && \
    rm -r ${dirname}

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS files
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
RUN touch autoupdate.lock cod4x18_dedrun.new steam_api.so.new
ARG UID=1000
ARG GID=1000
RUN chown ${UID}:${GID} * && \
    chmod 600 cod4x18_dedrun.new steam_api.so.new && \
    chmod 500 entrypoint cod4x18_dedrun steam_api.so steamclient.so && \
    chmod 400 xbase_00.iwd jcod4x_00.iwd cod4x_patchv2.ff server.cfg

FROM debian:${DEBIAN_VERSION}
RUN dpkg --add-architecture i386 && \
    apt-get update -qq && \
    apt-get install -qq --no-install-recommends \
    libc6 libgcc1:i386 	libstdc++6:i386 ca-certificates && \
    apt-get autoremove -qq && \
    rm -rf /var/lib/apt/lists/*
ARG UID=1000
ARG GID=1000
RUN mkdir -p /home/user/.callofduty4/main && \
    addgroup --gid 1000 cod4 && \
    adduser --system user --home /home/user --uid ${UID} --gid ${GID} && \
    chown -R user /home/user && \
    chmod -R 700 /home/user
WORKDIR /home/user/cod4
RUN chown ${UID}:${GID} /home/user/cod4
ENTRYPOINT [ "/home/user/cod4/entrypoint" ]
CMD +set dedicated 2+set sv_cheats "1"+set sv_maxclients "64"+exec server.cfg+map_rotate
EXPOSE 28960/udp 28960/tcp 8000/tcp
ENV \
    HTTP_SERVER=on \
    ROOT_URL=/
USER user
COPY --from=files --chown=${UID}:${GID} /tmp/ ./
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
    org.opencontainers.image.title="cod4" \
    org.opencontainers.image.description="Call of duty 4X Modern Warfare dedicated server"
