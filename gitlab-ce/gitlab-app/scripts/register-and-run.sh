#!/bin/sh
set -e

CONFIG=/etc/gitlab-runner/config.toml

if [ ! -f "$CONFIG" ] || ! grep -q "url = \"${CI_SERVER_URL}\"" "$CONFIG" 2>/dev/null; then
  echo "Registering runner ${RUNNER_NAME} against ${CI_SERVER_URL} ..."
  gitlab-runner register \
    --non-interactive \
    --url "${CI_SERVER_URL}" \
    --registration-token "${REGISTRATION_TOKEN}" \
    --executor "${RUNNER_EXECUTOR:-docker}" \
    --docker-image "${DOCKER_IMAGE:-alpine:latest}" \
    --description "${RUNNER_NAME}" \
    --tag-list "${RUNNER_TAG_LIST}" \
    --docker-network-mode "gitlab-shared" \
    --docker-privileged=false
else
  echo "Runner already registered, skipping registration."
fi

exec gitlab-runner run --working-directory /etc/gitlab-runner
