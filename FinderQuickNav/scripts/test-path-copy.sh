#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
test_dir="$(mktemp -d)"
test_binary="${test_dir}/path-copy-test"

xcrun swiftc \
  "${project_dir}/App/QuickNavPathCopyService.swift" \
  "${project_dir}/Tests/PathCopySmokeTest/main.swift" \
  -o "${test_binary}"

"${test_binary}"
