FROM debian
MAINTAINER Quentin McGaw <quentin.mcgaw@gmail.com>
EXPOSE 28960
RUN mkdir /cod4 && apt-get update && \
    apt-get install -y --no-install-recommends \
    unzip wget ca-certificates g++-multilib && \
    rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
WORKDIR /cod4
ENTRYPOINT ["/entrypoint.sh"]