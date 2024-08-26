#!/bin/bash
set -e
cyan build --prune

extra_files=(

)

copy_files() {
  for file in "$@"; do
    mkdir -p "./build/$(dirname "$file")"
    cp -rf "$file" "./build/$file"
  done
}

while IFS= read -r -d '' file; do
  copy_files "$file"
done < <(find . -type f -name "*.lua" ! -path "./build/*" ! -path "./.history/*" -print0)

copy_files "${extra_files[@]}"
