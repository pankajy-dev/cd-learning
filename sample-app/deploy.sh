#!/usr/bin/env bash
# Simulates "deploy to an environment" by (re)starting a container on a fixed
# port per environment. Same image ref is reused across every environment —
# this is the "build once, deploy many" rule made concrete.
set -euo pipefail

ENV_NAME=$1
IMAGE_REF=$2
PORT=$3
CONTAINER_NAME="cd-sample-${ENV_NAME}"

echo "Deploying ${IMAGE_REF} to ${ENV_NAME} on port ${PORT}"

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker run -d --name "${CONTAINER_NAME}" --network cd-net -p "${PORT}:3000" "${IMAGE_REF}"

echo "${ENV_NAME} now running ${IMAGE_REF}"
