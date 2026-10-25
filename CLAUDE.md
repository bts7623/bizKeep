# BizKeep (명함관리)

명함을 찍어 두고, 폰 주소록에 넣지 않은 채 업무 연락처를 빠르게 찾고 바로 전화하는 iOS/Android 앱. Flutter 단일 코드베이스.

## 절대 원칙
1. **속도가 최우선.** 콜드스타트 1초 내, 검색 응답 50ms 내. UI 스레드에서 무거운 일 금지 (OCR·이미지 압축·FTS 인덱싱은 isolate).
2. **화면은 3개 + 보조.** 목록(검색 포함) / 상세(수정 포함) / 설정. 그 외 화면 추가 금지. 설명문·온보딩 최소화.
3. **촬영 = 저장.** 명함 찍으면 확인 단계 없이 즉시 저장 후 상세 표시. "저장하시겠습니까" 류 다이얼로그 금지.
4. **서버 없음. 전부 온디바이스. 네트워크 사용 없음.** (AI 보정 옵션은 제거함 — 규칙 분류가 자주 틀리면 그때 재검토)
5. **한 줄 메모.** 메모는 40자 한 줄. 멀티라인·리치텍스트 금지.

## 기술 스택
- Flutter 3.47 (stable, Homebrew cask) / Dart 3.10
- 상태관리: flutter_riverpod
- DB: drift + sqlite3_flutter_libs. 검색은 전체 레코드 메모리 캐시 + `search_ranker.dart` (수천 건까지 ms 단위). FTS5는 1만 건 초과 시 도입.
- OCR·사각 검출: iOS는 Apple Vision (ios/Runner/VisionPlugin.swift, MethodChannel `bizkeep/vision`) — ML Kit은 arm64 시뮬레이터 미지원이라 제외. Android는 ML Kit을 Kotlin 채널로 (2단계-B).
- 카메라: camera / image_picker, 이미지: image (WebP 압축, ≤1024px)
- 전화·메일·문자: url_launcher
- 통화 식별 (3단계): iOS CallKit Call Directory Extension (Swift) / Android CallScreeningService + 오버레이
- 설정값: shared_preferences

## 폴더 구조
```
lib/
  main.dart
  app.dart                 # MaterialApp, 테마, 라우팅
  core/theme.dart          # 색·타이포 토큰 (docs/design.md 와 동일)
  data/
    db.dart                # drift 스키마 + FTS5 + 마이그레이션
    contact_repo.dart      # CRUD, 검색, 내보내기/가져오기
    search_ranker.dart     # 검색 가중치·우선순위 (순수 Dart, 테스트 대상)
    ocr_parser.dart        # OCR 텍스트 → 필드 분류 (순수 Dart, 테스트 대상)
    list_grouper.dart      # 정렬 모드별 섹션(월·초성·회사 트리)·즐겨찾기 배치 (순수 Dart, 테스트 대상)
  features/
    list/                  # 목록·검색·헤더 숨김·하단 독
    detail/                # 상세 바텀시트, 한 줄 메모 인라인 편집, 명함 크게 보기
    edit/                  # 직접 입력·수정 폼
    capture/               # 카메라 → OCR → 즉시 저장 (mine: true 면 내 명함, OCR 없이 이미지만)
    mycard/                # 내 명함 시트: 여러 장 등록(촬영·앨범), 넘겨 보기, 꾹 눌러 공유(저장·복사·에어드롭)
    settings/              # 통화식별·백업·정보
test/
  search_ranker_test.dart
  ocr_parser_test.dart
  list_grouper_test.dart
  duplicate_test.dart      # 중복 판정·diff
docs/
  spec.md                  # 요구사항·화면·검색규칙·데이터모델 (원본은 Claude Design 캔버스)
  design.md                # 색·타이포·간격 토큰
tools/
  daemon.command           # Finder에서 한 번 실행해 두는 작업 데몬 (queue/*.sh → logs/*.log)
  ocr_fixtures.swift       # 픽스처 명함 사진 → Vision OCR 원문(.txt/.boxes.tsv). 픽스처(실명함)는 git 제외
```

