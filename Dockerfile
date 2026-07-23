ARG BASE_IMAGE=steamcmd/steamcmd:latest
FROM ${BASE_IMAGE} AS steambuild

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
ARG UID=1000
ARG GID=1000

ENV CONFIG_LOC="/config"
ENV INSTALL_LOC="/scpserver"
ENV GAME_CONFIG_LOC="/home/scpsl/.config/SCP Secret Laboratory/config"

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    mono-complete \
    procps \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g $GID scpsl && \
    useradd -m -s /bin/bash -u $UID -g scpsl scpsl && \
    mkdir -p "$GAME_CONFIG_LOC" $CONFIG_LOC $INSTALL_LOC && \
    ln -s $CONFIG_LOC "$GAME_CONFIG_LOC/$PORT" && \
    chown -R scpsl:scpsl $INSTALL_LOC $CONFIG_LOC /home/scpsl/.config

COPY --chown=$UID:$GID --from=steambuild /scpserver $INSTALL_LOC
COPY --chown=$UID:$GID --chmod=0755 docker-entrypoint.sh /docker-entrypoint.sh

VOLUME $CONFIG_LOC
EXPOSE $PORT/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -x SCPSL.x86_64 || exit 1

USER scpsl
WORKDIR $INSTALL_LOC
ENTRYPOINT ["/docker-entrypoint.sh"]