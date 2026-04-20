FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

WORKDIR /workspace

COPY bootstrap/ ./bootstrap/
COPY script/ ./script/
COPY packages/ ./packages/
COPY .dotter/ ./.dotter/
COPY ci/image/ ./ci/image/
COPY justfile ./justfile
COPY bootstrap-up.sh ./bootstrap-up.sh

RUN bash bootstrap-up.sh \
    && bash ci/image/finalize-image.sh

WORKDIR /root
