# Outline Wiki + Keycloak SSO

Self-hosted [Outline](https://www.getoutline.com/) knowledge base with [Keycloak](https://www.keycloak.org/) as OIDC identity provider.

## Services

| Container | Port | Description |
|-----------|------|-------------|
| `outline` | `3000` | Wiki app |
| `outline-postgres` | — | Outline database |
| `outline-redis` | — | Outline cache / queues |
| `keycloak` | `8080` | SSO (admin UI at `/admin`) |
| `keycloak-postgres` | — | Keycloak database |

## Setup

### 1. Configure environment

```bash
cp .env.example .env
```

Edit `.env`:
- Generate `SECRET_KEY` and `UTILS_SECRET` with `openssl rand -hex 32`
- Set `URL` to the public address of Outline (e.g. `http://192.168.1.100:3000`)
- Set passwords for both Postgres instances and Keycloak admin
- Fill in `OIDC_*` vars after completing Keycloak setup below

### 2. Start Keycloak first

```bash
docker compose up -d keycloak keycloak-postgres
```

### 3. Configure Keycloak

1. Open `http://<HOST>:8080/admin` → log in with `KC_ADMIN` / `KC_ADMIN_PASSWORD`
2. Create a new realm (e.g. `magnolia`)
3. Inside the realm → **Clients** → **Create client**
   - Client ID: `outline`
   - Client authentication: ON
   - Valid redirect URIs: `http://<HOST>:3000/auth/oidc.callback`
4. Copy the **client secret** from the **Credentials** tab
5. Create at least one user in the realm
6. Fill in `OIDC_*` values in `.env`:
   ```
   OIDC_CLIENT_SECRET=<secret from step 4>
   OIDC_AUTH_URI=http://<HOST>:8080/realms/<REALM>/protocol/openid-connect/auth
   OIDC_TOKEN_URI=http://<HOST>:8080/realms/<REALM>/protocol/openid-connect/token
   OIDC_USERINFO_URI=http://<HOST>:8080/realms/<REALM>/protocol/openid-connect/userinfo
   OIDC_LOGOUT_URI=http://<HOST>:8080/realms/<REALM>/protocol/openid-connect/logout
   ```

### 4. Run database migration

```bash
docker compose run --rm --entrypoint='' -e NODE_ENV=test outline \
  node_modules/.bin/sequelize db:migrate --env=test
```

### 5. Start everything

```bash
docker compose up -d
```

## Notes

- `passport.js.patched` disables the secure-cookie requirement so Outline works over plain HTTP.
  Remove the volume mount in `docker-compose.yml` if you run behind an HTTPS reverse proxy.
- Keycloak `start-dev` mode is used for simplicity; use `start` with proper TLS for production.
