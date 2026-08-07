#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_dir="$(mktemp -d)"
test_binary="${test_dir}/host-launch-test"

xcrun swiftc \
  "${project_dir}/Shared/QuickNavBridgeMessage.swift" \
  "${project_dir}/Shared/PendingQuickNavRequestStore.swift" \
  "${project_dir}/Extension/HostSessionEnsurer.swift" \
  "${project_dir}/Tests/HostLaunchSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
