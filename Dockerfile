# Base image
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS base

WORKDIR /app
COPY . .
# RUN dotnet publish -c Release --output ./bld/ BattleBitAPIRunner.sln

# App image
FROM mcr.microsoft.com/dotnet/runtime:6.0 AS app

ARG UNAME=bbr
ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID -o $UNAME \
    && useradd -l -u $UID -g $GID -o -s /bin/bash $UNAME

# install wget, curl, unzip to get the latest version of BattleBitAPIRunner
RUN apt-get update \
    && apt-get install --no-install-recommends -y wget curl unzip

WORKDIR /app

# Define the repository and the API endpoint
ENV REPO="BattleBit-Community-Servers/BattleBitAPIRunner"
ENV API_URL="https://api.github.com/repos/$REPO/releases/latest"

# Fetch the latest release information and download the asset
RUN URL=$(curl -s $API_URL | grep -o 'https://github.com/[^"]*/releases/download/[^"]*/[^"]*.zip') && \
    wget $URL && \
    ZIP="$(find . -maxdepth 1 -name "*.zip")" && \
    unzip -qq $ZIP

# COPY --from=base --chown=$UID:$GID /app/bld /app
COPY --chown=$UID:$GID docker/appsettings.json /app/appsettings.json
RUN mkdir -p data/modules data/dependencies data/configurations\
    && chown -R $UID:$GID /app

USER $UID:$GID

VOLUME ["/app/data"]

CMD ["dotnet", "BattleBitAPIRunner.dll"]