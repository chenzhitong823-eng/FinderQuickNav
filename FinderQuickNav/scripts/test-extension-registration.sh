#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
test_dir="$(mktemp -d)"
trap 'rm -rf "${test_dir}"' EXIT
mkdir -p "${test_dir}/bin"
cat > "${test_dir}/bin/pluginkit" <<'STUB'
#!/bin/zsh
cat "${FQN_REGISTRATION_FIXTURE}"
STUB
chmod +x "${test_dir}/bin/pluginkit"
export PATH="${test_dir}/bin:${PATH}"
export FQN_REGISTRATION_FIXTURE="${test_dir}/registration.txt"
extension_id="local.finderquicknav.app.extension"
expected_path="${test_dir}/Applications With Spaces/FinderQuickNav.app/Contents/PlugIns/FinderQuickNavExtension.appex"

check_registration() {
    local expected_status="$1"
    local label="$2"
    local actual_status=0
    zsh "${script_dir}/verify-extension-registration.sh" "${extension_id}" "${expected_path}" \
        > "${test_dir}/result.log" 2>&1 || actual_status=$?
    if [[ "${expected_status}" == pass && "${actual_status}" -ne 0 ]] || \
       [[ "${expected_status}" == fail && "${actual_status}" -eq 0 ]]; then
        print -u2 -- "registration test failed: ${label} (exit=${actual_status})"
        cat "${test_dir}/result.log" >&2
        exit 1
    fi
}

printf '+    %s(0.1.1)\tUUID\t2026-09-28 00:00:00 +0000\t%s\n (1 plug-in)\n' \
    "${extension_id}" "${expected_path}" > "${FQN_REGISTRATION_FIXTURE}"
check_registration pass 'enabled extension at the intended path with spaces'

printf -- '-    %s(0.1.1)\tUUID\t%s\n' "${extension_id}" "${expected_path}" > "${FQN_REGISTRATION_FIXTURE}"
check_registration fail 'a disabled extension is not ready'

printf '+    %s(0.1.1)\tUUID\t/tmp/Archive.app/Contents/PlugIns/FinderQuickNavExtension.appex\n' \
    "${extension_id}" > "${FQN_REGISTRATION_FIXTURE}"
check_registration fail 'a single registration at an old path is not ready'

printf '+    %s(0.1.1)\tUUID\t%s\n+    %s(0.1.0)\tUUID\t/tmp/Old.appex\n' \
    "${extension_id}" "${expected_path}" "${extension_id}" > "${FQN_REGISTRATION_FIXTURE}"
check_registration fail 'duplicate registrations are rejected'

printf '(no matches)\n' > "${FQN_REGISTRATION_FIXTURE}"
check_registration fail 'missing extension is rejected'
print 'extension registration smoke test passed'
