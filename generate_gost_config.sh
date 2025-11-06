#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/etc/gost/config.json}"

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
SOCKS4_TLS_BASE_PORT="${SOCKS4_TLS_BASE_PORT:-1380}"
SOCKS5_TLS_BASE_PORT="${SOCKS5_TLS_BASE_PORT:-1480}"
HTTP_TLS_BASE_PORT="${HTTP_TLS_BASE_PORT:-1580}"
HTTP2_TLS_BASE_PORT="${HTTP2_TLS_BASE_PORT:-1680}"

SOCKS5_USER="${SOCKS5_USER:-}"
SOCKS5_PASS="${SOCKS5_PASS:-}"
HTTP_USER="${HTTP_USER:-}"
HTTP_PASS="${HTTP_PASS:-}"
SOCKS5_TLS_USER="${SOCKS5_TLS_USER:-}"
SOCKS5_TLS_PASS="${SOCKS5_TLS_PASS:-}"
HTTP_TLS_USER="${HTTP_TLS_USER:-}"
HTTP_TLS_PASS="${HTTP_TLS_PASS:-}"
HTTP2_TLS_USER="${HTTP2_TLS_USER:-}"
HTTP2_TLS_PASS="${HTTP2_TLS_PASS:-}"

WARP_PROXY="127.0.0.1:6969"
CERT_FILE="/etc/certs/server.crt"
KEY_FILE="/etc/certs/server.key"

mkdir -p "$(dirname "$OUT")"

json_escape() {
    python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$1"
}

SOCKS5_J_USER=$(json_escape "$SOCKS5_USER")
SOCKS5_J_PASS=$(json_escape "$SOCKS5_PASS")
HTTP_J_USER=$(json_escape "$HTTP_USER")
HTTP_J_PASS=$(json_escape "$HTTP_PASS")
SOCKS5_TLS_J_USER=$(json_escape "$SOCKS5_TLS_USER")
SOCKS5_TLS_J_PASS=$(json_escape "$SOCKS5_TLS_PASS")
HTTP_TLS_J_USER=$(json_escape "$HTTP_TLS_USER")
HTTP_TLS_J_PASS=$(json_escape "$HTTP_TLS_PASS")
HTTP2_TLS_J_USER=$(json_escape "$HTTP2_TLS_USER")
HTTP2_TLS_J_PASS=$(json_escape "$HTTP2_TLS_PASS")

services_json="["
first_service=true

