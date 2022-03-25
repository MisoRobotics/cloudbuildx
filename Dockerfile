# syntax=docker/dockerfile:1.3
ARG ALPINE_VERSION=3.15
FROM alpine:3.15
WORKDIR /
ARG BUILDX_VERSION=0.7.0
ARG DOCKER_VERSION=20.10.11-r0
ARG GCR_CRED_VERSION=2.1.0

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.15/community" >> /etc/apk/repositories \
    && apk update -U --no-cache && apk add --no-cache bind-tools curl openssh docker-cli=$DOCKER_VERSION \
    && curl -fSsLo /usr/bin/buildx https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64 \
    && curl -fSsL https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${GCR_CRED_VERSION}/docker-credential-gcr_linux_amd64-${GCR_CRED_VERSION}.tar.gz | tar xzp -C /usr/bin docker-credential-gcr \
    && docker-credential-gcr configure-docker --registries asia-docker.pkg.dev,eu-docker.pkg.dev,us-docker.pkg.dev,gcr.io,asia.gcr.io,eu.gcr.io,us.gcr.io \
    && chmod a+x /usr/bin/buildx \
    && rm -rf /lib/apk/db/scripts.tar \
    && rm -r /var/cache/apk

COPY ./entrypoint.sh /
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
LABEL maintainer="Ryan Sinnet" \
    github.account="https://github.com/MisoRobotics" \
    dockerfile.github.page="https://github.com/MisoRobotics/cloudbuildx/blob/main/Dockerfile" \
    description="Build multiarch containers on Google Cloud Build with Moby BuildKit, Docker Buildx, and QEMU." \
    version="1.1.0"

STOPSIGNAL SIGTERM
