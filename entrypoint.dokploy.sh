#!/bin/sh
set -eu

dir="$HOME/.nanobot"
config_file="$dir/config.json"
mkdir -p "$dir"

if [ -d "$dir" ] && [ ! -w "$dir" ]; then
    owner_uid=$(stat -c %u "$dir" 2>/dev/null || stat -f %u "$dir" 2>/dev/null)
    cat >&2 <<EOF
Error: $dir is not writable (owned by UID $owner_uid, running as UID $(id -u)).
Mount config.json directly to: $dir/config.json
EOF
    exit 1
fi

if [ ! -f "$config_file" ]; then
    cat >&2 <<EOF
Error: config file not found: $config_file
Mount config.json directly to: $config_file
EOF
    exit 1
fi

if [ ! -r "$config_file" ]; then
    cat >&2 <<EOF
Error: config file is not readable: $config_file
EOF
    exit 1
fi

python3 - "$config_file" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"Error: invalid JSON in {path}: {e}", file=sys.stderr)
    raise SystemExit(1)

providers = data.get("providers") or {}
defaults = ((data.get("agents") or {}).get("defaults") or {})
provider = defaults.get("provider")
model = defaults.get("model")

if not provider:
    print("Error: missing agents.defaults.provider in config.json", file=sys.stderr)
    raise SystemExit(1)
if not model:
    print("Error: missing agents.defaults.model in config.json", file=sys.stderr)
    raise SystemExit(1)
if provider == "auto":
    print("Error: agents.defaults.provider must be explicit (not 'auto')", file=sys.stderr)
    raise SystemExit(1)

provider_cfg = providers.get(provider) or {}
api_key = provider_cfg.get("api_key") or provider_cfg.get("apiKey")
if not api_key:
    print(
        f"Error: missing providers.{provider}.api_key in config.json",
        file=sys.stderr,
    )
    raise SystemExit(1)
PY

exec nanobot "$@"
