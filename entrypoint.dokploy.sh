#!/bin/sh
set -eu

dir="$HOME/.nanobot"
mkdir -p "$dir"

if [ -d "$dir" ] && [ ! -w "$dir" ]; then
    owner_uid=$(stat -c %u "$dir" 2>/dev/null || stat -f %u "$dir" 2>/dev/null)
    cat >&2 <<EOF
Error: $dir is not writable (owned by UID $owner_uid, running as UID $(id -u)).
Mount config.json directly to: $dir/config.json
EOF
    exit 1
fi

exec nanobot "$@"
