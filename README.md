# docker-compose-collection

Docker Compose configs.
All configs are copied from running services — not templates, not guesswork.

## Services

| Directory | Service | Port(s) | Node |
|-----------|---------|---------|------|
| [`actual-budget/`](actual-budget/) | Actual Budget — personal finance | `5006` (HTTPS self-signed) | mikasa |
| [`bentopdf/`](bentopdf/) | BentoPDF — PDF tools | `3000` | lena |
| [`dozzle/`](dozzle/) | Dozzle — Docker log viewer | `9999` | lena / mikasa / monitoring |
| [`flame/`](flame/) | Flame — startpage / bookmark dashboard | `5005` | lena |
| [`gitea/`](gitea/) | Gitea EE — git hosting + Actions CI (app + shared: DB/Redis/MinIO/pgBackRest + 5 runners) | `3002` / `222` | mlcv-ws1 |
| [`gitlab-ce/`](gitlab-ce/) | GitLab CE — git hosting + CI (app + shared: DB/Redis/MinIO + runner + backup) | `18300` / `2224` | mlcv-ws1 |
| [`harbor/`](harbor/) | Harbor CE — container image registry (installer-based, not static compose) | `8080` | mlcv-ws1 |
| [`homarr/`](homarr/) | Homarr — home server dashboard | `7575` | lena / hinata |
| [`homelab-dashboard/`](homelab-dashboard/) | Custom static homelab dashboard (nginx) | `80` | hinata |
| [`homepage/`](homepage/) | Homepage — homelab dashboard | `3003` | lena |
| [`immich/`](immich/) | Immich — photo & video management (OpenVINO) | `8080` | yor |
| [`keycloak/`](keycloak/) | Keycloak — SSO identity provider | `8080` | mikasa |
| [`komodo/`](komodo/) | Komodo — server management platform | `9120` | monitoring |
| [`minecraft-server/`](minecraft-server/) | Minecraft modded server (itzg/minecraft-server) | `25565` | lena |
| [`monitoring/`](monitoring/) | Prometheus + Grafana stack | `9090` / `3000` | monitoring |
| [`monitoring-agent/`](monitoring-agent/) | cAdvisor + node-exporter (deploy on every host) | `18080` / `9100` | all nodes |
| [`observium/`](observium/) | Observium — network monitoring (SNMP) | `8086` | lena |
| [`outline/`](outline/) | Outline — wiki / knowledge base + Keycloak OIDC | `3000` | mikasa |
| [`overleaf/`](overleaf/) | Overleaf CE — collaborative LaTeX editor | `80` | lena |
| [`portainer/`](portainer/) | Portainer CE — Docker management UI | `8000` / `9443` | monitoring |
| [`stirling-pdf/`](stirling-pdf/) | Stirling PDF — PDF tools | `8080` | lena |
| [`taiga/`](taiga/) | Taiga — project management | `9000` | kaguya |
| [`tailscale/`](tailscale/) | Tailscale — VPN gateway (subnet router) | — | hinata |
| [`uptime-kuma/`](uptime-kuma/) | Uptime Kuma — service uptime monitoring | `3001` | monitoring |
| [`vs-code-server/`](vs-code-server/) | OpenVSCode Server — VS Code in browser | `3000` | — |

## Usage

Each directory is self-contained. General steps:

```bash
cd <service>/
cp .env.example .env    # if .env.example exists
# edit .env as needed
docker compose up -d
```

Services without `.env.example` have all config inline in `docker-compose.yml`.

## Notes

- **`monitoring-agent/`** — deploy on every Docker host to expose metrics to Prometheus.
- **`outline/`** — requires patched `passport.js` for HTTP-only deployment (included). See [`outline/README.md`](outline/README.md) for full setup.
- **`overleaf/`** — uses custom `Dockerfile` (full TeX Live). Build takes 20–40 min on first run.
- **`taiga/`** — includes nginx gateway config at `taiga-gateway/taiga.conf`.
- **`immich/`** — uses `openvino` image variant for Intel iGPU hardware acceleration.
- **`keycloak/`** — runs `start-dev` mode (no TLS). Suitable for LAN-only deployment.
- **`gitea/`** — split stack: `gitea-app/` (Gitea + N runners, scale with `docker-compose.extra-runners.yml`) talks to `gitea-shared/` (Postgres w/ pgBackRest, Redis, MinIO) over an external network. See both directories' READMEs.
- **`gitlab-ce/`** — same split-stack idea as `gitea/`: `gitlab-app/` (omnibus GitLab + 1 runner + backup sidecar) talks to `gitlab-shared/` (Postgres, Redis, MinIO) over the external `gitlab-shared` network. Deployed to coexist with Gitea, not replace it. See `gitlab-app/README.md` for the runner-token and backup setup steps.
- **`harbor/`** — ships the installer (`install.sh` + `harbor.yml`) instead of a static compose file, since Harbor generates its own `docker-compose.yml` from `harbor.yml` at install time.
