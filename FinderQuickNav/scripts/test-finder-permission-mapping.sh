#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/finder-permission-mapping-test"

xcrun swiftc \
  "${project_dir}/App/Navigation/FinderNavigator.swift" \
  "${project_dir}/App/Permissions/PermissionCenter.swift" \
  "${project_dir}/Tests/FinderPermissionSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
