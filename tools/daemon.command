#!/bin/bash
# BizKeep 작업 데몬 — 터미널 창 하나만 띄워두고 tools/queue/*.sh 를 순서대로 실행
# 종료: tools/queue/STOP 파일 생성
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
Q="tools/queue"; L="tools/logs"
mkdir -p "$Q" "$L"
echo "BizKeep 작업 데몬 실행 중 (이 창은 그대로 두세요). 종료: tools/queue/STOP"
while true; do
  if [ -f "$Q/STOP" ]; then rm -f "$Q/STOP"; echo "데몬 종료"; exit 0; fi
  for j in $(ls "$Q"/*.sh 2>/dev/null | sort); do
    n=$(basename "$j" .sh)
    echo "▶ $n  $(date '+%H:%M:%S')"
    { echo "=== START $(date) ==="; bash "$j"; echo "=== EXIT $? $(date) ==="; } > "$L/$n.log" 2>&1
    mv "$j" "$L/$n.sh"
    echo "■ $n 완료"
  done
  sleep 2
done
