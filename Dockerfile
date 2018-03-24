FROM debian
MAINTAINER Quentin McGaw <quentin.mcgaw@gmail.com>
EXPOSE 28960
RUN mkdir /cod4 && cd /cod4 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    unzip wget ca-certificates g++-multilib && \
    wget https://cod4x.me/downloads/cod4x_server-linux.zip && \
    unzip -o cod4x_server-linux.zip && \
    rm cod4x_server-linux.zip && \
    chmod +x cod4x18_dedrun && \
    mv main/xbase_00.iwd ./xbase_00.iwd && \
    rm -rf main && \
    apt-get remove -y unzip wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*
VOLUME /cod4/main /cod4/zone /cod4/mods /cod4/usermaps
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
WORKDIR /cod4
ENTRYPOINT ["/entrypoint.sh"]