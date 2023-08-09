# Download files
FROM alpine:latest AS downloaded
WORKDIR /downloads

ARG VERSION="1.18.8"
ARG RELEASE_TYPE="stable"

RUN wget "https://cdn.vintagestory.at/gamefiles/${RELEASE_TYPE}/vs_server_linux-x64_${VERSION}.tar.gz"
RUN tar xzf "vs_server_linux-x64_${VERSION}.tar.gz"
RUN rm "vs_server_linux-x64_${VERSION}.tar.gz"

# Run server
FROM mcr.microsoft.com/dotnet/runtime:7.0 AS base
WORKDIR /vintagestory

COPY --from=downloaded /downloads /vintagestory

VOLUME [ "/vintagestory/data" ]
RUN chmod +x ./VintagestoryServer

EXPOSE 42420/tcp
CMD ./VintagestoryServer --dataPath ./data
