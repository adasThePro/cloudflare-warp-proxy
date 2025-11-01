# Cloudflare WARP Proxy

A Docker container that runs Cloudflare WARP and exposes it as a SOCKS5 proxy server.

## Docker Images

Docker images are automatically created when new WARP client versions are released.

**Available tags:**
- `:latest` - Always contains the most recent WARP client version
- `:warp_version` - Specific WARP client version (e.g., `:2025.8.779.0`)

## Quick Start

Using Docker run:

```bash
docker run -d \
  --name cf-warp-proxy \
  -p 1080:1080 \
  -v warp-data:/var/lib/cloudflare-warp \
  ghcr.io/adasthepro/cloudflare-warp-proxy:latest
```

Or with Docker Compose:

```bash
docker-compose up -d
```

The SOCKS5 proxy will be available at `localhost:1080`.

## Configuration

Edit the environment variables in `docker-compose.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `NUM_PORTS` | `1` | Number of SOCKS5 proxy ports (starting from 1080) |
| `SOCKS5_USER` | empty | SOCKS5 username (leave empty to disable auth) |
| `SOCKS5_PASS` | empty | SOCKS5 password (leave empty to disable auth) |
| `GOST_LOGGER_LEVEL` | `info` | Logging level: trace, debug, info, warn, error, fatal |
| `PORT` | empty | Optional HTTP server port for health checks (e.g., 8080) |

**Volume:** The container uses `warp-data:/var/lib/cloudflare-warp` to persist WARP registration data across restarts. Without this volume, the container will re-register on each startup.

## Usage

### Without Authentication

```bash
curl --proxy socks5://localhost:1080 https://www.cloudflare.com/cdn-cgi/trace
```

### With Authentication

Set `SOCKS5_USER` and `SOCKS5_PASS` in `docker-compose.yml`, then:

```bash
curl --proxy socks5://username:password@localhost:1080 https://www.cloudflare.com/cdn-cgi/trace
```

### Multiple Ports

To use multiple proxy ports, set `NUM_PORTS` and expose additional ports in `docker-compose.yml`:

```yaml
environment:
  - NUM_PORTS=3
ports:
  - "1080:1080"
  - "1081:1081"
  - "1082:1082"
```

## Version Pinning

To use a specific WARP client version instead of the latest:

```yaml
services:
  cf-warp-proxy:
    image: ghcr.io/adasthepro/cloudflare-warp-proxy:2025.8.779.0
```