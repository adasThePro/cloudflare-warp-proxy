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

echo "Registering WARP client..."
"$WARP_CLI_BIN" --accept-tos registration new > /dev/null 2>&1 || echo "WARP client already registered" >&2

echo "Fetching WARP Client Registration Details..."
echo "================================"
"$WARP_CLI_BIN" --accept-tos registration show || echo "Failed to fetch WARP Client registration details" >&2
echo "================================"

echo "Setting WARP Client to Proxy mode..."
"$WARP_CLI_BIN" --accept-tos mode proxy > /dev/null 2>&1 || echo "Failed to set WARP Client mode" >&2

echo "Setting WARP Client Proxy PORT to 6969..."
"$WARP_CLI_BIN" --accept-tos proxy port 6969 > /dev/null 2>&1 || echo "Failed to set WARP Client Proxy port" >&2

echo "Connecting to WARP..."
"$WARP_CLI_BIN" --accept-tos connect > /dev/null 2>&1 || echo "Failed to connect to WARP" >&2
sleep 5

echo "Checking WARP status..."
echo "================================"
"$WARP_CLI_BIN" --accept-tos status || echo "Unable to get WARP status" >&2
echo "================================"

echo "WARP Setup Complete"

SOCKS4_PORTS="${SOCKS4_PORTS:-0}"
SOCKS5_PORTS="${SOCKS5_PORTS:-0}"
HTTP_PORTS="${HTTP_PORTS:-0}"
SOCKS4_TLS_PORTS="${SOCKS4_TLS_PORTS:-0}"
SOCKS5_TLS_PORTS="${SOCKS5_TLS_PORTS:-0}"
HTTP_TLS_PORTS="${HTTP_TLS_PORTS:-0}"
HTTP2_TLS_PORTS="${HTTP2_TLS_PORTS:-0}"

SOCKS4_BASE_PORT="${SOCKS4_BASE_PORT:-1080}"
SOCKS5_BASE_PORT="${SOCKS5_BASE_PORT:-1180}"
HTTP_BASE_PORT="${HTTP_BASE_PORT:-1280}"
HTTP2_BASE_PORT="${HTTP2_BASE_PORT:-1380}"
SOCKS4_TLS_BASE_PORT="${SOCKS4_TLS_BASE_PORT:-1480}"
SOCKS5_TLS_BASE_PORT="${SOCKS5_TLS_BASE_PORT:-1580}"
HTTP_TLS_BASE_PORT="${HTTP_TLS_BASE_PORT:-1680}"
HTTP2_TLS_BASE_PORT="${HTTP2_TLS_BASE_PORT:-1780}"

validate_port_count() {
    local name="$1"
    local value="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "ERROR: ${name} must be a non-negative integer (got: '$value')" >&2
        exit 1
    fi
}

validate_port_count "SOCKS4_PORTS" "$SOCKS4_PORTS"
validate_port_count "SOCKS5_PORTS" "$SOCKS5_PORTS"
validate_port_count "HTTP_PORTS" "$HTTP_PORTS"
validate_port_count "SOCKS4_TLS_PORTS" "$SOCKS4_TLS_PORTS"
validate_port_count "SOCKS5_TLS_PORTS" "$SOCKS5_TLS_PORTS"
validate_port_count "HTTP_TLS_PORTS" "$HTTP_TLS_PORTS"
validate_port_count "HTTP2_TLS_PORTS" "$HTTP2_TLS_PORTS"

validate_base_port() {
    local name="$1"
    local value="$2"
    if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
        echo "ERROR: ${name} must be a positive integer (got: '$value')" >&2
        exit 1
    fi
    if [ "$value" -lt 1 ] || [ "$value" -gt 65535 ]; then
        echo "ERROR: ${name} must be between 1 and 65535 (got: '$value')" >&2
        exit 1
    fi
}

