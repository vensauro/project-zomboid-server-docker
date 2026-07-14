# syntax=docker/dockerfile:1
# Dockerfile that builds the amd64 Project Zomboid Gameserver.
# SteamCMD runs once in Dockerfile.content; this stage only copies its output.
ARG PZ_CONTENT_IMAGE=ghcr.io/vensauro/project-zomboid-server-files:latest
ARG PZ_CONTENT_PLATFORM=linux/amd64
FROM --platform=${PZ_CONTENT_PLATFORM} ${PZ_CONTENT_IMAGE} AS pz-content

FROM cm2network/steamcmd:root

LABEL maintainer="daniel.carrasco@electrosoftcloud.com"

ENV STEAMAPPID=380870
ENV STEAMAPP=pz
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"
# Fix for a new installation problem in the Steamcmd client
ENV HOME="${HOMEDIR}"

# Receive the value from docker-compose as an ARG
ARG STEAMAPPBRANCH="public"
# Promote the ARG value to an ENV for runtime
ENV STEAMAPPBRANCH=$STEAMAPPBRANCH

# Install required packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  dos2unix \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Generate locales to allow other languages in the PZ Server
RUN sed -i 's/^# *\(es_ES.UTF-8\)/\1/' /etc/locale.gen \
  # Generate locale
  && locale-gen

# SteamCMD downloaded this directory natively in Dockerfile.content. Copying
# from the OCI image does not execute its amd64 binaries.
COPY --from=pz-content --chown=${USER}:${USER} /home/steam/pz-dedicated/ "${STEAMAPPDIR}/"

# Copy the entry point file
COPY --chown=${USER}:${USER} scripts/entry.sh /server/scripts/entry.sh
RUN chmod 550 /server/scripts/entry.sh

# Copy searchfolder file
COPY --chown=${USER}:${USER} scripts/search_folder.sh /server/scripts/search_folder.sh
RUN chmod 550 /server/scripts/search_folder.sh

# Create required folders to keep their permissions on mount
RUN mkdir -p "${HOMEDIR}/Zomboid"

WORKDIR ${HOMEDIR}
# Expose ports
EXPOSE 16261-16262/udp \
  27015/tcp

ENTRYPOINT ["/server/scripts/entry.sh"]
