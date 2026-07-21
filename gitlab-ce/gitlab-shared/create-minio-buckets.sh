#!/bin/sh
set -e

mc alias set local http://minio:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"

for bucket in gitlab-artifacts gitlab-uploads gitlab-lfs gitlab-packages \
              gitlab-external-diffs gitlab-terraform-state gitlab-pages \
              gitlab-dependency-proxy gitlab-backups gitlab-registry; do
  mc mb --ignore-existing "local/${bucket}"
done

echo "MinIO buckets ready."
