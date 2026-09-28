#!/bin/zsh
set -euo pipefail

extension_id="${1:-local.finderquicknav.app.extension}"
install_directory="${FQN_INSTALL_DIR:-${HOME}/Applications}"
expected_path="${2:-${install_directory}/FinderQuickNav.app/Contents/PlugIns/FinderQuickNavExtension.appex}"
expected_path="${expected_path:A}"
registration="$(pluginkit -m -A -D -v -i "$extension_id" 2>&1)"
plugin_count="$(print -r -- "$registration" | awk '/^[+!?=-][[:space:]]+/ { count++ } END { print count+0 }')"

if [[ "$registration" == *"(no matches)"* || "$registration" != *"$extension_id"* ]]; then
    print -u2 "Finder extension is not registered: $extension_id"
    exit 1
fi
if [[ "$plugin_count" -ne 1 ]]; then
    print -u2 "Expected exactly one registered Finder extension, found $plugin_count: $extension_id"
    print -u2 -- "$registration"
    exit 1
fi

registration_line="$(print -r -- "$registration" | awk '/^[+!?=-][[:space:]]+/ { print }')"
if [[ "${registration_line}" != +* ]]; then
    print -u2 -- "Finder extension is not enabled: $extension_id"
    print -u2 -r -- "$registration"
    exit 1
fi
registered_path="/${registration_line#*/}"
if [[ "${registered_path:A}" != "${expected_path}" ]]; then
    print -u2 -- "Finder extension is registered at the wrong path."
    print -u2 -r -- "Expected: ${expected_path}"
    print -u2 -r -- "Actual:   ${registered_path}"
    exit 1
fi

print -r -- "$registration"