if [ "$SOCKS4_PORTS" -gt 0 ]; then
	for ((i=0;i<SOCKS4_PORTS;i++)); do
		port=$((SOCKS4_BASE_PORT + i))
		
		if [ "$first_service" = false ]; then
			services_json+=","
		fi
		first_service=false
		
		services_json+=$(cat <<EOF
{
	"name": "socks4-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "socks4",
		"chain": "warp-chain"
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
	done
fi

if [ "$SOCKS5_PORTS" -gt 0 ]; then
	for ((i=0;i<SOCKS5_PORTS;i++)); do
		port=$((SOCKS5_BASE_PORT + i))
		
		if [ "$first_service" = false ]; then
			services_json+=","
		fi
		first_service=false
		
		if [ -n "$SOCKS5_USER" ] && [ -n "$SOCKS5_PASS" ]; then
			services_json+=$(cat <<EOF
{
	"name": "socks5-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "socks5",
		"auth": { "username": ${SOCKS5_J_USER}, "password": ${SOCKS5_J_PASS} },
		"chain": "warp-chain"
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		else
			services_json+=$(cat <<EOF
{
	"name": "socks5-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "socks5",
		"chain": "warp-chain"
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		fi
	done
fi

if [ "$HTTP_PORTS" -gt 0 ]; then
	for ((i=0;i<HTTP_PORTS;i++)); do
		port=$((HTTP_BASE_PORT + i))
		
		if [ "$first_service" = false ]; then
			services_json+=","
		fi
		first_service=false
		
		if [ -n "$HTTP_USER" ] && [ -n "$HTTP_PASS" ]; then
			services_json+=$(cat <<EOF
{
	"name": "http-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "http",
		"auth": { "username": ${HTTP_J_USER}, "password": ${HTTP_J_PASS} },
		"chain": "warp-chain"
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		else
			services_json+=$(cat <<EOF
{
	"name": "http-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "http",
		"chain": "warp-chain"
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		fi
	done
fi

if [ "$SOCKS4_TLS_PORTS" -gt 0 ]; then
	for ((i=0;i<SOCKS4_TLS_PORTS;i++)); do
		port=$((SOCKS4_TLS_BASE_PORT + i))
		
		if [ "$first_service" = false ]; then
			services_json+=","
		fi
		first_service=false
		
		services_json+=$(cat <<EOF
{
	"name": "socks4-tls-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "socks4",
		"chain": "warp-chain"
	},
	"listener": {
		"type": "tls",
		"tls": {
			"certFile": "${CERT_FILE}",
			"keyFile": "${KEY_FILE}"
		}
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
	done
fi

if [ "$SOCKS5_TLS_PORTS" -gt 0 ]; then
	for ((i=0;i<SOCKS5_TLS_PORTS;i++)); do
		port=$((SOCKS5_TLS_BASE_PORT + i))
		
		if [ "$first_service" = false ]; then
			services_json+=","
		fi
		first_service=false
		
		if [ -n "$SOCKS5_TLS_USER" ] && [ -n "$SOCKS5_TLS_PASS" ]; then
			services_json+=$(cat <<EOF
{
	"name": "socks5-tls-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "socks5",
		"auth": { "username": ${SOCKS5_TLS_J_USER}, "password": ${SOCKS5_TLS_J_PASS} },
		"chain": "warp-chain"
	},
	"listener": {
		"type": "tls",
		"tls": {
			"certFile": "${CERT_FILE}",
			"keyFile": "${KEY_FILE}"
		}
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		else
			services_json+=$(cat <<EOF
{
	"name": "socks5-tls-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "socks5",
		"chain": "warp-chain"
	},
	"listener": {
		"type": "tls",
		"tls": {
			"certFile": "${CERT_FILE}",
			"keyFile": "${KEY_FILE}"
		}
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		fi
	done
fi

if [ "$HTTP_TLS_PORTS" -gt 0 ]; then
	for ((i=0;i<HTTP_TLS_PORTS;i++)); do
		port=$((HTTP_TLS_BASE_PORT + i))
		
		if [ "$first_service" = false ]; then
			services_json+=","
		fi
		first_service=false
		
		if [ -n "$HTTP_TLS_USER" ] && [ -n "$HTTP_TLS_PASS" ]; then
			services_json+=$(cat <<EOF
{
	"name": "http-tls-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "http",
		"auth": { "username": ${HTTP_TLS_J_USER}, "password": ${HTTP_TLS_J_PASS} },
		"chain": "warp-chain"
	},
	"listener": {
		"type": "tls",
		"tls": {
			"certFile": "${CERT_FILE}",
			"keyFile": "${KEY_FILE}"
		}
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		else
			services_json+=$(cat <<EOF
{
	"name": "http-tls-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "http",
		"chain": "warp-chain"
	},
	"listener": {
		"type": "tls",
		"tls": {
			"certFile": "${CERT_FILE}",
			"keyFile": "${KEY_FILE}"
		}
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		fi
	done
fi

if [ "$HTTP2_TLS_PORTS" -gt 0 ]; then
	for ((i=0;i<HTTP2_TLS_PORTS;i++)); do
		port=$((HTTP2_TLS_BASE_PORT + i))
		
		if [ "$first_service" = false ]; then
			services_json+=","
		fi
		first_service=false
		
		if [ -n "$HTTP2_TLS_USER" ] && [ -n "$HTTP2_TLS_PASS" ]; then
			services_json+=$(cat <<EOF
{
	"name": "http2-tls-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "http2",
		"auth": { "username": ${HTTP2_TLS_J_USER}, "password": ${HTTP2_TLS_J_PASS} },
		"chain": "warp-chain"
	},
	"listener": {
		"type": "http2",
		"tls": {
			"certFile": "${CERT_FILE}",
			"keyFile": "${KEY_FILE}"
		}
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		else
			services_json+=$(cat <<EOF
{
	"name": "http2-tls-${port}",
	"addr": ":${port}",
	"handler": {
		"type": "http2",
		"chain": "warp-chain"
	},
	"listener": {
		"type": "http2",
		"tls": {
			"certFile": "${CERT_FILE}",
			"keyFile": "${KEY_FILE}"
		}
	},
	"resolver": "cloudflare-resolver"
}
EOF
)
		fi
	done
fi

services_json+="]"

chains_json=$(cat <<EOF
[
  	{
    	"name": "warp-chain",
    	"selector": { "strategy": "round" },
    	"hops": [
      	{
        	"name": "warp-hop",
        	"nodes": [
          		{
            		"name": "warp-socks5",
            		"addr": "${WARP_PROXY}",
            		"connector": { "type": "socks5" }
          		}
        	]
      	}]
  	}
]
EOF
)

resolvers_json=$(cat <<EOF
[
  	{
    	"name": "cloudflare-resolver",
    	"nameservers": [
      		{ "addr": "https://cloudflare-dns.com/dns-query", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      		{ "addr": "https://[2606:4700:4700::1111]/dns-query", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv6" },
      		{ "addr": "tls://1.1.1.1:853", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      		{ "addr": "tls://1.0.0.1:853", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      		{ "addr": "udp://1.1.1.1:53", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      		{ "addr": "udp://1.0.0.1:53", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" }
    	]
  	}
]
EOF
)

cat > "$OUT" <<EOF
{
  	"services": $services_json,
  	"chains": $chains_json,
  	"resolvers": $resolvers_json
}
EOF

python3 - <<PY "$OUT"
import json, sys
f = sys.argv[1]
data = json.load(open(f))
json.dump(data, open(f, "w"), indent=2)
print(f"GOST JSON config file generated at: {f}")
PY