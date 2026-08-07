#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_dir="$(mktemp -d)"
test_binary="${test_dir}/settings-preferences-test"

xcrun swiftc \
  "${project_dir}/Shared/QuickNavBridgeMessage.swift" \
  "${project_dir}/App/Storage/FolderEntry.swift" \
  "${project_dir}/App/Storage/FavoritesStore.swift" \
  "${project_dir}/App/Settings/QuickNavPreferences.swift" \
  "${project_dir}/Shared/NewFilePreferencesStore.swift" \
  "${project_dir}/Tests/SettingsPreferencesSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
