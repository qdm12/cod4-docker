ARG DEBIAN_VERSION=buster-slim
ARG ALPINE_VERSION=3.11
ARG GO_VERSION=1.14

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS entrypoint
RUN apk --update add git
ENV CGO_ENABLED=0
ARG GOLANGCI_LINT_VERSION=v1.27.0
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

FROM alpine:${ALPINE_VERSION} AS downloader
WORKDIR /tmp
RUN apk add --update --no-cache -q --progress unzip && \
    wget -q https://cod4x.me/downloads/cod4x_server-linux.zip && \
    unzip -q cod4x_server-linux.zip -d cod4x && \
    rm cod4x_server-linux.zip && \
    apk del unzip && \
    mv cod4x/cod4x18_dedrun cod4x/main/xbase_00.iwd cod4x/steam_api.so cod4x/steamclient.so ./ && \
    rm -r cod4x

FROM alpine:${ALPINE_VERSION} AS files
WORKDIR /tmp
COPY --from=downloader /tmp/xbase_00.iwd /tmp/steam_api.so /tmp/steamclient.so /tmp/cod4x18_dedrun ./
COPY server.cfg .
COPY --from=entrypoint /tmp/gobuild/entrypoint .
RUN chown 1000 * && \
    chmod 500 entrypoint cod4x18_dedrun steam_api.so steamclient.so && \
    chmod 400 xbase_00.iwd server.cfg

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
