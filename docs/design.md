# BizKeep 디자인 토큰 (캔버스 v2 기준)

## 색
| 토큰 | 값 | 용도 |
|---|---|---|
| bg | #F6F7FA (상단 #EEF1F7 → 그라데이션) | 목록 배경 |
| surface | #FFFFFF | 행·카드·시트 |
| surfaceAlt | #F6F7F9 | 상세 필드 그룹 배경 |
| ink | #111318 | 본문·+버튼·아이콘 |
| inkMuted | #6B7280 | 보조 텍스트 (대비 4.6:1) |
| inkFaint | #B0B5BE | 셰브론·플레이스홀더 |
| line | #EEF0F3 | 구분선 |
| accent | #2F62E6 | 액션 아이콘, 칩 선택, 링크 |
| accentTint | #E8EFFF | 액센트 배경 |
| call | #22A95B (버튼) / #E6F6EE 배경 + #1B7A47 아이콘 (목록) | 통화 |
| memoBg | #F0F4FF | 메모 박스 |
| memoBorder | #DCE5FF | 메모 박스 테두리 |
| memoInk | #1E2F5C | 메모 글씨 (상세·입력) |
| memoListInk | #5B6475 | 메모 글씨 (목록) |
| warnBg | #FFF6DC / warnInk #8A5A00 | 인식 불확실 필드 |
| danger | #C62828 / #FDECEC | 삭제 |
| glass | rgba(255,255,255,0.72) + blur 24px + border rgba(255,255,255,0.95) | 하단 독·오버레이 카드 |

## 타이포 (Noto Sans KR / 시스템 기본 폴백)
| 역할 | 크기/굵기 |
|---|---|
| 상단 숫자 | 34 / 800, letter-spacing -0.03em |
| 상세 이름 | 26 / 700 |
| 행 이름 | 17 / 700 |
| 본문·입력 | 16 / 500 |
| 행 직책·메모·보조 | 13 / 500 |
| 행 회사·라벨 | 12~13 / 500, inkMuted |
전체 letter-spacing -0.01em.

## 간격·형태
- 화면 좌우 패딩 20, 행 패딩 10, 행 간격 10, 행 radius 20
- 썸네일 64×40 radius 8, 상세 명함 영역 160 radius 18
- 버튼: 원형 44(목록 통화) / 56(독) / 64(상세 통화), 시트 radius 28 상단
- 터치 타겟 최소 44
- 그림자: 행 `0 1px 2px rgba(17,19,24,.04), 0 6px 18px rgba(17,19,24,.05)`, 독 `0 10px 30px rgba(17,19,24,.12)`

## 아이콘
- 선 아이콘 (stroke 1.8~2.2), 이모지 금지. 통화는 채움.
- 앱 아이콘: 시안 B — 네이비 #0E1A33 바탕, 명함 3장(#2F62E6 → #7FA3FF → #FFFFFF) -6° 기울여 겹침.
