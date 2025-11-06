# Cloudflare WARP Proxy

A Docker-based proxy service that routes traffic through Cloudflare WARP, providing multiple proxy protocols including SOCKS4, SOCKS5, HTTP, and HTTP/2 with optional authentication and TLS encryption.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
  - [Using Docker](#using-docker)
  - [Using Docker Compose](#using-docker-compose)
  - [Building from Source](#building-from-source)
- [Configuration](#configuration)
  - [Proxy Type](#proxy-type)
  - [Base Port](#base-port)
  - [Authentication](#authentication)
  - [TLS Certificate](#tls-certificate)
  - [Logging](#logging)
- [DNS](#dns)
- [Volumes](#volumes)
- [License](#license)

## Features

- Mask real IP with Cloudflare IP
- Multiple proxy protocols
- Authentication support
- Cloudflare DNS over HTTPS, TLS, and UDP
- TLS encryption

## Quick Start

### Using Docker

Build and run the container:
```bash
docker run -d \
    --name cloudflare-warp-proxy \
    -e SOCKS5_PORTS=1 \
    -p 1180:1180 \
    ghcr.io/adasThePro/cloudflare-warp-proxy:latest
```

**Image Tags:**
- `latest`: Latest build with newest WARP client version
- `<warp_version>`: Specific WARP client version (e.g., `2025.8.779.0`)
- `build-<hash>`: Specific build identified by hash

Images are built automatically when new WARP client versions are released.

### Using Docker Compose

```bash
git clone https://github.com/adasThePro/cloudflare-warp-proxy.git
cd cloudflare-warp-proxy
docker-compose up -d
```

### Building from Source

```bash
git clone https://github.com/adasThePro/cloudflare-warp-proxy.git
cd cloudflare-warp-proxy
docker build -t cloudflare-warp-proxy .
```

## Configuration

### Proxy Type

Configure the number of ports for each proxy type using these environment variables. Set to `0` to disable a proxy type.

- `SOCKS4_PORTS`: Number of SOCKS4 ports
- `SOCKS5_PORTS`: Number of SOCKS5 ports
- `HTTP_PORTS`: Number of HTTP ports
- `SOCKS4_TLS_PORTS`: Number of TLS-enabled SOCKS4 ports
- `SOCKS5_TLS_PORTS`: Number of TLS-enabled SOCKS5 ports
- `HTTP_TLS_PORTS`: Number of TLS-enabled HTTP ports
- `HTTP2_TLS_PORTS`: Number of TLS-enabled HTTP/2 ports

>[!NOTE]
> - At least one proxy type must be enabled.
> - HTTP/2 proxy requires TLS to be enabled.

### Base Port

Configure the starting port for each proxy type:

- `SOCKS4_BASE_PORT`: Base port for SOCKS4 (default: `1080`)
- `SOCKS5_BASE_PORT`: Base port for SOCKS5 (default: `1180`)
- `HTTP_BASE_PORT`: Base port for HTTP (default: `1280`)
- `SOCKS4_TLS_BASE_PORT`: Base port for TLS-enabled SOCKS4 (default: `1380`)
- `SOCKS5_TLS_BASE_PORT`: Base port for TLS-enabled SOCKS5 (default: `1480`)
- `HTTP_TLS_BASE_PORT`: Base port for TLS-enabled HTTP (default: `1580`)
- `HTTP2_TLS_BASE_PORT`: Base port for TLS-enabled HTTP/2 (default: `1680`)

**Example:** If `SOCKS5_PORTS=5` and `SOCKS5_BASE_PORT=1180`, the proxy will listen on ports `1180` to `1184`.

### Authentication

Configure authentication for supported proxy types. Both username and password must be set to enable authentication.

**Note:** SOCKS4 does not support authentication.

#### SOCKS4

Socks4 does not support authentication.

#### SOCKS5
- `SOCKS5_USER`: Username for SOCKS5 proxies
- `SOCKS5_PASS`: Password for SOCKS5 proxies

#### HTTP
- `HTTP_USER`: Username for HTTP proxies
- `HTTP_PASS`: Password for HTTP proxies

#### SOCKS5 TLS
- `SOCKS5_TLS_USER`: Username for TLS-enabled SOCKS5 proxies
- `SOCKS5_TLS_PASS`: Password for TLS-enabled SOCKS5 proxies

#### HTTP TLS
- `HTTP_TLS_USER`: Username for TLS-enabled HTTP proxies
- `HTTP_TLS_PASS`: Password for TLS-enabled HTTP proxies

#### HTTP/2 TLS
- `HTTP2_TLS_USER`: Username for TLS-enabled HTTP/2 proxies
- `HTTP2_TLS_PASS`: Password for TLS-enabled HTTP/2 proxies

### TLS Certificate

TLS certificate files are required when using TLS-enabled proxy types. Two methods are available to provide the certificate files:

#### Build-time

1. Create a `certs` directory in the project root
2. Place your certificate files:
    - `server.crt`: TLS certificate file
    - `server.key`: TLS private key file
3. Build the Docker image

#### Run-time

Mount a directory containing the certificate files to `/user-certs` when running the container:

```bash
docker run -d \
    -v /path/to/your/certs:/user-certs:ro \
    -e TLS_KEY_PASS=your_password \
    cloudflare-warp-proxy
```

The mounted directory must contain:
- `server.crt` - TLS certificate
- `server.key` - Private key

#### Options
- `TLS_KEY_PASS`: Password for the TLS private key (if encrypted)
- `FORCE_CERT_REPLACE`: Set to `true` to force replacement of existing certificate files on startup

### Logging

- `GOST_LOGGER_LEVEL`: Set the logging level for GOST (default: `info`).
    - Options: `trace`, `debug`, `info`, `warn`, `error`, `fatal`

## DNS

The proxy uses Cloudflare DNS with multiple fallback options:
- DNS over HTTPS
- DNS over TLS
- Standard UDP DNS

## Volumes

The following volumes are used:
- `warp-data`: Stores WARP client registration data and configuration
- `certs`: Stores TLS certificate files

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.