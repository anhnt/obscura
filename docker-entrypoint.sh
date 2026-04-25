#!/bin/sh
set -e

PORT=${PORT:-9222}
WORKERS=${WORKERS:-1}
STEALTH_FLAG=""

if [ "$STEALTH" = "true" ] || [ "$STEALTH" = "1" ]; then
    STEALTH_FLAG="--stealth"
fi

OBSCURA_PORT=$((PORT + 10000))

echo "Starting Obscura on local port $OBSCURA_PORT (Workers: $WORKERS)..."
obscura serve --port $OBSCURA_PORT --workers $WORKERS $STEALTH_FLAG &

echo "Exposing Obscura to 0.0.0.0:$PORT via socat..."
echo "Connect Playwright/Puppeteer to ws://<container-ip>:$PORT"
exec socat TCP-LISTEN:$PORT,fork,bind=0.0.0.0 TCP:127.0.0.1:$OBSCURA_PORT