validate_base_port "SOCKS4_BASE_PORT" "$SOCKS4_BASE_PORT"
validate_base_port "SOCKS5_BASE_PORT" "$SOCKS5_BASE_PORT"
validate_base_port "HTTP_BASE_PORT" "$HTTP_BASE_PORT"
validate_base_port "HTTP2_BASE_PORT" "$HTTP2_BASE_PORT"
validate_base_port "SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_BASE_PORT"
validate_base_port "SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_BASE_PORT"
validate_base_port "HTTP_TLS_BASE_PORT" "$HTTP_TLS_BASE_PORT"
validate_base_port "HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_BASE_PORT"

SOCKS5_USER="${SOCKS5_USER:-}"
SOCKS5_PASS="${SOCKS5_PASS:-}"
HTTP_USER="${HTTP_USER:-}"
HTTP_PASS="${HTTP_PASS:-}"
HTTP2_USER="${HTTP2_USER:-}"
HTTP2_PASS="${HTTP2_PASS:-}"
SOCKS5_TLS_USER="${SOCKS5_TLS_USER:-}"
SOCKS5_TLS_PASS="${SOCKS5_TLS_PASS:-}"
HTTP_TLS_USER="${HTTP_TLS_USER:-}"
HTTP_TLS_PASS="${HTTP_TLS_PASS:-}"
HTTP2_TLS_USER="${HTTP2_TLS_USER:-}"
HTTP2_TLS_PASS="${HTTP2_TLS_PASS:-}"

check_auth() {
    local proxy_type="$1"
    local user_var="$2"
    local pass_var="$3"
    local user_val="$4"
    local pass_val="$5"
    
    if [ -n "$user_val" ] && [ -z "$pass_val" ]; then
        echo "WARNING: ${proxy_type} authentication disabled - ${pass_var} not provided (both ${user_var} and ${pass_var} required)" >&2
    fi
    if [ -z "$user_val" ] && [ -n "$pass_val" ]; then
        echo "WARNING: ${proxy_type} authentication disabled - ${user_var} not provided (both ${user_var} and ${pass_var} required)" >&2
    fi
}

if [ "$SOCKS5_PORTS" -gt 0 ]; then
    check_auth "SOCKS5" "SOCKS5_USER" "SOCKS5_PASS" "$SOCKS5_USER" "$SOCKS5_PASS"
fi

if [ "$HTTP_PORTS" -gt 0 ]; then
    check_auth "HTTP" "HTTP_USER" "HTTP_PASS" "$HTTP_USER" "$HTTP_PASS"
fi

if [ "$SOCKS5_TLS_PORTS" -gt 0 ]; then
    check_auth "SOCKS5_TLS" "SOCKS5_TLS_USER" "SOCKS5_TLS_PASS" "$SOCKS5_TLS_USER" "$SOCKS5_TLS_PASS"
fi

if [ "$HTTP_TLS_PORTS" -gt 0 ]; then
    check_auth "HTTP_TLS" "HTTP_TLS_USER" "HTTP_TLS_PASS" "$HTTP_TLS_USER" "$HTTP_TLS_PASS"
fi

if [ "$HTTP2_TLS_PORTS" -gt 0 ]; then
    check_auth "HTTP2_TLS" "HTTP2_TLS_USER" "HTTP2_TLS_PASS" "$HTTP2_TLS_USER" "$HTTP2_TLS_PASS"
fi

if [ "$SOCKS4_PORTS" -eq 0 ] && [ "$SOCKS5_PORTS" -eq 0 ] && [ "$HTTP_PORTS" -eq 0 ] && \
    [ "$SOCKS4_TLS_PORTS" -eq 0 ] && [ "$SOCKS5_TLS_PORTS" -eq 0 ] && [ "$HTTP_TLS_PORTS" -eq 0 ] && \
    [ "$HTTP2_TLS_PORTS" -eq 0 ]; then
    echo "ERROR: At least one proxy type must be enabled" >&2
    exit 1
fi

