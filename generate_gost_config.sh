#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/etc/gost/config.json}"
NUM_PORTS="${NUM_PORTS:-1}"
BASE_PORT="1080"
LISTEN_ADDR="0.0.0.0"
WARP_PROXY="127.0.0.1:6969"
SOCKS5_USER="${SOCKS5_USER:-}"
SOCKS5_PASS="${SOCKS5_PASS:-}"

mkdir -p "$(dirname "$OUT")"

json_escape() {
  python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$1"
}

J_USER=$(json_escape "$SOCKS5_USER")
J_PASS=$(json_escape "$SOCKS5_PASS")

services_json="["

for ((i=0;i<NUM_PORTS;i++)); do
  port=$((BASE_PORT + i))
  [ $i -gt 0 ] && services_json+=","
  services_json+=$(cat <<EOF
{
  "name": "socks-proxy-${port}",
  "addr": ":${port}",
  "handler": {
    "type": "socks5",
    "auth": { "username": ${J_USER}, "password": ${J_PASS} },
    "chain": "warp-chain"
  },
  "resolver": "cloudflare-resolver"
}
EOF
)
done

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
      }
    ]
  }
]
EOF
)

resolvers_json=$(cat <<'EOF'
[
  {
    "name": "cloudflare-resolver",
    "nameservers": [
      { "addr": "https://cloudflare-dns.com/dns-query", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      { "addr": "https://1.1.1.1/dns-query", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      { "addr": "https://1.0.0.1/dns-query", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      { "addr": "https://[2606:4700:4700::1111]/dns-query", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv6" },
      { "addr": "https://[2606:4700:4700::1001]/dns-query", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv6" },
      { "addr": "tls://1.1.1.1:853", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" },
      { "addr": "udp://1.1.1.1:53", "hostname": "cloudflare-dns.com", "ttl": 60, "prefer": "ipv4" }
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
print("GOST JSON config generated at:", f)
PY