## 개발 환경 메모
- Flutter: /opt/homebrew/bin/flutter (3.47.7)
- Xcode 설치 후: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch`, `brew install cocoapods`
- **작업 데몬**: Finder에서 `tools/daemon.command` → "다음으로 열기 → 터미널" 로 한 번 띄워두면,
  `tools/queue/NN_name.sh` 에 넣은 스크립트를 순서대로 실행하고 `tools/logs/NN_name.log` 에 기록한다. 종료는 `tools/queue/STOP` 파일.
- 테스트: `flutter test` (Xcode 불필요, 36개 통과), 정적 분석: `flutter analyze` (0 issues)
- 코드 생성: `dart run build_runner build` (drift)
- 시뮬레이터 UI 검증: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d <UDID>` → tools/logs/shots/*.png
- Flutter 3.47 + Xcode 27: SPM 끔(`flutter config --no-enable-swift-package-manager`), Podfile `use_frameworks! :linkage => :static`, platform 15.5
- **GitHub**: 원격 https://github.com/bts7623/bizKeep (private). 맥에는 gh·자격증명이 없으므로 맥에서 직접 push 하지 않는다.
  커밋은 맥(데몬)에서 만들고 `git bundle create tools/repo.bundle main` → Claude 세션 컨테이너로 가져가 push 한다.
- 컨테이너 → 맥 파일 전송: tgz 를 보내고 `tools/unpack.sh tools/x.tgz` (마운트는 unlink 금지라 tar -O 로 덮어씀). 맥에서 git 쓰려면 세션마다 삭제 권한 요청 필요(.git lock).

## 진행 상태
- [x] 1단계 코드: 목록·검색·상세(인라인 메모)·입력·설정·명함 보기, 헤더 숨김, 랭커·OCR 파서 + 테스트
- [x] 1단계 검증: iPhone 18 Pro 시뮬레이터(iOS 27) — integration_test 12장면 통과 (tools/logs/shots/)
- [x] 2단계-A (iOS): camera + Vision 사각 검출 **자동 촬영** + 원근 보정 크롭 + Vision OCR → 즉시 저장. **실기기 검증 필요** (시뮬레이터엔 카메라 없음)
- [ ] 2단계-B (Android): ML Kit Kotlin 채널로 `bizkeep/vision` 동일 API 구현
- [ ] 3단계: 통화 식별 (iOS Call Directory Extension)
- [x] 목록 구분자(최근=월, 이름=초성+인덱스 바, 회사=트리 접기/펴기) · 즐겨찾기(사람=상단 고정, 회사=트리 상단+펼침) · 내 명함(여러 장, 공유 시트). DB schemaVersion 2 (favorite, is_mine, company_prefs)
- [x] 연속 등록(촬영 직후 상세의 "다음 명함" → 바로 촬영) · 중복 명함(휴대전화>이메일>이름+회사 판정, 배너 → 달라진 필드 비교 → 교체/따로/중복삭제; 메모·즐겨찾기 유지) · + 메뉴 스피드 다이얼 · 촬영 화면 앨범 가져오기
- [ ] 4단계: 백업/복원, 초성검색
- [x] **OCR 파서 보완 1차** — `docs/ocr-plan.md` §0~§5 반영 (픽스처 5장 + 실기기 변형 7건 테스트 통과). §6 사용자 수정 학습, §7 온디바이스 LLM 은 보류. 새 오인식 명함은 사진을 `test/fixtures/cards/` 에 넣고 `swift tools/ocr_fixtures.swift test/fixtures/cards` → `expected.json` 에 기대값 추가

## 아이디어 백로그 (우선순위 순, 검토 의견은 대화 기록)
1. 3단계 통화 식별 (Apple Developer 등록 후)
2. ~~목록 그룹핑~~ 완료 3. ~~즐겨찾기~~ 완료 4. ~~내 명함~~ 완료 (주고받기 없음, 내 명함 등록·공유만)
5. iOS 내비게이션: 설정·명함보기는 push+스와이프 백, 상세 시트는 끌어내려 닫기, 촬영·입력은 모달 유지
6. 성능은 측정 후 최적화 (수백 건 넘기 전엔 손대지 않음)
7. BizDrop(P2P 전송)은 보류 — AirDrop/vCard로 대체

## 코드 규칙
- 목록 행 위젯은 `const` + 고정 높이(ContactRow.heightPlain/heightWithSub — 인덱스 점프 오프셋 계산에 사용), `SliverList` 사용. 썸네일은 별도 생성된 작은 WebP만.
- 검색은 150ms 디바운스, 메모리 캐시 + SearchRanker, 결과 상위 200건.
- 2글자 이하 입력은 이름·회사만 검색, 3글자부터 전 필드. 숫자 시작 → 번호 우선, @ 포함 → 메일 우선.
- 결과 정렬 가중치: 이름 > 회사 > 직책 > 번호·메일 > 주소·메모. 이름 완전일치 최상단.
- 모든 레코드는 UUID + updated_at 보유 (기기 간 가져오기·충돌 판단용).
- 내보내기 포맷: `contacts.json + images/` 를 zip 하나로. 가져오기는 같은 포맷.
- 한국어 UI. 문구는 짧게, 존댓말 ("~해요" 체).
