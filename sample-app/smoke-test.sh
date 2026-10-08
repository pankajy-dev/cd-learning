#!/usr/bin/env bash
# Post-deploy verification. In a real pipeline a failure here triggers rollback.
set -euo pipefail

CONTAINER_NAME=$1
for i in {1..10}; do
    if curl -sf "http://${CONTAINER_NAME}:3000/health" | grep -q '"status":"ok"'; then
        echo "smoke test passed on ${CONTAINER_NAME}"
        exit 0
    fi
    sleep 1
done

echo "smoke test FAILED on ${CONTAINER_NAME}"
exit 1
