#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
configuration="${FQN_CONFIGURATION:-Debug}"
signing_identity="${FQN_SIGNING_IDENTITY:-FinderQuickNav Local Signing}"
derived_data="$(mktemp -d "${TMPDIR:-/tmp}/finderquicknav-derived.XXXXXX")"
trap 'rm -rf "${derived_data}"' EXIT

xcodebuild \
    -project "${project_dir}/FinderQuickNav.xcodeproj" \
    -scheme FinderQuickNav \
    -configuration "${configuration}" \
    -derivedDataPath "${derived_data}" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    PROVISIONING_PROFILE_SPECIFIER= \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    build

app_path="${derived_data}/Build/Products/${configuration}/FinderQuickNav.app"
extension_path="${app_path}/Contents/PlugIns/FinderQuickNavExtension.appex"

codesign --force --sign "${signing_identity}" \
    --entitlements "${project_dir}/Extension/FinderQuickNavExtension.entitlements" \
    --timestamp=none "${extension_path}"
codesign --force --sign "${signing_identity}" \
    --entitlements "${project_dir}/App/FinderQuickNav.entitlements" \
    --timestamp=none "${app_path}"
codesign --verify --deep --strict --verbose=2 "${app_path}"

output_directory="${project_dir}/build-local"
output_path="${output_directory}/FinderQuickNav.app"
mkdir -p "${output_directory}"
if [[ -e "${output_path}" ]]; then
    backup_path="${output_path}.previous-$(date +%Y%m%d-%H%M%S)"
    mv "${output_path}" "${backup_path}"
fi
ditto "${app_path}" "${output_path}"

echo "local signed app: ${output_path}"
