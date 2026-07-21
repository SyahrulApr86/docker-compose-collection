# Gitea App Deployment

This compose file is now HA-ready for the application tier:

- app nodes use external PostgreSQL, Redis, and MinIO endpoints
- repository data lives on a shared POSIX mount
- shared Gitea config lives on a shared POSIX mount
- node-local runtime data stays local per node
- Gitea Actions is explicitly enabled
- an `act_runner` service auto-registers itself with a shared registration token
- the OCI container registry is explicitly enabled through the package registry
- local Bleve indexes are disabled to avoid split-brain state across nodes

## Deployment Modes

### 1. Same-host lab deployment

Use `gitea-shared` on the same Docker host first:

```bash
cd gitea-shared
docker compose up -d --build
```

Then start the app node:

```bash
cd gitea-app
docker compose -f docker-compose.yml -f docker-compose.lab.yml up -d
```

The default `.env` points to `gitea-shared` service names (`db`, `redis`, `minio`) and `docker-compose.lab.yml` joins the app container to both the `gitea-shared` and `proxy` Docker networks.
It is now tuned for the public reverse-proxy domain `https://gitea.precia.site/`, while still keeping an internal `LOCAL_ROOT_URL` for colocated services such as the built-in runner.

### 2. Real HA deployment

For actual HA across multiple VMs:

1. Provision HA PostgreSQL, HA Redis, and shared MinIO/S3 endpoints.
2. Mount the same shared POSIX paths on every app node for:
   - `GITEA_SHARED_CONF_PATH`
   - `GITEA_SHARED_REPO_PATH`
3. Keep `GITEA_NODE_DATA_PATH` local on each node.
4. Update `gitea-app/.env` on every node with the same:
   - `GITEA_DOMAIN`
   - `GITEA_ROOT_URL`
   - `GITEA_DB_HOST`
   - `GITEA_DB_SSL_MODE`
   - `GITEA_REDIS_HOST`
   - `GITEA_MINIO_ENDPOINT`
    - `MINIO_ACCESS_KEY`
    - `MINIO_SECRET_KEY`
   - `GITEA_SECRET_KEY`
   - `GITEA_INTERNAL_TOKEN`
   - `GITEA_OAUTH2_JWT_SECRET`
   - `LFS_JWT_SECRET`
5. Deploy the same compose file on each node.
6. Put all nodes behind an HTTP/TCP load balancer for web and SSH traffic.

## Why This Is HA-Correct

- `depends_on` was removed because the database, Redis, and MinIO are external HA dependencies, not services in this compose project.
- same-host lab networking is now isolated in `docker-compose.lab.yml`, so the base compose file stays portable for real external endpoints.
- same-host lab can also join your reverse-proxy network without polluting the base compose topology.
- `repository.ROOT` is pinned to `/data/git/repositories`, which must be a shared POSIX mount across nodes.
- Gitea Actions is now turned on explicitly and action logs are stored in MinIO instead of node-local disk.
- The package registry is now turned on explicitly, which also enables the OCI container registry endpoints under `/v2/`.
- `/data/gitea/conf` is shared so app config and SSH host keys stay consistent on every node.
- `/data/gitea/data` is node-local, so transient runtime data does not become a shared writable hotspot.
- `/srv/gitea-ha/runner-data` is node-local, so each node keeps its own runner registration and workspace cache.
- installer state and HA-sensitive secrets are now pinned via environment so a new node can bootstrap deterministically instead of racing through the web installer.
- the `commitgo/gitea-ee` image already ships `sshd`, so the compose file leaves Gitea's built-in SSH server disabled to avoid a port-22 double-bind loop.
- issue indexing uses the database and repository indexing is disabled by default, which avoids node-local Bleve state.

## Required Host Paths

Create these directories before starting the stack:

```bash
sudo mkdir -p /srv/gitea-ha/conf /srv/gitea-ha/repos /srv/gitea-ha/node-data /srv/gitea-ha/runner-data
sudo chown -R 1000:1000 /srv/gitea-ha
```

In a real multi-node deployment, `/srv/gitea-ha/conf` and `/srv/gitea-ha/repos` must be the same shared mount on every node.
For a same-host lab, Docker will create the paths automatically if they do not exist, then Gitea and the runner will chown them as needed.

## Health Check

```bash
docker compose ps
docker compose exec gitea wget -qO- http://localhost:3000/api/v1/version
```

## Actions and Runner

- Actions is explicitly enabled at the instance level.
- New repositories created from this config expose the `repo.actions` unit by default.
- The `runner` service auto-registers itself on first boot by using `GITEA_RUNNER_REGISTRATION_TOKEN`.
- [`act_runner.yaml`](./act_runner.yaml) pins job containers to `gitea-app_default` and uses the `runner` service as the cache host.
- For real HA, set a unique `GITEA_RUNNER_NAME` on each node even if the registration token stays the same.
- For runners on a separate host, change `GITEA_RUNNER_INSTANCE_URL` to the public Gitea URL.
- For same-host lab, if you do not have `gitea.precia.site` or an equivalent HTTPS domain pointing at this host, change `GITEA_DOMAIN` and `GITEA_ROOT_URL` in `.env` before relying on Actions or the container registry.

## Container Registry

- The Gitea package registry is explicitly enabled, which is the feature that serves OCI container images.
- The registry endpoint is the same Gitea domain under `/v2/`, so the registry name is just your normal Gitea domain.
- New repositories already keep `repo.packages` enabled by default, so users and orgs can publish images without extra repo-unit changes.
- In a proper HTTPS deployment behind your reverse proxy, the workflow is:
  - `docker login gitea.example.com`
  - `docker push gitea.example.com/<owner>/<image>:<tag>`
  - `docker pull gitea.example.com/<owner>/<image>:<tag>`
- In the checked-in config, the registry now expects the HTTPS domain `gitea.precia.site`.
- If you switch back to plain HTTP on `localhost:3001`, Docker will only talk to it if you mark that endpoint as an insecure registry in the Docker daemon on the client host.
- Container image blobs are stored in the same MinIO-backed storage as other package data, under the package storage base path.

## Notes

- The container exposes SSH on port `22` via the image's bundled `sshd`; `GITEA_SSH_PORT` is the externally advertised port.
- The checked-in `.env` is now tuned for `gitea.precia.site` behind a HTTPS reverse proxy. Change the domain, `ROOT_URL`, and all secrets before any different deployment.
- Change `GITEA_RUNNER_REGISTRATION_TOKEN` before any real deployment, and make `GITEA_RUNNER_NAME` unique per node.
- Change `GITEA_CONTAINER_REGISTRY_LIMIT_SIZE` if you want to cap image upload size instead of leaving it unlimited.
- For same-host lab, always include `docker-compose.lab.yml`. For real HA, do not use the lab override unless you intentionally attach the app node to that Docker network.
- If you want HA code search, add Elasticsearch/Meilisearch and re-enable the repository indexer with an external backend.
- The `gitea-shared` stack is convenient for a same-host lab, but it is not itself a true HA database/Redis/object-storage deployment.
