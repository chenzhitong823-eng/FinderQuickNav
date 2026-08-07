#!/bin/zsh
set -euo pipefail

app_path="${1:?usage: verify-bundle-versions.sh /path/to/FinderQuickNav.app}"
app_plist="$app_path/Contents/Info.plist"
extension_plist="$app_path/Contents/PlugIns/FinderQuickNavExtension.appex/Contents/Info.plist"

app_version="$(plutil -extract CFBundleVersion raw -o - "$app_plist")"
extension_version="$(plutil -extract CFBundleVersion raw -o - "$extension_plist")"

if [[ -z "$app_version" || -z "$extension_version" ]]; then
  print -u2 "bundle version must not be empty"
  exit 1
fi

if [[ "$app_version" != "$extension_version" ]]; then
  print -u2 "bundle version mismatch: app=$app_version extension=$extension_version"
  exit 1
fi

print "bundle versions match: $app_version"
