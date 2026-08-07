#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
info_plist="${project_dir}/App/Info.plist"

display_name="$(plutil -extract CFBundleDisplayName raw -o - "${info_plist}")" || true
[[ "${display_name}" == "man导" ]]

lui_element="$(plutil -extract LSUIElement raw -o - "${info_plist}" 2>/dev/null || true)"
[[ "${lui_element}" == "true" || "${lui_element}" == "1" ]]

grep -Fq 'SettingsWindowController.shared.show()' "${project_dir}/App/AppDelegate.swift"
[[ "$(grep -cF 'SettingsWindowController.shared.show()' "${project_dir}/App/AppDelegate.swift")" -ge 2 ]]
grep -Fq 'PendingQuickNavRequestStore' "${project_dir}/App/AppDelegate.swift"
grep -Fq 'HostSessionEnsurer' "${project_dir}/Extension/FinderSync.swift"
grep -Fq 'MenuBarController' "${project_dir}/App/AppDelegate.swift"
grep -Fq 'SettingsWindowController.shared.show()' "${project_dir}/App/QuickNavPanelController.swift"
[[ -f "${project_dir}/App/MenuBarController.swift" ]]
[[ -f "${project_dir}/App/Assets.xcassets/AppIcon.appiconset/Contents.json" ]]

echo "app identity smoke test passed"
