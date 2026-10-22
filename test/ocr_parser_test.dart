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
}
