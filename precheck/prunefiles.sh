#!/usr/bin/env bash
set -euo pipefail

src_dir="rackfiles-2-12"
dst_dir="rackfiles-2-12-16"

mkdir -p "$dst_dir"

# Only regular files at top-level of rackfiles/
for f in "$src_dir"/*.txt; do
  [[ -f "$f" ]] || continue
  # Copy only files with ≥ 16 lines
  if [[ $(wc -l < "$f") -ge 16 ]]; then
    head -n 16 -- "$f" > "$dst_dir/$(basename -- "$f")"
  fi
done
