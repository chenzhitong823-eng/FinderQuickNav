#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
test_dir="$(mktemp -d)"
trap 'rm -rf "${test_dir}"' EXIT
mkdir -p "${test_dir}/scripts" "${test_dir}/bin" "${test_dir}/Invalid.app" \
    "${test_dir}/Applications With Spaces/FinderQuickNav.app"
cp "${script_dir}/install-local.sh" "${script_dir}/verify-bundle-versions.sh" "${test_dir}/scripts/"
print 'existing installation' > "${test_dir}/Applications With Spaces/FinderQuickNav.app/keep.txt"

# Guard every mutating external command. Even an old installer with a
# hard-coded home directory cannot touch the real installation in this test.
for command_name in mkdir mv ditto pluginkit; do
    cat > "${test_dir}/bin/${command_name}" <<'GUARD'
#!/bin/zsh
print -r -- "${0:t} $*" >> "${FQN_MUTATION_LOG}"
exit 97
GUARD
done
cat > "${test_dir}/bin/pgrep" <<'GUARD'
#!/bin/zsh
exit 1
GUARD
cat > "${test_dir}/bin/codesign" <<'GUARD'
#!/bin/zsh
print -u2 'invalid signature in test fixture'
exit 1
GUARD
chmod +x "${test_dir}/bin/"*
export PATH="${test_dir}/bin:${PATH}"
export FQN_MUTATION_LOG="${test_dir}/mutations.log"
export FQN_INSTALL_DIR="${test_dir}/Applications With Spaces"

expect_safe_rejection() {
    local source_app="$1"
    local exit_code=0
    FQN_APP_PATH="${source_app}" zsh "${test_dir}/scripts/install-local.sh" \
        > "${test_dir}/result.log" 2>&1 || exit_code=$?
    if [[ "${exit_code}" -eq 0 || -s "${FQN_MUTATION_LOG}" ]]; then
        print -u2 'install preflight failed: invalid input reached an installation mutation'
        cat "${test_dir}/result.log" >&2
        [[ ! -f "${FQN_MUTATION_LOG}" ]] || cat "${FQN_MUTATION_LOG}" >&2
        exit 1
    fi
    [[ "$(cat "${FQN_INSTALL_DIR}/FinderQuickNav.app/keep.txt")" == 'existing installation' ]]
}

expect_safe_rejection "${test_dir}/Invalid.app"
expect_safe_rejection "${FQN_INSTALL_DIR}/FinderQuickNav.app"
print 'install preflight smoke test passed'
