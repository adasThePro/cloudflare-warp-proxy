FROM ubuntu:latest

ARG GOST_VERSION=3.2.5
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    python3 \
    netcat-openbsd \
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
COPY fake_server.sh /usr/local/bin/fake_server.sh
COPY generate_gost_config.sh /usr/local/bin/generate_gost_config.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/fake_server.sh /usr/local/bin/generate_gost_config.sh

EXPOSE 1080-1099 8080

ENV GOST_LOGGER_LEVEL=info
ENV NUM_PORTS=1
ENV SOCKS5_USER=
ENV SOCKS5_PASS=
ENV PORT=

ENTRYPOINT ["/usr/bin/env", "bash", "/entrypoint.sh"]