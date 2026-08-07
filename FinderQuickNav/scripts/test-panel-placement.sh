#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/panel-placement-test"

xcrun swiftc \
  "${project_dir}/Shared/PanelPlacementEngine.swift" \
  "${project_dir}/Tests/PanelPlacementSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
