#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_binary="$(mktemp -d)/extension-request-url-builder-test"

xcrun swiftc \
  "${project_dir}/Extension/ExtensionRequestURLBuilder.swift" \
  "${project_dir}/Tests/ExtensionRequestURLBuilderSmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
