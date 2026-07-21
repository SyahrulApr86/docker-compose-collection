# Gitea Shared Infrastructure

This directory now uses a single `docker-compose.yml` as the default shared stack.

The stack includes:

- PostgreSQL with pgBackRest installed for WAL archiving
- `backup-full` sidecar for periodic full backups
- `backup-diff` sidecar for periodic differential backups
- `backup-check` one-shot validation before backup loops start
- Redis
- MinIO
- automatic bucket initialization for app data and backup data

## Start

```bash
cd gitea-shared
docker compose up -d --build
```

## What Runs

1. `db`
   PostgreSQL with `archive_command` enabled via a pgBackRest wrapper that can bootstrap the stanza safely.

2. `backup-check`
   Runs `stanza-create` and `pgbackrest check` once before the long-lived backup runners start.

3. `backup-full`
   Runs `pgbackrest backup --type=full` in a loop.

4. `backup-diff`
   Waits for the first full backup to exist and for the startup full-backup pass to finish, then runs `pgbackrest backup --type=diff` in a loop.

5. `redis`
   Shared cache, session, queue, and distributed lock backend.

6. `minio`
   Shared object storage for Gitea and pgBackRest backup repository.

## Backup Intervals

- `PG_BACKUP_FULL_INTERVAL_SECONDS=86400`
- `PG_BACKUP_DIFF_INTERVAL_SECONDS=21600`
- `PG_BACKUP_RETRY_INTERVAL_SECONDS=60`

Retention is handled automatically by pgBackRest through:

- `repo1-retention-full=${PG_BACKUP_RETENTION}`
- `repo1-retention-archive=${PG_BACKUP_RETENTION}`

Default backup repository mode for this same-host stack is:

- `PG_BACKUP_REPO_TYPE=posix`

This uses the shared `pgbackrest_state` Docker volume as the local pgBackRest repository.

## Manual Backup

```bash
docker exec gitea_backup_full /backup-scripts/backup-manual.sh full
docker exec gitea_backup_diff /backup-scripts/backup-manual.sh diff
docker exec gitea_backup_diff /backup-scripts/backup-manual.sh incr
```

## Status Checks

```bash
docker compose ps
docker logs gitea_backup_check
docker logs gitea_backup_full --tail 50
docker logs gitea_backup_diff --tail 50
docker exec gitea_backup_full pgbackrest --stanza=db info
```

## Notes

- This is now the single source of truth for shared infra in this repo.
- `createbuckets` prepares both the app bucket and the backup bucket.
- `db` waits for MinIO and bucket initialization before PostgreSQL starts, so WAL archiving does not race the backup repo bootstrap.
- `backup-check` narrows the gap between PostgreSQL startup and stanza readiness.
- `backup-diff` waits for an initial full backup and a startup completion marker, so it does not race `backup-full` during bootstrap.
- If you switch `PG_BACKUP_REPO_TYPE` to `s3`, use a TLS-enabled S3-compatible endpoint. The MinIO service in this compose file is plain HTTP by default, so it is suitable for app object storage but not a drop-in pgBackRest S3 repo without extra TLS setup.
- If you need exact wall-clock backup times instead of interval-based loops, the runner script can be adjusted later.
