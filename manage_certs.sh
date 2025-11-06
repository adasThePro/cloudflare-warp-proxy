#!/usr/bin/env bash
set -euo pipefail

BUILD_CERTS_DIR="/build-certs"
MOUNT_CERTS_DIR="/user-certs"
CERT_DIR="/etc/certs"
BUILD_CERT="$BUILD_CERTS_DIR/server.crt"
BUILD_KEY="$BUILD_CERTS_DIR/server.key"
MOUNT_CERT="$MOUNT_CERTS_DIR/server.crt"
MOUNT_KEY="$MOUNT_CERTS_DIR/server.key"
DEFAULT_CERT="$CERT_DIR/server.crt"
DEFAULT_KEY="$CERT_DIR/server.key"

TLS_KEY_PASS="${TLS_KEY_PASS:-}"
FORCE_CERT_REPLACE="${FORCE_CERT_REPLACE:-false}"

mkdir -p "$CERT_DIR"

needs_tls() {
    local socks4_tls_ports="${SOCKS4_TLS_PORTS:-0}"
    local socks5_tls_ports="${SOCKS5_TLS_PORTS:-0}"
    local http_tls_ports="${HTTP_TLS_PORTS:-0}"
    local http2_tls_ports="${HTTP2_TLS_PORTS:-0}"
    
    if [ "$socks4_tls_ports" -gt 0 ] || [ "$socks5_tls_ports" -gt 0 ] || \
       [ "$http_tls_ports" -gt 0 ] || [ "$http2_tls_ports" -gt 0 ]; then
        return 0
    fi
    return 1
}

validate_certificate() {
    local cert_file="$1"

    if [ ! -r "$cert_file" ]; then
        echo "ERROR: Certificate file is not readable: $cert_file" >&2
        return 1
    fi
    
    if ! openssl x509 -in "$cert_file" -noout > /dev/null 2>&1; then
        echo "ERROR: Invalid certificate format: $cert_file" >&2
        return 1
    fi

    if ! openssl x509 -in "$cert_file" -noout -checkend 0 > /dev/null 2>&1; then
        echo "ERROR: Certificate has expired: $cert_file" >&2
        return 1
    fi
    
    return 0
}

validate_and_decrypt_key() {
    local key_file="$1"
    local password="${2:-}"
    local output_file="$3"
    local tmp_file=""
    
    if [ ! -r "$key_file" ]; then
        echo "ERROR: Key file is not readable: $key_file" >&2
        return 1
    fi

    if grep -q "ENCRYPTED" "$key_file"; then
        
        if [ -z "$password" ]; then
            echo "ERROR: Private key is encrypted but TLS_KEY_PASS is not provided" >&2
            return 1
        fi

        tmp_file=$(mktemp "${output_file}.XXXXXX")
        trap "rm -f '$tmp_file'" RETURN

        if ! openssl rsa -in "$key_file" -out "$tmp_file" -passin pass:"$password" > /dev/null 2>&1; then
            echo "ERROR: Failed to decrypt private key. Invalid password?" >&2
            return 1
        fi

        cp "$tmp_file" "$output_file"
        chmod 600 "$output_file"
        return 0
    fi

    if ! openssl rsa -in "$key_file" -noout -check > /dev/null 2>&1; then
        echo "ERROR: Invalid private key format: $key_file" >&2
        return 1
    fi

    if [ "$key_file" != "$output_file" ]; then
        cp "$key_file" "$output_file"
        chmod 600 "$output_file"
    fi

    return 0
}

process_build_certs() {
    if [ ! -f "$BUILD_CERT" ] || [ ! -f "$BUILD_KEY" ]; then
        return 1
    fi

    if ! validate_certificate "$BUILD_CERT"; then
        return 1
    fi

    if ! validate_and_decrypt_key "$BUILD_KEY" "$TLS_KEY_PASS" "$DEFAULT_KEY"; then
        return 1
    fi

    cp "$BUILD_CERT" "$DEFAULT_CERT"
    chmod 644 "$DEFAULT_CERT"
    rm -rf "$BUILD_CERTS_DIR"

    return 0
}

process_mount_certs() {
    if [ ! -f "$MOUNT_CERT" ] || [ ! -f "$MOUNT_KEY" ]; then
        return 1
    fi

    if ! validate_certificate "$MOUNT_CERT"; then
        return 1
    fi

    if ! validate_and_decrypt_key "$MOUNT_KEY" "$TLS_KEY_PASS" "$DEFAULT_KEY"; then
        return 1
    fi

    cp "$MOUNT_CERT" "$DEFAULT_CERT"
    chmod 644 "$DEFAULT_CERT"

    return 0
}

process_default_certs() {
    if ! validate_certificate "$DEFAULT_CERT"; then
        return 1
    fi

    if ! validate_and_decrypt_key "$DEFAULT_KEY" "$TLS_KEY_PASS" "$DEFAULT_KEY"; then
        return 1
    fi

    return 0
}

if ! needs_tls; then
    echo "No TLS proxy types enabled, skipping certificate management"
    exit 0
fi


if [ -f "$DEFAULT_CERT" ] && [ -f "$DEFAULT_KEY" ] && [ "$FORCE_CERT_REPLACE" != "true" ]; then
    if process_default_certs; then
        echo "Existing certificate files are valid"
        exit 0
    fi

    echo "Existing certificate files are invalid, attempting to replace them..."

    if process_build_certs; then
        echo "Replaced existing certificate files with build certificate files"
        exit 0
    fi

    if process_mount_certs; then
        echo "Replaced existing certificate files with mount certificate files"
        exit 0
    fi

    echo "Unable to replace existing certificate files with new ones"
    exit 1

fi

if [ -f "$BUILD_CERT" ] && [ -f "$BUILD_KEY" ]; then
    echo "Configuring build certificate files..."

    if process_build_certs; then
        echo "Build certificate files configured successfully"
        exit 0
    fi

    echo "Unable to configure build certificate files"
    exit 1
fi

if [ -f "$MOUNT_CERT" ] && [ -f "$MOUNT_KEY" ]; then
    echo "Configuring mount certificate files..."

    if process_mount_certs; then
        echo "Mount certificate files configured successfully"
        exit 0
    fi

    echo "Unable to configure mount certificate files"
    exit 1
fi

echo "ERROR: TLS proxy types are enabled but no valid certificate configuration provided" >&2
echo "Please provide certificates using one of these methods:" >&2
echo "1. Build-time: Place server.crt and server.key in the 'certs' folder before building" >&2
echo "2. Runtime: Mount certificates to /user-certs with files named server.crt and server.key" >&2
exit 1