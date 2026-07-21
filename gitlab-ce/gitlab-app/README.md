# GitLab CE — app node (+ runner + backup)

Omnibus `gitlab/gitlab-ce` configured to use **external** PostgreSQL, Redis
and MinIO from `../gitlab-shared/` instead of the bundled ones, so the app
node stays stateless and disposable — same idea as the `gitea/gitea-app`
split in this collection. Bundles one `gitlab-runner` (Docker executor) and
one `backup` sidecar that runs GitLab's own backup task on a schedule and
uploads the result to MinIO.

## Requirements

- `gitlab-shared` stack already up and healthy (external network `gitlab-shared`).
- An external Docker network named `proxy` if you're fronting this with a
  reverse proxy (Nginx Proxy Manager, Traefik, etc). Otherwise drop the
  `proxy` network from `docker-compose.yml` and just publish
  `GITLAB_HTTP_PORT` directly.

## Setup

```bash
cp .env.example .env   # fill in shared secrets (must match gitlab-shared/.env)
                        # and GITLAB_EXTERNAL_URL / GITLAB_HOSTNAME
docker compose up -d gitlab
```

First boot (`gitlab reconfigure`) takes several minutes. Watch it:

```bash
docker compose logs -f gitlab
```

Once healthy, log in as `root` — get the auto-generated initial password:

```bash
docker exec gitlab_app cat /etc/gitlab/initial_root_password
```

(That file self-destructs after 24h — change the root password before then.)

### Enable the runner

Classic registration tokens are disabled by default on recent GitLab
versions. As `root`:

1. Admin Area → Settings → CI/CD → Continuous Integration and Deployment →
   check **"Allow runner registration token"** → Save.
2. Admin Area → CI/CD → Runners → copy the **registration token**.
3. Put it in `.env` as `GITLAB_RUNNER_REGISTRATION_TOKEN`, then:

```bash
docker compose up -d runner
```

The runner registers itself once (`register-and-run.sh` checks
`/etc/gitlab-runner/config.toml` first, so re-creating the container won't
double-register) and stays running afterwards.

### Backups

```bash
docker compose up -d backup
```

Every `GITLAB_BACKUP_SCHEDULE_SECONDS` (default 24h), the sidecar runs
`docker exec gitlab_app gitlab-backup create` and uploads the resulting
`*_gitlab_backup.tar` to the `gitlab-backups` bucket in MinIO. It needs
`/var/run/docker.sock` mounted to reach the app container — same trade-off
as any docker-exec-based sidecar, don't expose this stack to untrusted
users.

Note: `gitlab-backup create` does **not** back up `/etc/gitlab` (secrets,
config). Back that directory up separately (it's small, e.g. a periodic
`tar` of the `gitlab_config` volume to the same MinIO bucket) — losing it
without a copy means an existing backup tar can't be restored into a fresh
install without regenerating secrets.

## Registry (optional)

Off by default (`GITLAB_REGISTRY_ENABLE=false`). To turn on, set it to
`true`, set `GITLAB_REGISTRY_EXTERNAL_URL`, `docker compose up -d gitlab`
to reconfigure, and expose that URL through your reverse proxy same as the
main `GITLAB_EXTERNAL_URL`.
