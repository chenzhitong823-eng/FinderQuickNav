#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
source_app="${FQN_APP_PATH:-${project_dir}/build-local/FinderQuickNav.app}"
install_directory="${FQN_INSTALL_DIR:-${HOME}/Applications}"
installed_app="${install_directory}/FinderQuickNav.app"
extension_id="local.finderquicknav.app.extension"
extension_name="FinderQuickNavExtension.appex"
archive_dir="${project_dir}/system/archive"
archive_path="${archive_dir}/FinderQuickNav-user-before-local-install-$(date +%Y%m%d-%H%M%S)-$$.app"

if [[ "${source_app:A}" == "${installed_app:A}" ]]; then
    print -u2 'Source app and installed app must be different paths.'
    exit 1
fi
source_extension="${source_app}/Contents/PlugIns/${extension_name}"
if [[ ! -x "${source_app}/Contents/MacOS/FinderQuickNav" || \
      ! -x "${source_extension}/Contents/MacOS/FinderQuickNavExtension" ]]; then
    print -u2 -r -- "App or Finder extension executable is missing: ${source_app}"
    exit 1
fi
[[ "$(plutil -extract CFBundleIdentifier raw -o - "${source_app}/Contents/Info.plist")" == 'local.finderquicknav.app' ]]
[[ "$(plutil -extract CFBundleIdentifier raw -o - "${source_extension}/Contents/Info.plist")" == "${extension_id}" ]]
codesign --verify --deep --strict --verbose=2 "${source_app}"
zsh "${script_dir}/verify-bundle-versions.sh" "${source_app}"

# Prepare and verify the copy before stopping or moving the working app.
mkdir -p "${install_directory}" "${archive_dir}"
staging_directory="$(mktemp -d "${install_directory}/.finderquicknav-install.XXXXXX")"
trap 'rm -rf "${staging_directory}"' EXIT
ditto "${source_app}" "${staging_directory}/FinderQuickNav.app"
codesign --verify --deep --strict "${staging_directory}/FinderQuickNav.app"

# Match the executable path literally; spaces and regex characters in the
# user's home directory must not select unrelated processes.
old_app_pids="$(ps -axo pid=,comm= | awk \
    -v expected_host="${installed_app:A}/Contents/MacOS/FinderQuickNav" \
    -v expected_extension="${installed_app:A}/Contents/PlugIns/${extension_name}/Contents/MacOS/FinderQuickNavExtension" '
    { pid=$1; sub(/^[[:space:]]*[0-9]+[[:space:]]+/, ""); if ($0 == expected_host || $0 == expected_extension) print pid }
')"
if [[ -n "${old_app_pids}" ]]; then
    kill ${(f)old_app_pids}
fi

if [[ -d "${installed_app}" ]]; then
    pluginkit -r "${installed_app}/Contents/PlugIns/${extension_name}" || true
    mv "${installed_app}" "${archive_path}"
fi

mv "${staging_directory}/FinderQuickNav.app" "${installed_app}"
installed_extension="${installed_app}/Contents/PlugIns/${extension_name}"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f -R -trusted "${installed_app}"
pluginkit -a "${installed_extension}"
pluginkit -e use -i "${extension_id}"
registered=0
for attempt in {1..20}; do
    if zsh "${script_dir}/verify-extension-registration.sh" "${extension_id}" "${installed_extension}" >/dev/null 2>&1; then
        registered=1
        break
    fi
    sleep 1
done
if [[ "${registered}" -ne 1 ]]; then
    zsh "${script_dir}/verify-extension-registration.sh" "${extension_id}" "${installed_extension}"
fi
codesign --verify --deep --strict --verbose=2 "${installed_app}"

printf 'installed app: %s\n' "${installed_app}"
if [[ -d "${archive_path}" ]]; then
    printf 'archived previous app: %s\n' "${archive_path}"
fi
