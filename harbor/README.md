# Harbor CE — container image registry

Unlike the other entries in this collection, Harbor isn't run from a static
`docker-compose.yml` — its official installer (`install.sh`) *generates* the
compose file from `harbor.yml` at install time. Committing the generated
file would just go stale every time `harbor.yml` changes, so this directory
ships the installer + config instead, same as upstream Harbor releases.

`harbor.yml` here is the actual config in use, with the two secrets
(`harbor_admin_password`, `database.password`) replaced with placeholders.
`harbor.yml.tmpl` is the untouched upstream template (all options
documented, useful as a reference).

## Setup

```bash
# edit harbor.yml: set real passwords, hostname, data_volume path, etc.
./install.sh
```

`install.sh` calls `./prepare` (renders `docker-compose.yml` from
`harbor.yml`) then `docker compose up -d`. Re-run it any time you change
`harbor.yml` to regenerate and redeploy.

## Notes

- `hostname` / `external_url` in `harbor.yml` should match whatever domain
  a reverse proxy (NPM, Traefik, etc) will front this with — Harbor itself
  listens on plain HTTP (`http.port`) and expects TLS to be terminated
  upstream if `external_url` is `https://`.
- `data_volume` is where all registry blobs, DB data, and job logs live —
  point it at a disk with enough room for your image layers.
- Trivy vulnerability scanning is on by default (`trivy.security_check: vuln`).
