#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
source_app="${FQN_APP_PATH:-${project_dir}/build-local/FinderQuickNav.app}"
installed_app="/Users/mac/Applications/FinderQuickNav.app"
extension_id="local.finderquicknav.app.extension"
extension_name="FinderQuickNavExtension.appex"
archive_dir="${project_dir}/system/archive"
archive_path="${archive_dir}/FinderQuickNav-user-before-local-install-$(date +%Y%m%d-%H%M%S).app"

[[ -d "${source_app}" ]]
mkdir -p "${archive_dir}"

old_host_pids=$(pgrep -f '/Users/mac/Applications/FinderQuickNav.app/Contents/MacOS/FinderQuickNav' || true)
if [[ -n "${old_host_pids}" ]]; then
    kill ${old_host_pids}
fi

if [[ -d "${installed_app}" ]]; then
    pluginkit -r "${installed_app}/Contents/PlugIns/${extension_name}" || true
    mv "${installed_app}" "${archive_path}"
fi

ditto "${source_app}" "${installed_app}"
installed_extension="${installed_app}/Contents/PlugIns/${extension_name}"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f -R -trusted "${installed_app}"
pluginkit -a "${installed_extension}"
pluginkit -e use -i "${extension_id}"
registered=0
for attempt in {1..20}; do
    if "${script_dir}/verify-extension-registration.sh" >/dev/null 2>&1; then
        registered=1
        break
    fi
    sleep 1
done
if [[ "${registered}" -ne 1 ]]; then
    "${script_dir}/verify-extension-registration.sh"
fi
codesign --verify --deep --strict --verbose=2 "${installed_app}"

printf 'installed app: %s\narchived previous app: %s\n' "${installed_app}" "${archive_path}"
