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
# With the containerd image store, registry config is read from a hosts.toml
# under the Docker certs directory (/etc/docker/certs.d/<host>/hosts.toml, the
# path moby's registry.CertsDir() resolves) and mirrored under
# /etc/containerd/certs.d/<host>/hosts.toml for ctr/CRI consumers. The script
# writes both so every docker.io pull on this host goes through the mirror with
# the token.
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
# dockerd (containerd image store) resolves hosts.toml from its own certs dir
# (moby `registry.CertsDir()`, default /etc/docker/certs.d) and does NOT read the
# containerd path, so this is the file that actually takes effect for pulls.
# The containerd CRI path is written as well for `ctr`/CRI consumers and for
# future Docker versions that may read both.
DOCKER_CERTS_ROOT="/etc/docker/certs.d"
CONTAINERD_CERTS_ROOT="/etc/containerd/certs.d"
# Namespaces probed for Docker Hub references across Docker and containerd versions.
CERT_HOST_DIRS="docker.io registry-1.docker.io"

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
# All hosts.toml locations this script manages (both certs roots x Hub namespaces).
certs_files() {
  local root host
  for root in "$DOCKER_CERTS_ROOT" "$CONTAINERD_CERTS_ROOT"; do
    for host in $CERT_HOST_DIRS; do
      printf '%s/%s/hosts.toml\n' "$root" "$host"
    done
  done
}

write_certs_files() {
  local file basic_auth
  # containerd hosts.toml has no username/password host keys (they are silently
  # ignored, see containerd issue #8186), so the mirror token is sent as a static
  # Authorization header via the documented `header` table.
  #
  # `server` points at the mirror as well: containerd uses the default server for
  # lookups that are not covered by mirror capabilities (for example the OCI
  # referrers API on containerd <= 2.1), and a registry-1.docker.io fallback would
  # bypass the mirror and break on censored networks.
  #
  # `capabilities` is intentionally omitted: the built-in default is
  # pull|resolve|push (plus referrers on containerd >= 2.2), while listing
  # "referrers" explicitly is a hard "unknown capability" error on <= 2.1.
  basic_auth="$(printf '%s' "proxy:${AUTH_TOKEN}" | base64 | tr -d '\n')"
  while IFS= read -r file; do
    mkdir -p "$(dirname "$file")"
    cat > "$file" <<EOF
server = "https://${MIRROR_HOST}"

[header]
  authorization = "Basic ${basic_auth}"

[host."https://${MIRROR_HOST}"]
  [host."https://${MIRROR_HOST}".header]
    authorization = "Basic ${basic_auth}"
EOF
    log "wrote ${file}"
  done < <(certs_files)
}

apply_containerd_certs() {
  write_certs_files
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
  local file dir
  while IFS= read -r file; do
    if [ -f "$file" ]; then
      rm -f "$file"
      log "removed ${file}"
    fi
  done < <(certs_files)
  # Drop directories that this script created and that are now empty.
  for dir in "$DOCKER_CERTS_ROOT" "$CONTAINERD_CERTS_ROOT"; do
    rmdir "${dir}/docker.io" "${dir}/registry-1.docker.io" "${dir}" 2>/dev/null || true
  done
  restart_docker
  log "docker.io pulls now go directly to Docker Hub again"
}

cmd_status() {
  require_root
  require_docker
  log "storage driver: $(docker info --format '{{.Driver}}' 2>/dev/null || echo unknown)"
  log "server version: $(docker_server_version)"
  if uses_containerd_image_store; then
    local file
    while IFS= read -r file; do
      if [ -f "$file" ]; then
        log "mirror config: ${file} (present)"
      else
        log "mirror config: ${file} (missing)"
      fi
    done < <(certs_files)
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

  # Show what is actually in effect for the pull path: the storage driver and
  # the file dockerd itself reads (its own certs dir, not the containerd one).
  local primary="${DOCKER_CERTS_ROOT}/docker.io/hosts.toml"
  log "storage driver: $(docker info --format '{{.Driver}}' 2>/dev/null || echo unknown)"
    if [ -f "$primary" ]; then
        log "registry config read by dockerd: ${primary}"
        grep -E '^(server|\[host\.)' "$primary" | sed 's/^/    /' || true
        log "note: the mirror serves as the default server too, so referrers and other"
        log "lookups cannot fall back to a direct registry-1.docker.io connection."
        log "note: credentials are sent as a static Authorization header in that file"
        log "(containerd hosts.toml has no username/password keys; see containerd issue #8186)."
        log "note: the same file is mirrored under ${CONTAINERD_CERTS_ROOT} for ctr/CRI consumers."
        log "note: registry-mirrors left in ${DAEMON_JSON} are not used by the containerd"
        log "image store; remove them there if they are no longer wanted."
    fi
    check_mirror_ipv6
    log "quay.io / ghcr.io / gcr.io images still need the full name: docker pull ${MIRROR_HOST}/quay/coreos/etcd:latest"
}

# The mirror is usually fronted by a CDN that publishes AAAA records. Hosts with
# IPv6 configured but no working IPv6 route fail pulls with
# "network is unreachable" because containerd dials the AAAA address first.
check_mirror_ipv6() {
    command -v curl >/dev/null 2>&1 || return 0
    command -v getent >/dev/null 2>&1 || return 0
    # Only warn when the name really has AAAA records, so IPv4-only hosts stay quiet.
    if ! getent ahostsv6 "$MIRROR_HOST" >/dev/null 2>&1; then
        return 0
    fi
    if curl -6 -fsS -o /dev/null --max-time 8 "https://${MIRROR_HOST}/health" 2>/dev/null; then
        return 0
    fi
    log "warning: ${MIRROR_HOST} has IPv6 (AAAA) records but this host cannot reach them."
    log "  containerd may dial the AAAA address first and fail with \"network is unreachable\"."
    log "  Fix one of:"
    log "    - disable IPv6 on this host: sysctl -w net.ipv6.conf.all.disable_ipv6=1"
    log "      (persist it in /etc/sysctl.d/99-disable-ipv6.conf, then restart docker)"
    log "    - pin the IPv4 address of ${MIRROR_HOST} in /etc/hosts"
    log "    - disable IPv6 for the domain in the CDN/DNS zone settings"
}

case "$COMMAND" in
  apply)    cmd_apply  ;;
  update)   cmd_update ;;
  rollback) cmd_remove ;;
  remove)   cmd_remove ;;
  status)   cmd_status ;;
  *) die "unknown command: ${COMMAND} (use apply | update | rollback | status)" ;;
esac