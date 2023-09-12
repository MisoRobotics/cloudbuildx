# syntax=docker/dockerfile:1
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

WORKDIR /
ARG BUILDX_VERSION=0.12.0

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories \
    && apk update -U --no-cache && apk add --no-cache bind-tools curl openssh docker-cli \
    && curl -fSsLo /usr/bin/buildx https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64 \
    && curl -fSsLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_amd64 && chmod +x /usr/local/bin/yq \
    && chmod a+x /usr/bin/buildx \
    && gcloud auth configure-docker asia-docker.pkg.dev,eu-docker.pkg.dev,us-docker.pkg.dev,gcr.io,asia.gcr.io,eu.gcr.io,us.gcr.io \
    && rm -rf /lib/apk/db/scripts.tar \
    && rm -r /var/cache/apk

COPY ./entrypoint.sh /
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
LABEL maintainer="Ryan Sinnet" \
    github.account="https://github.com/MisoRobotics" \
    dockerfile.github.page="https://github.com/MisoRobotics/cloudbuildx/blob/main/Dockerfile" \
    description="Build multiarch containers on Google Cloud Build with Moby BuildKit, Docker Buildx, and QEMU." \
    version="2.1.2"

ARG MULTIARCH=
ENV MULTIARCH=${MULTIARCH}
STOPSIGNAL SIGTERM
