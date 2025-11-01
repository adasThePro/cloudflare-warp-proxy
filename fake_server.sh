#!/usr/bin/env bash

PORT=$1
while true; do
    response="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n<html><body><h1>Service Running</h1><p>WARP + SOCKS5 Proxy Service is active.</p></body></html>"
    echo -e "$response" | nc -l -p "$PORT" -q 1 > /dev/null 2>&1
done