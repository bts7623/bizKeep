# BizKeep (명함관리)

명함을 찍어 두고, 폰 주소록에 넣지 않은 채 업무 연락처를 빠르게 찾고 바로 전화하는 iOS/Android 앱.

- 화면 3개: 목록(검색) · 상세(한 줄 메모) · 설정
- 촬영 = 저장. 확인 단계 없음
- 완전 온디바이스, 서버 없음
- Flutter 3.47 · Riverpod · drift(SQLite) · ML Kit OCR(2단계) · CallKit 통화 식별(3단계)

문서: [docs/spec.md](docs/spec.md) · [docs/design.md](docs/design.md) · 작업 규칙 [CLAUDE.md](CLAUDE.md)

## 개발

```bash
flutter pub get
dart run build_runner build
flutter test
flutter run
```
