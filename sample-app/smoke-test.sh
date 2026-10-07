#!/usr/bin/env bash
# Post-deploy verification. In a real pipeline a failure here triggers rollback.
set -euo pipefail

PORT=$1
for i in {1..10}; do
    if curl -sf "http://localhost:${PORT}/health" | grep -q '"status":"ok"'; then
        echo "smoke test passed on port ${PORT}"
        exit 0
    fi
    sleep 1
done

echo "smoke test FAILED on port ${PORT}"
exit 1
