#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/finder-navigation-policy-test"

xcrun swiftc \
  "${project_dir}/App/Navigation/FinderNavigator.swift" \
  "${project_dir}/App/Settings/QuickNavPreferences.swift" \
  "${project_dir}/App/QuickNavSessionState.swift" \
  "${project_dir}/Tests/FinderNavigationSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
