ARG BASE_IMAGE=steamcmd/steamcmd:latest
FROM ${BASE_IMAGE} AS steambuild
LABEL maintainer="Ryan Smith <fragsoc@yusu.org>, Laura Demkowicz-Duffy <fragsoc@yusu.org>"

ARG APPID=996560
ARG STEAM_BETA=""

USER root
ENV HOME=/root

RUN steamcmd +quit || true

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

FROM debian:bookworm-slim AS runner

ARG PORT=7777
ARG UID=999
ARG GID=999

ENV CONFIG_LOC="/config"
ENV INSTALL_LOC="/scpserver"
ENV GAME_CONFIG_LOC="/home/scpsl/.config/SCP Secret Laboratory/config"

USER root

RUN apt-get update && apt-get install -y \
    mono-complete \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g $GID scpsl && \
    useradd -m -s /bin/bash -u $UID -g scpsl scpsl && \
    mkdir -p "$GAME_CONFIG_LOC" $CONFIG_LOC $INSTALL_LOC && \
    chown -R scpsl:scpsl $INSTALL_LOC $CONFIG_LOC /home/scpsl/.config

COPY --chown=$UID:$GID --from=steambuild /scpserver $INSTALL_LOC
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

VOLUME $CONFIG_LOC
EXPOSE $PORT/udp

WORKDIR $INSTALL_LOC
ENTRYPOINT ["/docker-entrypoint.sh"]
