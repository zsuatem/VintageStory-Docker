#!/bin/sh
set -eu

server_dir="${1:-}"

if [ -z "$server_dir" ]; then
    echo "Usage: $0 <server-dir>" >&2
    exit 1
fi

if [ ! -d "$server_dir" ]; then
    echo "Server directory not found: $server_dir" >&2
    exit 1
fi

assembly_path="$server_dir/VintagestoryServer.dll"

if [ ! -f "$assembly_path" ]; then
    echo "Server assembly not found: $assembly_path" >&2
    exit 1
fi

version="$(
    grep -a -o -m1 '\.NETCoreApp,Version=v[0-9]\+\.[0-9]\+' "$assembly_path" \
    | sed 's/^\.NETCoreApp,Version=v//'
)"

if [ -z "$version" ]; then
    echo "Could not determine required .NET runtime from $assembly_path" >&2
    exit 1
fi

channel="$(printf '%s' "$version" | cut -d. -f1,2)"

case "$channel" in
    [0-9]*.[0-9]*) printf '%s\n' "$channel" ;;
    *)
        echo "Unsupported .NET runtime version '$version' in $assembly_path" >&2
        exit 1
        ;;
esac
