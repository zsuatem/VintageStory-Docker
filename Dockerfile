ARG DOTNET_RUNTIME_VERSION

# Run server
FROM mcr.microsoft.com/dotnet/runtime:${DOTNET_RUNTIME_VERSION} AS base
WORKDIR /vintagestory

ARG VERSION="1.22.0-rc.10"

# Install dependencies for container startup
RUN set -eux; \
    apt-get update; \
    apt-get install -y gosu procps; \
    rm -rf /var/lib/apt/lists/*

COPY .server-package/server/ /vintagestory/
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
