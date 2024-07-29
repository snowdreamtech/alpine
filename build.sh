#!/bin/sh

DOCKER_HUB_PROJECT=snowdreamtech/alpine

GITHUB_PROJECT=ghcr.io/snowdreamtech/alpine

docker buildx build --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x \
-t ${DOCKER_HUB_PROJECT}:entrypoint-latest \
-t ${DOCKER_HUB_PROJECT}:entrypoint-3.20.2 \
-t ${DOCKER_HUB_PROJECT}:entrypoint-3.20 \
-t ${DOCKER_HUB_PROJECT}:entrypoint-3 \
-t ${GITHUB_PROJECT}:entrypoint-latest \
-t ${GITHUB_PROJECT}:entrypoint-3.20.2 \
-t ${GITHUB_PROJECT}:entrypoint-3.20 \
-t ${GITHUB_PROJECT}:entrypoint-3 \
. \
--push
