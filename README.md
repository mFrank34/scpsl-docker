<div align="center">
    <a href="https://store.steampowered.com/app/700330/SCP_Secret_Laboratory/">
<img width=100% src="https://steamcdn-a.akamaihd.net/steam/apps/700330/header.jpg"/>
</a>
<br/>
<img alt="Travis (.com)" src="https://img.shields.io/travis/com/FragSoc/scpsl-docker?style=flat-square">
<img alt="GitHub" src="https://img.shields.io/github/license/FragSoc/barotrauma-docker?style=flat-square">
</div>

---

A [Docker](https://www.docker.com/) image to run a dedicated server for [SCP: Secret Lab](https://store.steampowered.com/app/700330/SCP_Secret_Laboratory/).

Works with both Docker and [Podman](https://podman.io/) (including rootless Podman).

## Usage

### Docker

An example sequence could be:

```bash
docker build -t scpsl https://github.com/FragSoc/scpsl-docker.git && \
docker run -d -p 7777:7777/udp -v $PWD/scpsl_config:/config scpsl
```

### Podman (rootless)

Rootless Podman maps container UIDs into a subordinate range on the host, so a
plain bind mount can hit permission errors on `/config`. Fix ownership once
with `podman unshare` before starting the container — no build changes
needed, the default `UID`/`GID` build args (`999`/`999`) are fine:

```bash
mkdir -p ./config
podman unshare chown 999:999 ./config

podman build -t scpsl --network=host . && \
podman run -d -p 7777:7777/udp -v $PWD/config:/config:Z scpsl
```

`--network=host` on the build step avoids flaky networking in Podman's build
sandbox, which can otherwise cause `steamcmd` to fail partway through with a
`Missing configuration` error. The image also retries the `steamcmd` install
a few times internally to ride out transient Steam CDN hiccups.

### docker-compose / podman-compose

```yaml
version: "3.9"
services:
  scp-deadicated:
    build:
      context: .
      dockerfile: dockerfile
      network: host
    container_name: scp-deadicated
    ports:
      - "7777:7777/udp"
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    volumes:
      - ./config:/config:Z
```

```bash
mkdir -p ./config
podman unshare chown 999:999 ./config   # skip this line for plain docker
podman compose up -d --build
```

`security_opt: no-new-privileges` and `cap_drop: ALL` are optional hardening
— the server only needs to bind a UDP port above 1024 and read/write its own
files, so it doesn't need any Linux capabilities.

If you're on plain Docker, drop the `podman unshare` step and the `:Z`
SELinux label suffix on the volume (Docker doesn't need either).

The image exposes one volume at `/config` for the server's configuration files.

The image exposes one port, defaulting to `7777/udp` (see below).

### Build Arguments

Argument Key | Default Value | Description
---|---|---
`UID` | `999` | Desired user ID of the user the server will run as. You might want to override this for easier directory permission management (e.g. matching your host user's `id -u` for rootless Podman bind mounts — see `podman unshare` note above for an alternative that doesn't require rebuilding).
`GID` | `999` | Twin to `UID`, setting the primary group id of the user.
`PORT` | `7777` | Port that the game will be run under. **WARNING:** you must still set this in `/config/config_gamplay.txt`
`APPID` | `996560` | The appid to pass to `steamcmd`. Default should be fine for the vast majority of cases.
`STEAM_BETA` | | A beta string to pass to `steamcmd`. For example: `-beta mybetaname -betapassword letmein`.

## Troubleshooting

- **`steamcmd` fails with `Missing configuration` during build:** usually a
  transient Steam CDN handshake issue, sometimes worsened by Podman's
  rootless build networking. Retry the build, and/or build with
  `--network=host` (or `network: host` under `build:` in compose).
- **Permission denied writing to `/config` under rootless Podman:** run
  `podman unshare chown 999:999 ./config` (or whatever `UID:GID` you built
  the image with) against the host directory before starting the container.

## Licensing

The few files in this repo are licensed under the GPL.

However, SCP: Secret Lab is proprietary software licensed by [Northwood Studios](https://northwoodstudios.org/); no credit is taken for the software in this image.