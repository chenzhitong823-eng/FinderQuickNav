#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
suite_temp="$(mktemp -d "${TMPDIR:-/tmp}/finderquicknav-tests.XXXXXX")"
trap 'rm -rf "${suite_temp}"' EXIT
export TMPDIR="${suite_temp}/"
log_directory="${FQN_TEST_LOG_DIR:-${suite_temp}/logs}"
mkdir -p "${log_directory}"

passed=0
failed=0
for test_script in "${script_dir}"/test-*.sh(N); do
    test_name="${test_script:t}"
    if zsh "${test_script}" > "${log_directory}/${test_name%.sh}.log" 2>&1; then
        print -r -- "PASS ${test_name}"
        (( passed += 1 ))
    else
        print -u2 -r -- "FAIL ${test_name}"
        cat "${log_directory}/${test_name%.sh}.log" >&2
        (( failed += 1 ))
    fi
done
print -r -- "Tests: ${passed} passed, ${failed} failed"
[[ "${passed}" -gt 0 && "${failed}" -eq 0 ]]
