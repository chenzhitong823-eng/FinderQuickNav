#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/pending-quick-nav-request-test"

xcrun swiftc \
  "${project_dir}/Shared/QuickNavBridgeMessage.swift" \
  "${project_dir}/Shared/PendingQuickNavRequestStore.swift" \
  "${project_dir}/Tests/PendingQuickNavRequestSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
