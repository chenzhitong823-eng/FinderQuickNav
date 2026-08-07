#!/bin/zsh
set -euo pipefail

extension_id="${1:-local.finderquicknav.app.extension}"
registration="$(pluginkit -m -A -D -v -i "$extension_id" 2>&1)"
plugin_count="$(print -r -- "$registration" | rg -c '^[+!?=-][[:space:]]+' || true)"

if [[ "$registration" == *"(no matches)"* || "$registration" != *"$extension_id"* ]]; then
    print -u2 "Finder extension is not registered: $extension_id"
    exit 1
fi
if [[ "$plugin_count" -ne 1 ]]; then
    print -u2 "Expected exactly one registered Finder extension, found $plugin_count: $extension_id"
    print -u2 -- "$registration"
    exit 1
fi

print "$registration"
