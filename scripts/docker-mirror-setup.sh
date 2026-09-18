#!/usr/bin/env bash
#
# docker-mirror-setup.sh - Make plain `docker pull nginx:latest` resolve through
# the EdgeMirror token-gated proxy on this host.
#
# This script only supports the containerd image store (Docker >= 25 with the
# "containerd-snapshotter" feature enabled). The classic image store is
# intentionally not supported because Docker does not attach registry
# credentials to `registry-mirrors` pulls (https://github.com/moby/moby/issues/30880),
# so a token-gated mirror would answer 401 and Docker would silently fall back
# to Docker Hub. If the host does not run the containerd image store, the script
# prints the requirement and exits.
#
# With the containerd image store, registry config lives in
# /etc/containerd/certs.d/<host>/hosts.toml, which supports username/password
# credentials natively (https://github.com/containerd/containerd/pull/10612).
# The script writes /etc/containerd/certs.d/docker.io/hosts.toml so every image
# pull from Docker Hub on this host goes through the mirror with the token.
#
# Usage (run as root on the Docker host):
#   Running the script without arguments applies the mirror configuration and
#   asks for the domain and access token on the terminal when they are not set
#   as environment variables:
#
#   sudo scripts/docker-mirror-setup.sh            # same as "apply"
#   sudo AUTH_TOKEN=... MIRROR_HOST=... scripts/docker-mirror-setup.sh   # skip prompts
#
# Optional subcommands:
#   sudo scripts/docker-mirror-setup.sh update     # re-apply, e.g. after rotating the token
#   sudo scripts/docker-mirror-setup.sh status     # inspect current configuration
#   sudo scripts/docker-mirror-setup.sh rollback   # restore the default Docker Hub setup
#   sudo scripts/docker-mirror-setup.sh remove     # alias of "rollback"
#
# Environment (optional; when missing the script asks on the terminal so the
# token never ends up in shell history):
#   MIRROR_HOST   the proxy domain
#   AUTH_TOKEN    the access token configured as AUTH_TOKEN on the proxy
#
set -euo pipefail

# ---------------------------------------------------------------- config ----
# Default command is "apply" when the script is run without arguments.
COMMAND="${1:-apply}"
MIRROR_HOST="${MIRROR_HOST:-}"
AUTH_TOKEN="${AUTH_TOKEN:-}"
DOCKER_MIN_VERSION="25.0.0"
DAEMON_JSON="/etc/docker/daemon.json"
CERTS_DIR="/etc/containerd/certs.d/docker.io"
CERTS_TOML="${CERTS_DIR}/hosts.toml"

# --------------------------------------------------------------- helpers ----
log()  { printf '[docker-mirror] %s\n' "$*"; }
die()  { log "ERROR: $*" >&2; exit 1; }

require_root() {
  [ "$(id -u)" -eq 0 ] || die "run as root (sudo)"
}

require_docker() {
  command -v docker >/dev/null 2>&1 || die "docker CLI not found"
  docker info >/dev/null 2>&1 || die "docker daemon is not running or not usable"
}

resolve_credentials() {
  # Environment variables are optional prefills; when they are not provided the
  # script asks on the terminal so the token never sits in shell history.
  if [ -z "$MIRROR_HOST" ] || [ "$MIRROR_HOST" = "YOUR_DOMAIN" ]; then
    read -r -p "Mirror proxy domain (e.g. mirror.example.com): " MIRROR_HOST || die "input aborted"
    [ -n "$MIRROR_HOST" ] && [ "$MIRROR_HOST" != "YOUR_DOMAIN" ] || die "MIRROR_HOST must be the real proxy domain"
  fi
  if [ -z "$AUTH_TOKEN" ]; then
    read -r -s -p "Access token (AUTH_TOKEN value): " AUTH_TOKEN || die "input aborted"
    printf '\n'
  fi
  [ -n "$AUTH_TOKEN" ] || die "AUTH_TOKEN is required"
}

# Compare dotted version numbers, returns 0 when $1 >= $2.
version_gte() {
  local cur min
  cur="${1%%-*}"   # strip any pre-release suffix such as -rc.1 / -beta.1
  cur="${cur//[^0-9.]/}"
  min="${2%%-*}"
  min="${min//[^0-9.]/}"
  local ci mi
  read -ra ci <<< "${cur//./ }"
  read -ra mi <<< "${min//./ }"
  for i in 0 1 2; do
    [ "${ci[$i]:-0}" -gt "${mi[$i]:-0}" ] && return 0
    [ "${ci[$i]:-0}" -lt "${mi[$i]:-0}" ] && return 1
  done
  return 0
}

docker_server_version() {
  docker version --format '{{.Server.Version}}' 2>/dev/null || true
}

