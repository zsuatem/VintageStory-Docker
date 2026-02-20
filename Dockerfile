# Download files
FROM ubuntu:latest AS downloaded
WORKDIR /downloads

ARG VERSION="1.22.0-pre.3"
ARG RELEASE_TYPE="stable"

RUN set -eux; \
    apt-get update; \
    apt-get install -y wget; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    wget "https://cdn.vintagestory.at/gamefiles/${RELEASE_TYPE}/vs_server_linux-x64_${VERSION}.tar.gz"; \
    tar xzf "vs_server_linux-x64_${VERSION}.tar.gz"; \
    rm "vs_server_linux-x64_${VERSION}.tar.gz"

# Run server
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS base
WORKDIR /vintagestory

ARG VERSION="1.22.0-pre.3"

ENV PUID=1000
ENV PGID=1000

# Install gosu for user switching and procps for healthcheck
RUN set -eux; \
    apt-get update; \
    apt-get install -y gosu procps; \
    rm -rf /var/lib/apt/lists/*

COPY --from=downloaded /downloads /vintagestory
COPY entrypoint.sh /entrypoint.sh

LABEL org.opencontainers.image.title="Vintage Story Server"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.description="Simple Docker image of Vintage Story Server"
LABEL org.opencontainers.image.source="https://github.com/zsuatem/VintageStory-Docker"

VOLUME [ "/vintagestory/data" ]

RUN set -eux; \
    chmod +x ./VintagestoryServer; \
    chmod +x /entrypoint.sh

EXPOSE 42420/tcp
EXPOSE 42420/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD pgrep -f VintagestoryServer >/dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