check_collision() {
    local name1="$1"
    local base1="$2"
    local count1="$3"
    local name2="$4"
    local base2="$5"
    local count2="$6"
    
    if [ "$count1" -eq 0 ] || [ "$count2" -eq 0 ]; then
        return 0
    fi
    
    local end1=$((base1 + count1 - 1))
    local end2=$((base2 + count2 - 1))
    
    if [ "$base1" -le "$end2" ] && [ "$base2" -le "$end1" ]; then
        echo "ERROR: Port collision detected between $name1 and $name2" >&2
        echo "  $name1: $base1-$end1 ($count1 ports)" >&2
        echo "  $name2: $base2-$end2 ($count2 ports)" >&2
        exit 1
    fi
}

check_collision "SOCKS4" "$SOCKS4_BASE_PORT" "$SOCKS4_PORTS" "SOCKS5" "$SOCKS5_BASE_PORT" "$SOCKS5_PORTS"
check_collision "SOCKS4" "$SOCKS4_BASE_PORT" "$SOCKS4_PORTS" "HTTP" "$HTTP_BASE_PORT" "$HTTP_PORTS"
check_collision "SOCKS4" "$SOCKS4_BASE_PORT" "$SOCKS4_PORTS" "SOCKS4_TLS" "$SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_PORTS"
check_collision "SOCKS4" "$SOCKS4_BASE_PORT" "$SOCKS4_PORTS" "SOCKS5_TLS" "$SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_PORTS"
check_collision "SOCKS4" "$SOCKS4_BASE_PORT" "$SOCKS4_PORTS" "HTTP_TLS" "$HTTP_TLS_BASE_PORT" "$HTTP_TLS_PORTS"
check_collision "SOCKS4" "$SOCKS4_BASE_PORT" "$SOCKS4_PORTS" "HTTP2_TLS" "$HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_PORTS"
check_collision "SOCKS5" "$SOCKS5_BASE_PORT" "$SOCKS5_PORTS" "HTTP" "$HTTP_BASE_PORT" "$HTTP_PORTS"
check_collision "SOCKS5" "$SOCKS5_BASE_PORT" "$SOCKS5_PORTS" "SOCKS4_TLS" "$SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_PORTS"
check_collision "SOCKS5" "$SOCKS5_BASE_PORT" "$SOCKS5_PORTS" "SOCKS5_TLS" "$SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_PORTS"
check_collision "SOCKS5" "$SOCKS5_BASE_PORT" "$SOCKS5_PORTS" "HTTP_TLS" "$HTTP_TLS_BASE_PORT" "$HTTP_TLS_PORTS"
check_collision "SOCKS5" "$SOCKS5_BASE_PORT" "$SOCKS5_PORTS" "HTTP2_TLS" "$HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_PORTS"
check_collision "HTTP" "$HTTP_BASE_PORT" "$HTTP_PORTS" "SOCKS4_TLS" "$SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_PORTS"
check_collision "HTTP" "$HTTP_BASE_PORT" "$HTTP_PORTS" "SOCKS5_TLS" "$SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_PORTS"
check_collision "HTTP" "$HTTP_BASE_PORT" "$HTTP_PORTS" "HTTP_TLS" "$HTTP_TLS_BASE_PORT" "$HTTP_TLS_PORTS"
check_collision "HTTP" "$HTTP_BASE_PORT" "$HTTP_PORTS" "HTTP2_TLS" "$HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_PORTS"
check_collision "SOCKS4_TLS" "$SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_PORTS" "SOCKS5_TLS" "$SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_PORTS"
check_collision "SOCKS4_TLS" "$SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_PORTS" "HTTP_TLS" "$HTTP_TLS_BASE_PORT" "$HTTP_TLS_PORTS"
check_collision "SOCKS4_TLS" "$SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_PORTS" "HTTP2_TLS" "$HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_PORTS"
check_collision "SOCKS5_TLS" "$SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_PORTS" "HTTP_TLS" "$HTTP_TLS_BASE_PORT" "$HTTP_TLS_PORTS"
check_collision "SOCKS5_TLS" "$SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_PORTS" "HTTP2_TLS" "$HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_PORTS"
check_collision "HTTP_TLS" "$HTTP_TLS_BASE_PORT" "$HTTP_TLS_PORTS" "HTTP2_TLS" "$HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_PORTS"

