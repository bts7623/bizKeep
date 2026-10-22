#!/bin/bash
# BizKeep 작업 실행기: tools/job.sh 를 실행하고 tools/job.log 에 기록
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
LOG="tools/job.log"
echo "=== START $(date) ===" > "$LOG"
bash tools/job.sh >> "$LOG" 2>&1
echo "=== EXIT $? $(date) ===" >> "$LOG"
echo "작업 완료 — 이 창은 닫아도 됩니다."
