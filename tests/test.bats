#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=helga-agentur/ddev-structurizr

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  export CI=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --docroot=web --project-type=php
  assert_success
  run ddev start -y
  assert_success

  # Workspace in a module; exports go to the central folder (default root layout).
  export SOURCE_DIR="web/modules/custom/my_module/architecture/diagrams"
  export EXPORT_DIR="architecture/my_module"
  mkdir -p "${SOURCE_DIR}"
  cp "${DIR}/tests/testdata/workspace.dsl" "${SOURCE_DIR}/workspace.dsl"
}

health_checks() {
  run ddev c4 --list
  assert_success
  assert_output "my_module"

  run ddev c4-export
  assert_success
  assert_output --partial "my_module -> ${EXPORT_DIR}/"
  assert_file_exist "${EXPORT_DIR}/README.md"
  assert_file_exist "${EXPORT_DIR}/SystemContext.svg"
  assert_file_exist "${EXPORT_DIR}/SystemContext.md"
  assert_file_exist "${EXPORT_DIR}/Containers.svg"
  assert_file_not_exist "architecture/.tmp-export-my_module"
  run grep -c '```mermaid' "${EXPORT_DIR}/SystemContext.md"
  assert_output "1"
  run grep -F '![SystemContext](SystemContext.svg)' "${EXPORT_DIR}/README.md"
  assert_success

  run ddev c4-export missing_module
  assert_failure
  assert_output --partial "No workspace for module 'missing_module'"

  # Editing mode: the only workspace is picked automatically.
  run ddev c4
  assert_success
  assert_output --partial "my_module: http://localhost:"
  url="$(echo "${output}" | grep -o 'http://localhost:[0-9]*' | head -1)"
  run curl -fsS -o /dev/null "${url}"
  assert_success

  run ddev c4 --stop-all
  assert_success
  run docker ps -q --filter "name=^structurizr_${PROJNAME}_"
  assert_output ""

  # The containers carry DDEV labels, so stopping the project stops them as well.
  run ddev c4 my_module
  assert_success
  run ddev stop
  assert_success
  run docker ps -q --filter "name=^structurizr_${PROJNAME}_"
  assert_output ""
}

teardown() {
  set -eu -o pipefail
  ddev c4 --stop-all >/dev/null 2>&1 || true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  health_checks
}
