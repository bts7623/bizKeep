import 'package:bizkeep/data/db.dart';
import 'package:bizkeep/data/list_grouper.dart';
import 'package:flutter_test/flutter_test.dart';

Contact c(String id, String name, String company, {bool fav = false, int created = 0, String memo = ''}) => Contact(
      id: id, name: name, company: company, department: '', title: '', phoneMobile: '', phoneOffice: '', fax: '', email: '',
      address: '', website: '', memo: memo, imageFront: null, imageBack: null, thumb: null, ocrRaw: '', source: 'manual',
      lowConfidence: '[]', createdAt: created, updatedAt: created, favorite: fav, isMine: false,
    );

void main() {
  const g = ListGrouper();
  final oct = DateTime(2026, 10, 5).millisecondsSinceEpoch;
  final sep = DateTime(2026, 9, 20).millisecondsSinceEpoch;
  final all = [
    c('1', '김전영', '폭스소프트', created: oct),
    c('2', '이영우', '메타빌드', created: oct, fav: true),
    c('3', '변재희', '세종문화회관', created: sep),
    c('4', '오민석', '더존비즈온', created: sep),
    c('5', '유수연', '(주)더존비즈온', created: sep),
    c('6', 'Alice', '', created: sep),
  ];

  test('초성 키', () {
    expect(ListGrouper.indexKeyOf('김전영'), 'ㄱ');
    expect(ListGrouper.indexKeyOf('이영우'), 'ㅇ');
    expect(ListGrouper.indexKeyOf('alice'), 'A');
    expect(ListGrouper.indexKeyOf(''), '#');
    expect(ListGrouper.indexKeyOf('123'), '#');
  });

  test('최근순: 즐겨찾기 상단 + 월 구분, 즐겨찾기는 아래에 중복 안 됨', () {
    final out = g.group(all, mode: SortMode.recent);
    expect(out[0], isA<SectionEntry>().having((e) => e.label, 'label', '즐겨찾기'));
    expect((out[1] as ContactEntry).contact.id, '2');
    expect((out[2] as SectionEntry).label, '2026년 10월');
    expect((out[3] as ContactEntry).contact.id, '1');
    expect((out[4] as SectionEntry).label, '2026년 9월');
    expect(out.whereType<ContactEntry>().where((e) => e.contact.id == '2').length, 1);
  });

  test('이름순: 초성 구분 + indexKey', () {
    final out = g.group(all.where((x) => !x.favorite).toList(), mode: SortMode.name);
    final keys = [for (final e in out) if (e is SectionEntry) e.indexKey];
    expect(keys, ['A', 'ㄱ', 'ㅂ', 'ㅇ']); // Alice, 김, 변, 오·유
    final last = out.sublist(out.length - 2).map((e) => (e as ContactEntry).contact.name).toList();
    expect(last, ['오민석', '유수연']);
  });

  test('회사순: 2명 이상만 트리, (주) 정규화로 같은 회사, 소속 없음 맨 뒤', () {
    final out = g.group(all, mode: SortMode.company);
    final companies = out.whereType<CompanyEntry>().toList();
    expect(companies.length, 1);
    expect(companies.first.name, '더존비즈온');
    expect(companies.first.count, 2);
    expect(companies.first.expanded, false);
    // 접힌 상태: 더존 멤버 행 없음
    expect(out.whereType<ContactEntry>().any((e) => e.contact.id == '4'), false);
    expect((out.last as ContactEntry).contact.name, 'Alice');
  });

  test('회사순: 펼침·회사 즐겨찾기(맨 위, 자동 펼침, 1명이어도 트리)', () {
    final out = g.group(all, mode: SortMode.company, expanded: {'더존비즈온'}, favoriteCompanies: {'폭스소프트'});
    // 즐겨찾기 사람 섹션(이영우) 다음에 폭스소프트 트리
    final firstCompany = out.whereType<CompanyEntry>().first;
    expect(firstCompany.name, '폭스소프트');
    expect(firstCompany.favorite, true);
    expect(firstCompany.expanded, true);
    final dz = out.whereType<CompanyEntry>().firstWhere((e) => e.key == '더존비즈온');
    expect(dz.expanded, true);
    final i = out.indexOf(dz);
    expect((out[i + 1] as ContactEntry).indent, true);
    expect((out[i + 1] as ContactEntry).contact.name, '오민석');
  });
}
