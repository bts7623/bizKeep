# BizKeep (명함관리)

명함을 찍어 두고, 폰 주소록에 넣지 않은 채 업무 연락처를 빠르게 찾고 바로 전화하는 iOS/Android 앱. Flutter 단일 코드베이스.

## 절대 원칙
1. **속도가 최우선.** 콜드스타트 1초 내, 검색 응답 50ms 내. UI 스레드에서 무거운 일 금지 (OCR·이미지 압축·FTS 인덱싱은 isolate).
2. **화면은 3개 + 보조.** 목록(검색 포함) / 상세(수정 포함) / 설정. 그 외 화면 추가 금지. 설명문·온보딩 최소화.
3. **촬영 = 저장.** 명함 찍으면 확인 단계 없이 즉시 저장 후 상세 표시. "저장하시겠습니까" 류 다이얼로그 금지.
4. **서버 없음. 전부 온디바이스.** 네트워크는 (설정에서 켰을 때만) LLM 보정용 외엔 사용 안 함.
5. **한 줄 메모.** 메모는 40자 한 줄. 멀티라인·리치텍스트 금지.

## 기술 스택
- Flutter 3.27 (stable) / Dart 3.6
- 상태관리: flutter_riverpod
- DB: drift + sqlite3_flutter_libs, FTS5 가상테이블
- OCR: google_mlkit_text_recognition (Korean script, 온디바이스)
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
  features/
    list/                  # 목록·검색·헤더 숨김·하단 독
    detail/                # 상세 바텀시트, 한 줄 메모 인라인 편집, 명함 크게 보기
    edit/                  # 직접 입력·수정 폼
    capture/               # 카메라 → OCR → 즉시 저장
    settings/              # 통화식별·백업·정보
test/
  search_ranker_test.dart
  ocr_parser_test.dart
docs/
  spec.md                  # 요구사항·화면·검색규칙·데이터모델 (원본은 Claude Design 캔버스)
  design.md                # 색·타이포·간격 토큰
tools/
  run.command / job.sh     # Finder에서 실행하는 작업 러너 (로그: tools/job.log)
```

## 개발 환경 메모
- Flutter: /opt/homebrew/bin/flutter
- Xcode 설치 후: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch`, `brew install cocoapods`
- 명령 실행은 tools/job.sh 를 수정한 뒤 Finder에서 tools/run.command 열기 → tools/job.log 확인
- 테스트: `flutter test` (Xcode 불필요), 정적 분석: `flutter analyze`

## 코드 규칙
- 목록 행 위젯은 `const` + 고정 높이, `ListView.builder` 사용. 썸네일은 별도 생성된 작은 WebP만.
- 검색은 150ms 디바운스, FTS5 MATCH prefix 쿼리, 결과 상위 200건.
- 2글자 이하 입력은 이름·회사만 검색, 3글자부터 전 필드. 숫자 시작 → 번호 우선, @ 포함 → 메일 우선.
- 결과 정렬 가중치: 이름 > 회사 > 직책 > 번호·메일 > 주소·메모. 이름 완전일치 최상단.
- 모든 레코드는 UUID + updated_at 보유 (기기 간 가져오기·충돌 판단용).
- 내보내기 포맷: `contacts.json + images/` 를 zip 하나로. 가져오기는 같은 포맷.
- 한국어 UI. 문구는 짧게, 존댓말 ("~해요" 체).
