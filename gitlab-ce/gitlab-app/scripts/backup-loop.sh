#!/bin/sh
set -e

mc alias set local "http://${MINIO_ENDPOINT}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" >/dev/null

while true; do
  echo "$(date -Iseconds) starting gitlab-backup create ..."
  if docker exec "${GITLAB_APP_CONTAINER}" gitlab-backup create SKIP=registry STRATEGY=copy; then
    latest=$(docker exec "${GITLAB_APP_CONTAINER}" sh -c "ls -t /var/opt/gitlab/backups/*_gitlab_backup.tar | head -1")
    if [ -n "$latest" ]; then
      echo "$(date -Iseconds) uploading $latest to MinIO bucket gitlab-backups"
      docker cp "${GITLAB_APP_CONTAINER}:${latest}" "/tmp/$(basename "$latest")"
      mc cp "/tmp/$(basename "$latest")" "local/gitlab-backups/$(basename "$latest")" \
        || echo "$(date -Iseconds) WARNING: upload to MinIO failed, backup still kept in gitlab_app volume"
      rm -f "/tmp/$(basename "$latest")"
    fi
  else
    echo "$(date -Iseconds) backup create FAILED, will retry next cycle"
  fi

  echo "$(date -Iseconds) backup cycle done, sleeping ${BACKUP_SCHEDULE_SECONDS:-86400}s"
  sleep "${BACKUP_SCHEDULE_SECONDS:-86400}"
done
