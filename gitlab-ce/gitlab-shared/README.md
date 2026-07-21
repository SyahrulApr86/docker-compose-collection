# GitLab CE — shared infrastructure

Stateful services shared by the GitLab app node: PostgreSQL, Redis, MinIO
(object storage for artifacts/uploads/LFS/packages/registry/backups).

Mirrors the `gitea/gitea-shared` split-stack pattern in this collection:
stateful services live here, the stateless app + runner + backup sidecar
live in `../gitlab-app/`, connected over the external `gitlab-shared`
Docker network.

## Setup

```bash
cp .env.example .env   # fill in passwords/keys
docker compose up -d
```

Wait for `minio` to report healthy, then `createbuckets` runs once and exits
(`service_completed_successfully`) after creating all buckets GitLab needs.

## Notes

- Unlike the Gitea stack in this collection, this does **not** use
  pgBackRest/WAL archiving on Postgres. GitLab ships its own backup task
  (`gitlab-backup create`) that dumps the DB itself; see `../gitlab-app/`'s
  `backup` sidecar for how the resulting archive gets pushed to the
  `gitlab-backups` MinIO bucket on a schedule.
- `POSTGRES_PORT`/`MINIO_API_PORT`/`MINIO_CONSOLE_PORT` only need a host port
  published if you need external access (e.g. `mc` from your laptop, or a
  DB client). The `gitlab-app` stack talks to these over the `gitlab-shared`
  network by container name, no host port required.
