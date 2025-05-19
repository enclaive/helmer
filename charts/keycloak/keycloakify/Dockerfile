FROM node:22.10.0-alpine

WORKDIR /src
COPY . .

RUN apk add --no-cache \
    git \
    xdg-utils \
    coreutils \
    maven

RUN git config --global --add safe.directory /src