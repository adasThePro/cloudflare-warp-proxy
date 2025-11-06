FROM ubuntu:latest

ARG GOST_VERSION=3.2.5
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    openssl \
    python3 \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [arch=${TARGETARCH} signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update && \
    apt-get install -y cloudflare-warp && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fSL -o /tmp/gost.tar.gz \
      "https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_${TARGETARCH}.tar.gz"; \
    tar -xzf /tmp/gost.tar.gz -C /tmp; \
    mv /tmp/gost /usr/local/bin/gost; \
    chmod +x /usr/local/bin/gost; \
    rm -f /tmp/gost.tar.gz; \
    /usr/local/bin/gost -V || true

COPY entrypoint.sh /entrypoint.sh
COPY generate_gost_config.sh /usr/local/bin/generate_gost_config.sh
COPY manage_certs.sh /usr/local/bin/manage_certs.sh
COPY certs /build-certs

RUN chmod +x /entrypoint.sh /usr/local/bin/generate_gost_config.sh /usr/local/bin/manage_certs.sh

# Proxy ports: 1080-1780
EXPOSE 1080-1780

# GOST logging level (trace, debug, info, warn, error, fatal)
ENV GOST_LOGGER_LEVEL=info

# Proxy type configuration: number of ports for each type
# Set to 0 to disable
ENV SOCKS4_PORTS=0
ENV SOCKS5_PORTS=0
ENV HTTP_PORTS=0
ENV SOCKS4_TLS_PORTS=0
ENV SOCKS5_TLS_PORTS=0
ENV HTTP_TLS_PORTS=0
ENV HTTP2_TLS_PORTS=0

# Base ports for each proxy type
ENV SOCKS4_BASE_PORT=1080
ENV SOCKS5_BASE_PORT=1180
ENV HTTP_BASE_PORT=1280
ENV SOCKS4_TLS_BASE_PORT=1380
ENV SOCKS5_TLS_BASE_PORT=1480
ENV HTTP_TLS_BASE_PORT=1580
ENV HTTP2_TLS_BASE_PORT=1680

# Proxy authentication (both username and password must be set to enable)
# SOCKS4 does not support authentication
# SOCKS5 authentication
ENV SOCKS5_USER=
ENV SOCKS5_PASS=
# HTTP authentication
ENV HTTP_USER=
ENV HTTP_PASS=
# SOCKS5 TLS authentication
ENV SOCKS5_TLS_USER=
ENV SOCKS5_TLS_PASS=
# HTTP TLS authentication
ENV HTTP_TLS_USER=
ENV HTTP_TLS_PASS=
# HTTP2 TLS authentication
ENV HTTP2_TLS_USER=
ENV HTTP2_TLS_PASS=

# TLS certificate configuration
# Method 1: Place certificate files in 'certs' folder before building (copied to /build-certs during build)
# Method 2: Mount certificate files to /user-certs at runtime (must contain server.crt and server.key)
# If private key is password-protected, set TLS_KEY_PASS environment variable
ENV TLS_KEY_PASS=
# Force replacement of existing certificate files even if they are valid
ENV FORCE_CERT_REPLACE=

ENTRYPOINT ["/usr/bin/env", "bash", "/entrypoint.sh"]