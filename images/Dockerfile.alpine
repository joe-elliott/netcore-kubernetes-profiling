FROM mcr.microsoft.com/dotnet/core/sdk:2.2.300-alpine3.9

WORKDIR /root

ENV PATH="${PATH}:/root/.dotnet/tools"

RUN    echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add bash \
               ncurses \
               perf \
               git \
               perl \
    && rm -rf /var/cache/apk/* \
    && git clone --depth=1 https://github.com/BrendanGregg/FlameGraph \
    && dotnet tool install -g dotnet-dump --version 1.0.4-preview6.19311.1