import 'package:bizkeep/data/search_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const r = SearchRanker();
  final docs = [
    const SearchDoc(id: '1', name: '김전영', company: '폭스소프트', title: '부장', phoneMobile: '010-1234-5678', phoneOffice: '02-555-0123', email: 'jy.kim@foxsoft.co.kr', address: '서울 강남구 테헤란로 123', memo: 'DR 환경 구축 담당', createdAt: 10),
    const SearchDoc(id: '2', name: '박서연', company: '한국교육학술정보원', title: '선임연구원', phoneMobile: '010-9876-5432', email: 'sy.park@keris.or.kr', address: '대구 동구', memo: 'NDMS 연계', createdAt: 20),
    const SearchDoc(id: '3', name: '김민재', company: 'KT 클라우드', title: '팀장', phoneMobile: '010-1111-2222', address: '서울 강남구 역삼동', createdAt: 30),
    const SearchDoc(id: '4', name: '이도현', company: '위즈코리아', title: '과장', ocrRaw: '위즈코리아 이도현 과장 강남', createdAt: 40),
  ];

  test('빈 입력은 결과 없음', () {
    expect(r.rank('', docs), isEmpty);
    expect(r.rank('   ', docs), isEmpty);
  });

  test('2글자 이하는 이름·회사만 검색 (주소 "강남" 안 걸림)', () {
    final hits = r.rank('강남', docs);
    expect(hits, isEmpty);
  });

  test('3글자부터 전 필드 — 주소 매칭에 힌트 표시', () {
    final hits = r.rank('강남구', docs);
    expect(hits.map((h) => h.doc.id), containsAll(['1', '3']));
    expect(hits.first.hint, startsWith('주소 ·'));
  });

  test('이름 완전일치가 prefix보다 위, prefix가 회사보다 위', () {
    final hits = r.rank('김', docs);
    expect(hits.map((h) => h.doc.id).toList(), ['3', '1']); // 둘 다 prefix 80 → 최근순
    final exact = r.rank('김전영', docs);
    expect(exact.first.doc.id, '1');
    expect(exact.first.score, 100);
  });

  test('이름·회사 매칭은 힌트 없음', () {
    expect(r.rank('박서연', docs).first.hint, isNull);
    expect(r.rank('폭스', docs).first.hint, isNull);
  });

  test('숫자 입력은 번호 우선, 하이픈 무시', () {
    final hits = r.rank('0101234', docs);
    expect(hits.single.doc.id, '1');
    expect(hits.single.field, MatchField.phone);
    final office = r.rank('02-555', docs);
    expect(office.single.doc.id, '1');
    final mid = r.rank('5678', docs);
    expect(mid.single.doc.id, '1');
  });

  test('@ 포함은 메일 우선', () {
    final hits = r.rank('sy.park@', docs);
    expect(hits.single.doc.id, '2');
    expect(hits.single.field, MatchField.email);
  });

  test('메모 검색', () {
    final hits = r.rank('NDMS', docs);
    expect(hits.single.doc.id, '2');
    expect(hits.single.hint, '메모 · NDMS 연계');
  });

  test('OCR 원문은 최하위 가중치 (직책 40 > OCR 10)', () {
    final extra = [
      ...docs,
      const SearchDoc(id: '5', name: '홍길동', ocrRaw: '선임연구원 홍길동', createdAt: 50),
    ];
    final hits = r.rank('선임연구원', extra);
    expect(hits.map((h) => h.doc.id).toList(), ['2', '5']);
    expect(hits.first.field, MatchField.title);
    expect(hits.last.field, MatchField.ocr);
  });

  test('대소문자 무시', () {
    expect(r.rank('kt 클라', docs).single.doc.id, '3');
  });

  test('limit 적용', () {
    final many = List.generate(300, (i) => SearchDoc(id: '$i', name: '테스트$i', createdAt: i));
    expect(r.rank('테스트', many).length, 200);
  });
}
