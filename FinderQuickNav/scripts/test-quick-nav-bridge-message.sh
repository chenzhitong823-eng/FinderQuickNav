#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/quick-nav-bridge-message-test"

xcrun swiftc \
  "${project_dir}/Shared/QuickNavBridgeMessage.swift" \
  "${project_dir}/Tests/QuickNavBridgeMessageSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
