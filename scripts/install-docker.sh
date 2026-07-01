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

  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_run sudo docker info
  elif sudo docker info >/dev/null; then
    cw_log "Docker daemon reachable via sudo."
  else
    cw_die "Docker installed but daemon not reachable via sudo. Start Docker with: sudo systemctl enable --now docker"
  fi

  if cw_confirm_sensitive CARACODERS_CONFIRM_DOCKER_GROUP "Add current user to docker group? This gives high local privileges."; then
    cw_run sudo usermod -aG docker "$USER"
    if [[ "$CW_DRY_RUN" == "true" ]]; then
      cw_log "DRY-RUN: docker group membership would require logout/login, reboot, or 'newgrp docker' to apply."
    else
      cw_warn "User '$USER' added to docker group. Logout/login, reboot, or run 'newgrp docker' for membership to apply."
    fi
  fi

  smoke_image="${DOCKER_HELLO_WORLD_IMAGE:-hello-world@sha256:96498ffd522e70807ab6384a5c0485a79b9c7c08ca79ba08623edcad1054e62d}"
  [[ "$smoke_image" != *':latest'* ]] || cw_die "Docker smoke image must not use :latest: $smoke_image"
  [[ "$smoke_image" == *@sha256:* ]] || cw_die "Docker smoke image must be digest-pinned: $smoke_image"

  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_run sudo docker run --rm "$smoke_image"
  else
    display="$(cw_quote_cmd sudo docker run --rm "$smoke_image")"
    cw_log "RUN: $display"
    cw_record_action "RUN $display"
    if sudo docker run --rm "$smoke_image"; then
      cw_log "Docker smoke test passed: $smoke_image"
    else
      status=$?
      message="Docker smoke test failed for $smoke_image (exit=$status). This can be caused by registry/network/digest availability; Docker installation already completed."
      if [[ "$CW_STRICT" == "true" ]]; then
        cw_die "$message"
      fi
      cw_warn "$message Continuing because Docker smoke image validation is non-fatal by default. Re-run with --strict to make it fatal."
    fi
  fi
fi
