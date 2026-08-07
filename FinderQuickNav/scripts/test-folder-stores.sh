#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/folder-stores-test"

xcrun swiftc \
  "${project_dir}/App/Storage/FolderEntry.swift" \
  "${project_dir}/App/Storage/FavoritesStore.swift" \
  "${project_dir}/App/Storage/RecentsStore.swift" \
  "${project_dir}/Tests/FolderStoresSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
