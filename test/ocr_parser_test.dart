import 'dart:convert';
import 'dart:io';

import 'package:bizkeep/data/ocr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const p = OcrParser();

  test('전형적인 국문 명함', () {
    final c = p.parse('''
폭스소프트
FOXSOFT
기술본부 DR사업팀
김전영 부장
M 010-1234-5678  T 02-555-0123  F 02-555-0124
jy.kim@foxsoft.co.kr
www.foxsoft.co.kr
서울 강남구 테헤란로 123, 7층
''');
    expect(c.name, '김전영');
    expect(c.title, '부장');
    expect(c.company, '폭스소프트');
    expect(c.department, '기술본부 DR사업팀');
    expect(c.phoneMobile, '010-1234-5678');
    expect(c.phoneOffice, '02-555-0123');
    expect(c.fax, '02-555-0124');
    expect(c.email, 'jy.kim@foxsoft.co.kr');
    expect(c.website, 'www.foxsoft.co.kr');
    expect(c.address, startsWith('서울 강남구 테헤란로 123'));
  });

  test('공공기관 명함 — 사무관, (주) 없는 기관명', () {
    final c = p.parse('''
교육부
교육시설과
사무관 정하늘
Tel. 044-203-6000
Mobile 010-5555-6666
hnjeong@korea.kr
세종특별자치시 갈매로 408
''');
    expect(c.company, '교육부');
    expect(c.title, '사무관');
    expect(c.name, '정하늘');
    expect(c.department, '교육시설과');
    expect(c.phoneOffice, '044-203-6000');
    expect(c.phoneMobile, '010-5555-6666');
  });

  test('라벨 없는 번호 — 010은 휴대, 02는 사무실', () {
    final c = p.parse('''
(주)에이스정보
윤재호 이사
02-1234-5678
010-9999-8888
''');
    expect(c.company, '(주)에이스정보');
    expect(c.phoneOffice, '02-1234-5678');
    expect(c.phoneMobile, '010-9999-8888');
  });

  test('+82 국제번호 정규화', () {
    final c = p.parse('''
KT Cloud
최민재 팀장
+82 10 1111 2222
''');
    expect(c.phoneMobile, '010-1111-2222');
    expect(c.company, 'KT Cloud');
  });

  test('이름 없는 명함은 lowConfidence 에 name', () {
    final c = p.parse('''
위즈코리아
고객지원팀
02-333-4444
''');
    expect(c.name, '');
    expect(c.lowConfidence, contains('name'));
    expect(c.department, '고객지원팀');
  });

  test('E.164 변환', () {
    expect(OcrParser.toE164('010-1234-5678'), '+821012345678');
    expect(OcrParser.toE164('02-555-0123'), '+8225550123');
    expect(OcrParser.toE164('+82 10 1234 5678'), '+821012345678');
    expect(OcrParser.toE164('123'), isNull);
  });

  // ---- 실기기 OCR 변형 (아이폰 크롭 이미지 기준, 2026-10-23 캡처) ----

  test('음절 공백 이름 + 영문명 + 파이프 직책 + 영문 로고 (METABUILD)', () {
    final c = p.parse('''
이 영 우 Lee Yeongwoo
METABUILD
사업3본부 | 상무이사
Sales Office 3 | Managing Director
주 소 서울특별시 서초구 서초중앙로 62 메타빌드빌딩 (06640)
M 010.5581.6189  T 02.598.3327
E lyw@metabuild.co.kr  F 02.598.3329
www.metabuild.co.kr
''');
    expect(c.name, '이영우');
    expect(c.title, '상무이사');
    expect(c.department, '사업3본부');
    expect(c.company, 'METABUILD');
    expect(c.lowConfidence, isNot(contains('company')));
    expect(c.phoneMobile, '010-5581-6189');
    expect(c.phoneOffice, '02-598-3327');
    expect(c.fax, '02-598-3329');
    expect(c.email, 'lyw@metabuild.co.kr');
    expect(c.address, '서울특별시 서초구 서초중앙로 62 메타빌드빌딩 (06640)');
  });

  test('회사+부서 한 줄, 가운뎃점 직책·이름, 메일 도메인 교정, 주소 두 줄 (세종문화회관)', () {
    final c = p.parse('''
세종문화회관 재무행정팀
팀원 • 변재희
Team Member
Jae Hee Byun
P 02 399 1021
M 010 6247 4784
F 02 399 1519
E jhbyun@sojongpac.or.kr
03172 서울특별시 종로구
세종대로 175(세종로)
www.sejongpac.or.kr
게종
''');
    expect(c.name, '변재희');
    expect(c.title, '팀원');
    expect(c.company, '세종문화회관');
    expect(c.department, '재무행정팀');
    expect(c.phoneOffice, '02-399-1021');
    expect(c.phoneMobile, '010-6247-4784');
    expect(c.fax, '02-399-1519');
    expect(c.email, 'jhbyun@sejongpac.or.kr');
    expect(c.address, '03172 서울특별시 종로구 세종대로 175(세종로)');
  });

  test('상위조직 2줄, 직책 뒤 공백 이름, H./E. 한 줄 (법무부노동조합)', () {
    final c = p.parse('''
한국노총 공공연맹
법무부노동조합
MINISTRY OF JUSTICE TRADE UNION
위원장 김 성 고
H. 010-8875-2025  E. ksg2025@naver.com
서울특별시 구로구 금오로 865(서울남부구치소) (우)08367
''');
    expect(c.name, '김성고');
    expect(c.title, '위원장');
    expect(c.company, '법무부노동조합');
    expect(c.department, '한국노총 공공연맹');
    expect(c.phoneMobile, '010-8875-2025');
    expect(c.email, 'ksg2025@naver.com');
    expect(c.address, startsWith('서울특별시 구로구 금오로 865'));
  });

  test('자간 넓은 번호, 직책+자격명, 가운뎃점 한 줄 (노무법인 호연)', () {
    final c = p.parse('''
대표 공인노무사  곽 영 준
노무법인 호연
LABOR LAW FIRM HOYEON
PROFILE
0 1 0 - 6 3 8 7 - 4 1 2 8 · kyj@hyinsa.com · www.hyinsa.com
(본사)서울특별시 구로구 디지털로33길 28 우림이비지센터 1차 306호(08377)
''');
    expect(c.name, '곽영준');
    expect(c.title, '대표 공인노무사');
    expect(c.company, '노무법인 호연');
    expect(c.department, '');
    expect(c.phoneMobile, '010-6387-4128');
    expect(c.email, 'kyj@hyinsa.com');
    expect(c.website, 'www.hyinsa.com');
    expect(c.address, startsWith('(본사)서울특별시 구로구'));
  });

  test('슬래시 부서/직책, A 주소 라벨, T/F 한 줄 (드림시큐리티)', () {
    final c = p.parse('''
(주)드림시큐리티
DREAM SECURITY
Digital Trust
이 상 훈
제품구축팀 / 구축3파트 / 선임
M 010 2802 0645
E shoon.lee@dreamsecurity.com
T 02 2233 5533   F 02 402 3622
A 04783 서울시 성동구 아차산로 126 더리브세종타워 10층
KOSDAQ
코스닥상장법인
''');
    expect(c.name, '이상훈');
    expect(c.title, '선임');
    expect(c.department, '제품구축팀 / 구축3파트');
    expect(c.company, '(주)드림시큐리티');
    expect(c.phoneMobile, '010-2802-0645');
    expect(c.phoneOffice, '02-2233-5533');
    expect(c.fax, '02-402-3622');
    expect(c.address, '04783 서울시 성동구 아차산로 126 더리브세종타워 10층');
  });

  test('슬래시 3단 직책은 마지막, 앞 기호 제거, 영문 슬로건 무시 (더존)', () {
    final c = p.parse('''
N | 더존지니어스
Business Partner
유 수 연
솔루션사업본부 / 본부장 / 상무
T 1544-0914  M 010-9005-1348
E ysywlswn@douzone.site
''');
    expect(c.name, '유수연');
    expect(c.title, '상무');
    expect(c.department, '솔루션사업본부');
    expect(c.company, '더존지니어스');
    expect(c.phoneOffice, '1544-0914');
    expect(c.phoneMobile, '010-9005-1348');

    final d = p.parse('''
DOUZONE
오 민 석
솔루션사업부문 / 솔루션구축1센터
솔루션구축1Unit / 리더 / 차장
더존비즈온
www.douzone.com
M 010-7142-4620  E msoh@douzone.com
''');
    expect(d.name, '오민석');
    expect(d.title, '차장');
    expect(d.department, '솔루션사업부문 / 솔루션구축1센터 / 솔루션구축1Unit');
    expect(d.company, '더존비즈온');
  });

  test('회사명 줄에 상장 배지·URL 이 붙은 경우 (더존비즈온 KOSPI www…)', () {
    final c = p.parse('''
Maximizing Potential DOUZONE
정 연 석
TS본부 / TS영업3센터
영업2Unit / 차장
더존비즈온 (OsP) www.douzone.com
서울특별시 중구 을지로1가 87 더존을지타워 14F
T 02-6233-4030  M 010-4745-9636
F 02-6670-0907  E ysju@douzone.com
''');
    expect(c.name, '정연석');
    expect(c.title, '차장');
    expect(c.company, '더존비즈온');
    expect(c.website, 'www.douzone.com');
    expect(c.department, 'TS본부 / TS영업3센터 / 영업2Unit');
  });

  test('이름 줄에 로마자(붙어쓴)·로고 기호가 같이 합쳐진 경우', () {
    final c = p.parse('''
이 영 우 LeeYeongwoo @METABUILD
사업3본부 | 상무이사
Sales Office 3 | Managing Director
주 소 서울특별시 서초구 서초중앙로 62 메타빌드빌딩 (06640)
M 010.5581.6189  T 02.598.3327
E lyw@metabuild.co.kr  F 02.598.3329
www.metabuild.co.kr
''');
    expect(c.name, '이영우');
    expect(c.company, 'METABUILD');
    expect(c.title, '상무이사');
  });

  test('조직명이 붙은 긴 직책 + 약어 로고 + 기관명을 주소로 오인하지 않기 (노동조합)', () {
    final c = p.parse('''
한국노총/공공연맹
SMLU 서울교통공사통합노동조합
조직강화실장 조 성 익
04803 서울시 성동구 천호대로 232 서울교통공사 신답별관 8F
Tel 02-6110-8337  Fax 02-6110-8339
M.P 010-2639-5980  E-mail gheh719@naver.com
''');
    expect(c.name, '조성익');
    expect(c.title, '조직강화실장');
    expect(c.company, '서울교통공사통합노동조합');
    expect(c.department, '한국노총/공공연맹');
    expect(c.address, startsWith('04803 서울시 성동구 천호대로 232'));
    expect(c.phoneOffice, '02-6110-8337');
    expect(c.fax, '02-6110-8339');
    expect(c.phoneMobile, '010-2639-5980');
    expect(c.email, 'gheh719@naver.com');
  });

  test('좌표가 있으면 같은 행 조각을 합치고 큰 글자를 이름으로', () {
    final c = p.parseLines([
      OcrLine('한국노총 공공연맹', x: 0.3, y: 0.10, w: 0.3, h: 0.04),
      OcrLine('법무부노동조합', x: 0.3, y: 0.15, w: 0.5, h: 0.09),
      OcrLine('위원장', x: 0.3, y: 0.35, w: 0.1, h: 0.05),
      OcrLine('김 성 고', x: 0.5, y: 0.34, w: 0.3, h: 0.07),
      OcrLine('H. 010-8875-2025', x: 0.1, y: 0.6, w: 0.3, h: 0.04),
    ]);
    expect(c.name, '김성고');
    expect(c.title, '위원장');
    expect(c.company, '법무부노동조합');
    expect(c.department, '한국노총 공공연맹');
  });

  // ---- 픽스처: test/fixtures/cards/*.txt (맥 Vision 출력, git 제외) + expected.json ----
  group('fixtures', () {
    final dir = Directory('test/fixtures/cards');
    final expectedFile = File('${dir.path}/expected.json');
    if (!expectedFile.existsSync()) return;
    final expected = jsonDecode(expectedFile.readAsStringSync()) as Map<String, dynamic>;
    for (final entry in expected.entries) {
      final txt = File('${dir.path}/${entry.key}.txt');
      if (!txt.existsSync()) continue;
      test(entry.key, () {
        final c = p.parse(txt.readAsStringSync());
        final e = (entry.value as Map<String, dynamic>)['expect'] as Map<String, dynamic>;
        final actual = c.toMap();
        for (final k in ['name', 'company', 'department', 'title', 'phoneMobile', 'phoneOffice', 'fax', 'email']) {
          if (e.containsKey(k)) expect(actual[k], e[k], reason: '$k (${entry.key})');
        }
      });
    }
  });
}
