# Download files
FROM alpine:latest AS downloaded
WORKDIR /downloads

ARG VERSION="1.16.5"
ARG RELEASE_TYPE="stable"

RUN wget "https://cdn.vintagestory.at/gamefiles/${RELEASE_TYPE}/vs_server_${VERSION}.tar.gz"
RUN tar xzf "vs_server_${VERSION}.tar.gz"
RUN rm "vs_server_${VERSION}.tar.gz"

# Run server
FROM mono:latest AS base
WORKDIR /vintagestory

COPY --from=downloaded /downloads /vintagestory

VOLUME [ "/vintagestory/data" ]

EXPOSE 42420/tcp
CMD mono VintagestoryServer.exe --dataPath ./data
