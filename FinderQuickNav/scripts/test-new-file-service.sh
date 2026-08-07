#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
build_dir="${project_dir}/build/smoke-tests/new-file-service"
mkdir -p "$build_dir"

swiftc \
  -swift-version 6 \
  -module-name NewFileServiceSmokeTest \
  "$project_dir/App/NewFile/NewFileService.swift" \
  "$project_dir/Tests/NewFileServiceSmokeTest/main.swift" \
  -o "$build_dir/new-file-service-smoke-test"

"$build_dir/new-file-service-smoke-test"
