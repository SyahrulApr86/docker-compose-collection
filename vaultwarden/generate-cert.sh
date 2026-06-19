#!/bin/bash
# Generate self-signed cert for Vaultwarden HTTPS
# Replace 192.168.1.103 with your server IP
IP=${1:-192.168.1.103}
mkdir -p certs
openssl req -x509 -newkey rsa:4096 \
  -keyout certs/key.pem \
  -out certs/cert.pem \
  -days 3650 -nodes \
  -subj "/CN=$IP" \
  -addext "subjectAltName=IP:$IP"
echo "Cert generated for $IP"
