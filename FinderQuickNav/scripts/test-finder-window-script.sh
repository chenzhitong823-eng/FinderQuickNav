#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/finder-window-script-test"

xcrun swiftc \
  "${project_dir}/App/Navigation/FinderWindowScriptBuilder.swift" \
  "${project_dir}/Tests/FinderWindowScriptSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
