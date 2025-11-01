#!/usr/bin/env bash
set -euo pipefail

GOST_BIN="/usr/local/bin/gost"
GOST_CFG_GENERATOR="/usr/local/bin/generate_gost_config.sh"
GOST_CFG="/etc/gost/config.json"
WARP_SVC_BIN="/usr/bin/warp-svc"
WARP_CLI_BIN="/usr/bin/warp-cli"

echo "Starting warp-svc..."
"$WARP_SVC_BIN" > /dev/null 2>&1 &
WARP_SVC_PID=$!
echo "warp-svc started with PID: $WARP_SVC_PID"
sleep 5

echo "Deleting existing WARP registration (if any)..."
"$WARP_CLI_BIN" --accept-tos registration delete > /dev/null 2>&1 || echo "No existing registration to delete" >&2

echo "Registering WARP client..."
"$WARP_CLI_BIN" --accept-tos registration new > /dev/null 2>&1 || echo "WARP client already registered" >&2

echo "Fetching WARP Registration Details..."
echo "================================"
"$WARP_CLI_BIN" --accept-tos registration show 2>&1 || echo "Failed to fetch WARP registration details" >&2
echo "================================"

echo "Setting WARP to Proxy mode..."
"$WARP_CLI_BIN" --accept-tos mode proxy > /dev/null 2>&1 || echo "Failed to set WARP mode" >&2

echo "Setting WARP Proxy PORT to 6969..."
"$WARP_CLI_BIN" --accept-tos proxy port 6969 > /dev/null 2>&1 || echo "Failed to set WARP Proxy port" >&2

echo "Connecting to WARP..."
"$WARP_CLI_BIN" --accept-tos connect > /dev/null 2>&1 || echo "Failed to connect to WARP" >&2
sleep 5

echo "Checking WARP status..."
echo "================================"
"$WARP_CLI_BIN" --accept-tos status 2>&1 || echo "Unable to get WARP status" >&2
echo "================================"

echo "WARP Setup Complete"

# Start fake HTTP server if PORT is set
if [ -n "${PORT:-}" ]; then
    echo "Starting fake HTTP server on port $PORT"
    /usr/local/bin/fake_server.sh "$PORT" &
    echo "Fake HTTP server started on port $PORT (PID: $!)"
fi

echo "Generating GOST config at ${GOST_CFG} (NUM_PORTS=${NUM_PORTS:-1}, BASE_PORT=${BASE_PORT:-1080})"
"$GOST_CFG_GENERATOR" "$GOST_CFG"

if [ ! -f "$GOST_CFG" ]; then
    echo "ERROR: GOST config not found at $GOST_CFG" >&2
    exit 1
fi

echo "Starting GOST with config: $GOST_CFG"
exec "$GOST_BIN" -C "$GOST_CFG"