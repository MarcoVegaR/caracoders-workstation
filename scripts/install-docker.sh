#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

if cw_command_exists docker; then
  cw_log "Docker command already exists: $(command -v docker)"
else
  if cw_confirm_sensitive CARACODERS_ALLOW_DOCKER_APT_REPO "Add Docker official APT repository and install Docker Engine?"; then
    VERSION_CODENAME=""
    cw_load_key_value_file /etc/os-release "os-release"
    codename="${VERSION_CODENAME:-}"
    [[ -n "$codename" ]] || cw_die "Cannot determine Ubuntu codename for Docker repository."
    arch="$(dpkg --print-architecture)"
    repo_line="deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename ${DOCKER_CHANNEL:-stable}"

    docker_key_url="${DOCKER_APT_KEY_URL:-https://download.docker.com/linux/ubuntu/gpg}"
    docker_key_fingerprint="${DOCKER_APT_KEY_FINGERPRINT:-9DC858229FC7DD38854AE2D88D81803C0EBFCD88}"
    key_tmp="/tmp/caracoders-docker-apt-key-${CW_STARTED_AT}.asc"

    cw_run sudo apt-get update
    cw_run sudo apt-get install -y ca-certificates curl gnupg
    cw_download_file "$docker_key_url" "$key_tmp"
    if [[ "$CW_DRY_RUN" == "false" ]]; then
      actual_fingerprint="$(gpg --show-keys --with-colons "$key_tmp" | awk -F: '$1 == "fpr" {print $10; exit}')"
      [[ -n "$actual_fingerprint" ]] || cw_die "Could not read Docker APT key fingerprint from $key_tmp"
      [[ "$actual_fingerprint" == "$docker_key_fingerprint" ]] || cw_die "Docker APT key fingerprint mismatch. expected=$docker_key_fingerprint actual=$actual_fingerprint"
    else
      cw_log "DRY-RUN: verify Docker APT key fingerprint: $docker_key_fingerprint"
    fi
    cw_run sudo install -m 0755 -d /etc/apt/keyrings
    cw_run sudo install -m 0644 "$key_tmp" /etc/apt/keyrings/docker.asc
    cw_run sudo chmod a+r /etc/apt/keyrings/docker.asc
    cw_run rm -f "$key_tmp"
    cw_sudo_write_file /etc/apt/sources.list.d/docker.list "$repo_line"
    cw_run sudo apt-get update
    cw_run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    cw_warn "Docker installation skipped."
  fi
fi

if cw_command_exists docker; then
  cw_run docker --version
  cw_run docker compose version
  smoke_image="${DOCKER_HELLO_WORLD_IMAGE:-hello-world@sha256:d2c94e258dcb3c5ac2798d32e1249e42ef01c38b196fe8fb44a7eaceabaabcf8}"
  [[ "$smoke_image" != *':latest'* ]] || cw_die "Docker smoke image must not use :latest: $smoke_image"
  [[ "$smoke_image" == *@sha256:* ]] || cw_die "Docker smoke image must be digest-pinned: $smoke_image"
  cw_run sudo docker run --rm "$smoke_image"
  if cw_confirm_sensitive CARACODERS_CONFIRM_DOCKER_GROUP "Add current user to docker group? This gives high local privileges."; then
    cw_run sudo usermod -aG docker "$USER"
    cw_warn "Logout/login is required for docker group membership to apply."
  fi
fi
