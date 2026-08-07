#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
group_name="group.local.finderquicknav"

plutil -lint "${project_dir}/App/FinderQuickNav.entitlements" >/dev/null
plutil -lint "${project_dir}/Extension/FinderQuickNavExtension.entitlements" >/dev/null

plutil -p "${project_dir}/App/FinderQuickNav.entitlements" \
    | rg -q "\\\"${group_name}\\\""
plutil -p "${project_dir}/Extension/FinderQuickNavExtension.entitlements" \
    | rg -q "\\\"${group_name}\\\""
rg -q 'CODE_SIGN_ENTITLEMENTS: App/FinderQuickNav\.entitlements' "${project_dir}/project.yml"
rg -q 'CODE_SIGN_ENTITLEMENTS: Extension/FinderQuickNavExtension\.entitlements' "${project_dir}/project.yml"
rg -q 'NewFilePreferencesStore\(\)\.enabledEntries' "${project_dir}/Extension/FinderSync.swift"

echo "app group config smoke test passed"
