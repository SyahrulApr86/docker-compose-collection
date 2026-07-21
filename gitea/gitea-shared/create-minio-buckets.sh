#!/bin/sh

set -eu

MAX_ATTEMPTS="${MAX_ATTEMPTS:-5}"
SLEEP_SECONDS="${SLEEP_SECONDS:-3}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

attempt=1
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  if mc alias set myminio http://minio:9000 "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" >/dev/null 2>&1; then
    mc mb "myminio/$S3_BUCKET_NAME" --ignore-existing >/dev/null 2>&1
    log "Bucket '$S3_BUCKET_NAME' is ready."

    if [ -n "${PG_BACKUP_S3_BUCKET:-}" ]; then
      mc mb "myminio/$PG_BACKUP_S3_BUCKET" --ignore-existing >/dev/null 2>&1
      log "Bucket '$PG_BACKUP_S3_BUCKET' is ready."
    fi

    exit 0
  fi

  log "Attempt $attempt/$MAX_ATTEMPTS failed, retrying in ${SLEEP_SECONDS}s..."
  attempt=$((attempt + 1))
  sleep "$SLEEP_SECONDS"
done

log "Failed to create bucket '$S3_BUCKET_NAME' after $MAX_ATTEMPTS attempts."
exit 1
