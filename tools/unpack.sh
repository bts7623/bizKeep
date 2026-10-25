#!/bin/bash
# 컨테이너에서 보낸 tgz 를 unlink 없이 풀기 (마운트는 삭제 금지): tools/unpack.sh tools/src.tgz
set -e
cd "$(dirname "$0")/.."
for f in $(tar tzf "$1"); do
  [ -z "${f##*/}" ] && continue
  mkdir -p "$(dirname "$f")"
  tar xzf "$1" -O "$f" > "$f"
  echo "updated $f"
done
