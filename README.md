<div align="center">

[![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/zsuatem/VintageStory-Docker/image-build.yml?branch=master&label=image%20build&style=flat-square)](https://github.com/zsuatem/VintageStory-Docker)

[![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/zsuatem/vintagestory/stable?label=latest%20stable%20version&style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)

[![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/zsuatem/vintagestory/unstable?label=latest%20unstable%20version&style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)

[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/zsuatem/vintagestory?style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)
[![Docker Pulls](https://img.shields.io/docker/pulls/zsuatem/vintagestory?style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)
[![Docker Stars](https://img.shields.io/docker/stars/zsuatem/vintagestory?style=flat-square)](https://hub.docker.com/r/zsuatem/vintagestory)

</div>

# About
Simple Docker image of Vintage Story Server for `amd64`, `arm64` and `arm v7` architectures.

**Note:** Version 1.18.8+ only supports AMD64 architecture. Official ARM builds were [discontinued](https://github.com/anegostudios/VintagestoryServerArm64) as .NET 8 provides built-in ARM support, but Vintage Story still requires native AMD64 libraries. Consider using x86 emulation (QEMU) on ARM devices for newer versions.

**Security:** This image runs as a non-root user (UID=1000, GID=1000) by default for better security. Legacy installations running as root are automatically detected and supported for backward compatibility.

# Quick Start
Get started quickly with a single command:

```bash
docker run -d --name vintagestory \
    -p 42420:42420/tcp \
    -p 42420:42420/udp \
    -v ./data:/vintagestory/data \
    zsuatem/vintagestory:latest
```

Your server data will be stored in the `./data` directory. Access the console with `docker attach vintagestory` (detach with <kbd>Ctrl</kbd> + <kbd>P</kbd> <kbd>Q</kbd>).

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
docker run --name vintagestory -d -it -p 42420:42420/tcp -p 42420:42420/udp zsuatem/vintagestory:latest
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
Run with the `data` folder mounted to a local directory (recommended):
```docker
docker run --name vintagestory -d -it \
    -p 42420:42420/tcp \
    -p 42420:42420/udp \
    -v ./data:/vintagestory/data \
    zsuatem/vintagestory:latest
```

Or using a named volume:
```docker
docker run --name vintagestory -d -it \
    -p 42420:42420/tcp \
    -p 42420:42420/udp \
    -v vsserverdata:/vintagestory/data \
    zsuatem/vintagestory:latest
```

## Run the server (docker compose)
Same as above but as `docker-compose.yml`.

`docker-compose.yml` file:
```yml
services:
    vintagestory:
        image: zsuatem/vintagestory:latest
        container_name: vintagestory
        restart: always
        ports:
            - 42420:42420/tcp
            - 42420:42420/udp
        volumes:
            - ./data:/vintagestory/data
        stdin_open: true
        tty: true
        # Optional: Set custom user/group IDs
        # environment:
        #   - PUID=1000
        #   - PGID=1000
```

# Environment Variables

| Variable | Description                        | Default |
| -------- | ---------------------------------- | ------- |
| `PUID`   | User ID for the container process  | `1000`  |
| `PGID`   | Group ID for the container process | `1000`  |

Set these variables to match your host user/group IDs to avoid permission issues with mounted volumes.

# User and Permissions

## Default Behavior (Recommended)
By default, the container runs as a **non-root user** with UID=1000 and GID=1000 for better security. This is the recommended setup for new installations.

```bash
docker run -d -p 42420:42420/tcp -p 42420:42420/udp -v vsserverdata:/vintagestory/data zsuatem/vintagestory:latest
# Runs as UID=1000, GID=1000 (non-root)
```

## Custom User/Group IDs
If you need to match specific user/group IDs on your host system (e.g., to avoid permission issues with bind mounts), you can set custom PUID and PGID:

```bash
docker run -d \
    -p 42420:42420/tcp \
    -p 42420:42420/udp \
    -v /path/to/data:/vintagestory/data \
    -e PUID=1500 \
    -e PGID=1500 \
    zsuatem/vintagestory:latest
```

Or in docker-compose:
```yml
services:
    vintagestory:
        image: zsuatem/vintagestory:latest
        environment:
            - PUID=1500
            - PGID=1500
        volumes:
            - /path/to/data:/vintagestory/data
```

## Backward Compatibility (Legacy Installations)
If you're upgrading from an older version that stored data as root, the container will **automatically detect** this and continue running as root for backward compatibility. You'll see a warning message suggesting migration to non-root for better security.

## Migration from Root to Non-Root
If you have an existing installation running as root and want to migrate to non-root:

### Option 1: On Host (Recommended)
Fix permissions on your host before upgrading:
```bash
# Find your data directory (check with docker volume inspect)
sudo chown -R 1000:1000 /var/lib/docker/volumes/vsserverdata/_data
# or for bind mount:
sudo chown -R 1000:1000 /path/to/your/data

# Then run with default settings
docker run -d -v vsserverdata:/vintagestory/data zsuatem/vintagestory:latest
```

### Option 2: Using Temporary Container
```bash
docker run --rm -v vsserverdata:/data ubuntu chown -R 1000:1000 /data
docker run -d -v vsserverdata:/vintagestory/data zsuatem/vintagestory:latest
```

### Option 3: Keep Running as Root (Not Recommended)
If you prefer to keep running as root:
```bash
docker run -d -e PUID=0 -e PGID=0 -v vsserverdata:/vintagestory/data zsuatem/vintagestory:latest
```

Note: This bypasses security improvements and is not recommended.

# Troubleshooting

## Permission Denied Errors
If you see permission errors when the container starts:

1. **Check ownership mismatch warning** in container logs:
   ```bash
   docker logs vintagestory
   ```

2. **Fix ownership** on your host to match PUID/PGID (default 1000:1000):
   ```bash
   sudo chown -R 1000:1000 /path/to/your/data
   ```

3. **Or set PUID/PGID** to match your existing data:
   ```bash
   # Find current ownership
   ls -ln /path/to/your/data
   # Set matching PUID/PGID
   docker run -e PUID=<uid> -e PGID=<gid> ...
   ```

## Container Runs as Root (Security Warning)
If you see warnings about running as root, this means you have data from an older version. For better security, consider migrating to non-root as described in the [Migration section](#migration-from-root-to-non-root).

## Healthcheck Causing Restarts
The image includes a healthcheck that verifies the server process is running. If your server takes a long time to start or you experience unexpected restarts, you can disable the healthcheck in docker-compose:

```yml
services:
    vintagestory:
        # ... other config ...
        healthcheck:
            disable: true
```

Or in docker run:
```bash
docker run --no-healthcheck ...
```

# Useful URLs

- **Official game site:** [Vintage Story](https://www.vintagestory.at/)
- **GitHub repository:** [zsuatem/VintageStory-Docker](https://github.com/zsuatem/VintageStory-Docker)
- **Docker Hub:** [zsuatem/vintagestory](https://hub.docker.com/r/zsuatem/vintagestory)
