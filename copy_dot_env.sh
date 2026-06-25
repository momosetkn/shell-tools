#!/usr/bin/env bash
set -euo pipefail

A_DIR="${1:-a}"
B_DIR="${2:-B}"

mkdir -p "$B_DIR"

find "$A_DIR" -type f \( -name ".env" -o -name ".env.*" \) -print0 |
while IFS= read -r -d '' file; do
  rel="${file#$A_DIR/}"
  dest="$B_DIR/$rel"

  mkdir -p "$(dirname "$dest")"
  cp -p "$file" "$dest"

  echo "copied: $file -> $dest"
done
