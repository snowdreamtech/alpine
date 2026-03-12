#!/usr/bin/env bats
# tests/docker.bats - Alpine Docker Image Integration Tests

setup() {
  # Guard: Skip if docker is not available
  if ! command -v docker >/dev/null 2>&1; then
    skip "docker command not found"
  fi

  if ! docker version >/dev/null 2>&1; then
    skip "docker daemon not running"
  fi

  # Variables for testing
  IMAGE_NAME="snowdreamtech/alpine"
  CONTAINER_NAME="alpine-test-$(date +%s)"
}

teardown() {
  # Cleanup container if exists
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}

@test "Verify image exists" {
  run docker images -q "${IMAGE_NAME}"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "Base: verify OS version" {
  run docker run --rm "${IMAGE_NAME}" cat /etc/alpine-release
  [ "$status" -eq 0 ]
  printf "%s" "$output" | grep -q "^3\.23\."
}

@test "User Mapping: verify PUID/PGID support" {
  run docker run --name "${CONTAINER_NAME}" -e PUID=1234 -e PGID=1234 -e USER=testuser "${IMAGE_NAME}" id -u testuser
  [ "$status" -eq 0 ]
  [ "$output" -eq 1234 ]
}

@test "Timezone: verify TZ support" {
  run docker run --rm -e TZ=Asia/Shanghai "${IMAGE_NAME}" date +%Z
  [ "$status" -eq 0 ]
  printf "%s" "$output" | grep -q "CST"
}

@test "Packages: verify essential tools are installed" {
  for tool in bash zsh nano rsync git curl wget jq; do
    run docker run --rm "${IMAGE_NAME}" which "$tool"
    [ "$status" -eq 0 ]
  done
}

@test "Privileges: verify non-root user has sudo access" {
  run docker run --rm -e PUID=1000 -e PGID=1000 -e USER=devuser "${IMAGE_NAME}" sudo -n id -u
  [ "$status" -eq 0 ]
  [ "$output" -eq 0 ]
}

@test "Non-root: verify container doesn't crash with -u option" {
  run docker run --rm -u 1000:1000 "${IMAGE_NAME}" whoami
  [ "$status" -eq 0 ]
}
