#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/monitored-root-resolver-test"

xcrun swiftc \
  "${project_dir}/Extension/MonitoredRootResolver.swift" \
  "${project_dir}/Tests/MonitoredRootResolverSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
