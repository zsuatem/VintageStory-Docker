<div align="center">

[![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/zsuatem/VintageStory-Docker/Build%20Vintage%20Story%20Docker%20image/master?label=image%20build&style=flat-square)](https://github.com/zsuatem/VintageStory-Docker)

[![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/zsuatem/vintagestory/stable?label=latest%20stable%20version&style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)

[![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/zsuatem/vintagestory/unstable?label=latest%20unstable%20version&style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)

[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/zsuatem/vintagestory?style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)
[![Docker Pulls](https://img.shields.io/docker/pulls/zsuatem/vintagestory?style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)
[![Docker Stars](https://img.shields.io/docker/stars/zsuatem/vintagestory?style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)

</div>

# About
Simple Docker image of Vintage Story Server for `amd64`, `arm64` and `arm v7` architectures.

# Tags
- `latest`, `stable` - latest stable version
  - `1.16` - latest 1.16.x (stable) version e.g. (1.14, 1.15)
    - `1.16.4` - 1.16.4 (stable) version e.g. (1.14.10, 1.15.2)
- `unstable` - latest unstable version
  - `1.16.5-rc.1` - 1.16.5-rc.1 (preview, rc) version e.g. (v1.14.0-pre.11, v1.15.0-pre.8)

# How to use
## Simple run
Simple run with default settings (not recommended).
```docker
docker run --name vintagestory -d -it -p 42420:42420/tcp zsuatem/vintagestory:latest
```

## Data folder
If you want to easily change some settings or add mods you can mount the `data` folder or what you need to folder/file on your server. the `data` folder is mounted to a randomly named volume by default.

The `data` folder contains:

```
.
|-- BackupSaves
|-- Backups
|-- Cache
|-- Logs
|-- Macros
|-- Mods
|-- Playerdata
|-- Saves
|-- WorldEdit
|-- serverconfig.json
`-- servermagicnumbers.json
```

If you do not want to mount any file or folder you can copy the file from the server to the container using `docker cp` e.g. `docker cp ./serverconfig.json vintagestory:/vintagestory/data/serverconfig.json`.

## Access to console
You can easily access the console using `docker attach vintagestory` where "vintagestory" is the container name.
To detach, use the keyboard shortcut <kbd>Ctrl</kbd> + <kbd>P</kbd> <kbd>Q</kbd>.

## Run the server (docker run)
Run with the `data` folder in the container mounted to `vsserverdata` volume.
```docker
docker run --name vintagestory -d -it \
    -p 42420:42420/tcp \
    -v vsserverdata:/vintagestory/data \
    zsuatem/vintagestory:latest
```

## Run the server (docker compose)
Same as above but as `docker-compose.yml`. You can exacly the 

`docker-compose.yml` file:
```yml
version: "3.9"

services:
    vintagestory:
        image: zsuatem/vintagestory:latest
        container_name: vintagestory
        restart: always
        ports:
            - 42420:42420/tcp
        volumes:
            - vsserverdata:/vintagestory/data
        stdin_open: true
        tty: true

volumes:
        vsserverdata:
```

# Useful URLs
Official game site [Vintage Story](https://www.vintagestory.at/)

You can find the images on [Docker Hub](https://hub.docker.com/r/zsuatem/vintagestory)