validate_port_range() {
    local name="$1"
    local base="$2"
    local count="$3"
    
    if [ "$count" -eq 0 ]; then
        return 0
    fi
    
    local end=$((base + count - 1))
    if [ "$end" -gt 65535 ]; then
        echo "ERROR: $name port range exceeds 65535 (base: $base, count: $count, end: $end)" >&2
        exit 1
    fi
}

validate_port_range "SOCKS4" "$SOCKS4_BASE_PORT" "$SOCKS4_PORTS"
validate_port_range "SOCKS5" "$SOCKS5_BASE_PORT" "$SOCKS5_PORTS"
validate_port_range "HTTP" "$HTTP_BASE_PORT" "$HTTP_PORTS"
validate_port_range "SOCKS4_TLS" "$SOCKS4_TLS_BASE_PORT" "$SOCKS4_TLS_PORTS"
validate_port_range "SOCKS5_TLS" "$SOCKS5_TLS_BASE_PORT" "$SOCKS5_TLS_PORTS"
validate_port_range "HTTP_TLS" "$HTTP_TLS_BASE_PORT" "$HTTP_TLS_PORTS"
validate_port_range "HTTP2_TLS" "$HTTP2_TLS_BASE_PORT" "$HTTP2_TLS_PORTS"

echo "Proxy configuration:"
echo "================================"
if [ "$SOCKS4_PORTS" -gt 0 ]; then
    echo "SOCKS4: $SOCKS4_BASE_PORT-$((SOCKS4_BASE_PORT + SOCKS4_PORTS - 1)) ($SOCKS4_PORTS ports)"
fi
if [ "$SOCKS5_PORTS" -gt 0 ]; then
    echo "SOCKS5: $SOCKS5_BASE_PORT-$((SOCKS5_BASE_PORT + SOCKS5_PORTS - 1)) ($SOCKS5_PORTS ports)"
fi
if [ "$HTTP_PORTS" -gt 0 ]; then
    echo "HTTP: $HTTP_BASE_PORT-$((HTTP_BASE_PORT + HTTP_PORTS - 1)) ($HTTP_PORTS ports)"
fi
if [ "$SOCKS4_TLS_PORTS" -gt 0 ]; then
    echo "SOCKS4_TLS: $SOCKS4_TLS_BASE_PORT-$((SOCKS4_TLS_BASE_PORT + SOCKS4_TLS_PORTS - 1)) ($SOCKS4_TLS_PORTS ports)"
fi
if [ "$SOCKS5_TLS_PORTS" -gt 0 ]; then
    echo "SOCKS5_TLS: $SOCKS5_TLS_BASE_PORT-$((SOCKS5_TLS_BASE_PORT + SOCKS5_TLS_PORTS - 1)) ($SOCKS5_TLS_PORTS ports)"
fi
if [ "$HTTP_TLS_PORTS" -gt 0 ]; then
    echo "HTTP_TLS: $HTTP_TLS_BASE_PORT-$((HTTP_TLS_BASE_PORT + HTTP_TLS_PORTS - 1)) ($HTTP_TLS_PORTS ports)"
fi
if [ "$HTTP2_TLS_PORTS" -gt 0 ]; then
    echo "HTTP2_TLS: $HTTP2_TLS_BASE_PORT-$((HTTP2_TLS_BASE_PORT + HTTP2_TLS_PORTS - 1)) ($HTTP2_TLS_PORTS ports)"
fi
echo "================================"

echo "Managing TLS certificates..."
/usr/local/bin/manage_certs.sh

echo "Generating GOST config file at: $GOST_CFG..."
"$GOST_CFG_GENERATOR" "$GOST_CFG"

if [ ! -f "$GOST_CFG" ]; then
    echo "ERROR: GOST config file not found at: $GOST_CFG" >&2
    exit 1
fi

echo "Starting GOST with config file: $GOST_CFG"
exec "$GOST_BIN" -C "$GOST_CFG"