# True when the daemon actually runs on the containerd image store.
uses_containerd_image_store() {
  local driver feature
  driver="$(docker info --format '{{.Driver}}' 2>/dev/null || true)"
  feature=""
  if [ -f "$DAEMON_JSON" ]; then
    feature="$(grep -o '"containerd-snapshotter"[[:space:]]*:[[:space:]]*true' "$DAEMON_JSON" 2>/dev/null | head -n1 || true)"
  fi
  [ "$driver" = "overlayfs" ] || [ -n "$feature" ]
}

# Gate: require the containerd image store, otherwise explain and exit.
require_containerd_image_store() {
  local server_version
  server_version="$(docker_server_version)"

  if [ -n "$server_version" ] && ! version_gte "$server_version" "$DOCKER_MIN_VERSION"; then
    die "Docker ${server_version} is too old: the containerd image store needs Docker >= ${DOCKER_MIN_VERSION}. Upgrade docker-ce, then re-run."
  fi

  if ! uses_containerd_image_store; then
    die "this host does not use the containerd image store, which this script requires

The classic image store cannot authenticate to a token-gated mirror:
Docker does not attach registry credentials to registry-mirrors pulls
(https://github.com/moby/moby/issues/30880), so the proxy would answer 401
and pulls would silently fall back to Docker Hub.

To enable the containerd image store on Docker >= ${DOCKER_MIN_VERSION}, add:

    \"features\": { \"containerd-snapshotter\": true }

to /etc/docker/daemon.json, restart the daemon, then re-run this script.
Note: switching image stores does not carry previously pulled images over."
  fi
}

restart_docker() {
  log "restarting Docker daemon"
  systemctl restart docker 2>/dev/null || service docker restart 2>/dev/null || \
    die "could not restart Docker; please restart it manually"

  # If containerd runs as its own unit, reload it so certs.d changes apply.
  if systemctl list-unit-files containerd.service >/dev/null 2>&1; then
    systemctl restart containerd 2>/dev/null || true
  fi

  # Wait until the daemon accepts requests again.
  for _ in $(seq 1 30); do
    docker info >/dev/null 2>&1 && return 0
    sleep 1
  done
  die "Docker did not come back up after restart"
}

# -------------------------------------------------- containerd certs.d ---------
apply_containerd_certs() {
  log "writing ${CERTS_TOML}"
  mkdir -p "$CERTS_DIR"
  cat > "$CERTS_TOML" <<EOF
server = "https://registry-1.docker.io"

[host."https://${MIRROR_HOST}"]
  capabilities = ["pull", "resolve"]
  username = "proxy"
  password = "${AUTH_TOKEN}"
EOF
  restart_docker
}

# ------------------------------------------------------------ commands ----
cmd_apply() {
  require_root
  require_docker
  require_containerd_image_store
  resolve_credentials
  apply_containerd_certs
  cmd_verify
}

# Re-apply the configuration (e.g. after rotating the access token).
cmd_update() {
  require_root
  require_docker
  require_containerd_image_store
  resolve_credentials
  apply_containerd_certs
  cmd_verify
}

cmd_remove() {
  require_root
  require_docker
  require_containerd_image_store
  rm -f "$CERTS_TOML"
  restart_docker
  log "removed ${CERTS_TOML}; docker.io pulls now go directly to Docker Hub"
}

cmd_status() {
  require_root
  require_docker
  log "storage driver: $(docker info --format '{{.Driver}}' 2>/dev/null || echo unknown)"
  log "server version: $(docker_server_version)"
  if uses_containerd_image_store; then
    if [ -f "$CERTS_TOML" ]; then
      log "containerd mirror config: ${CERTS_TOML} (present)"
    else
      log "containerd mirror config: ${CERTS_TOML} (missing)"
    fi
  else
    log "containerd image store: not used (see 'apply' command requirements)"
  fi
}

cmd_verify() {
  # The script does not pull images itself; hand back manual verification steps
  # so the operator can confirm the mirror was actually used.
  log "configuration applied. Verify manually on this host:"
  log "    docker pull nginx:latest"
  log "and confirm the pull resolves through ${MIRROR_HOST} (e.g. check the proxy access"
  log "log for the pull, or run the pull twice and watch the second one being cached)."
  log "quay.io / ghcr.io / gcr.io images still need the full name: docker pull ${MIRROR_HOST}/quay/coreos/etcd:latest"
}

case "$COMMAND" in
  apply)    cmd_apply  ;;
  update)   cmd_update ;;
  rollback) cmd_remove ;;
  remove)   cmd_remove ;;
  status)   cmd_status ;;
  *) die "unknown command: ${COMMAND} (use apply | update | rollback | status)" ;;
esac