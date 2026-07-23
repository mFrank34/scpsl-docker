ARG BASE_IMAGE=steamcmd/steamcmd:latest
FROM ${BASE_IMAGE} AS steambuild
LABEL maintainer="Ryan Smith <fragsoc@yusu.org>, Laura Demkowicz-Duffy <fragsoc@yusu.org>"

ARG APPID=996560
ARG STEAM_BETA=""

USER root
ENV HOME=/root

# Bootstrap steamcmd first — lets it self-update/build its cache
# before we actually try to pull the game. Allowed to fail.
RUN steamcmd +quit || true

# Install the scpsl server, with retries in case of a flaky
# Steam CDN handshake (common cause of "Missing configuration")
RUN mkdir -p /scpserver && \
    for i in 1 2 3; do \
        steamcmd \
            +force_install_dir /scpserver \
            +login anonymous \
            +app_update $APPID $STEAM_BETA validate \
            +quit && break; \
        echo "steamcmd attempt $i failed, retrying..."; \
        sleep 5; \
    done

FROM mono AS runner

ARG PORT=7777
ARG UID=999
ARG GID=999
# ^ Override these at build time to match your host user
#   (run `id -u` / `id -g` on the host) so rootless bind-mounts
#   to ./config don't need userns remapping.

ENV CONFIG_LOC="/config"
ENV INSTALL_LOC="/scpserver"
ENV GAME_CONFIG_LOC="/home/scpsl/.config/SCP Secret Laboratory/config"

USER root

# Setup directory structure and permissions
RUN groupadd -g $GID scpsl && \
    useradd -m -s /bin/false -u $UID -g scpsl scpsl && \
    mkdir -p "$GAME_CONFIG_LOC" $CONFIG_LOC $INSTALL_LOC && \
    ln -s $CONFIG_LOC "$GAME_CONFIG_LOC/$PORT" && \
    chown -R scpsl:scpsl $INSTALL_LOC $CONFIG_LOC /home/scpsl/.config
COPY --chown=scpsl:scpsl --from=steambuild /scpserver $INSTALL_LOC
COPY docker-entrypoint.sh /docker-entrypoint.sh

# I/O
VOLUME $CONFIG_LOC
EXPOSE $PORT/udp

# Expose and run
USER scpsl
WORKDIR $INSTALL_LOC
ENTRYPOINT /docker-entrypoint.sh