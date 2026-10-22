#!/bin/bash
# BizKeep 환경 점검 — 결과를 tools/env_report.txt 에 저장
cd "$(dirname "$0")"
OUT="env_report.txt"
{
  echo "=== $(date) ==="
  echo "macOS: $(sw_vers -productVersion) / $(uname -m)"
  echo "--- xcode-select ---"; xcode-select -p 2>&1
  echo "--- xcodebuild ---"; xcodebuild -version 2>&1 | head -2
  echo "--- flutter ---"; which flutter 2>&1; flutter --version 2>&1 | head -3
  echo "--- dart ---"; which dart 2>&1
  echo "--- brew ---"; which brew 2>&1
  echo "--- cocoapods ---"; which pod 2>&1
  echo "--- simulators ---"; xcrun simctl list devices available 2>&1 | head -20
  echo "--- flutter doctor ---"; flutter doctor -v 2>&1
  echo "=== DONE ==="
} > "$OUT" 2>&1
echo "완료. 이 창은 닫아도 됩니다."
