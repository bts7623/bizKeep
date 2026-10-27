import 'package:bizkeep/core/calldir.dart';
import 'package:bizkeep/data/db.dart';
import 'package:flutter_test/flutter_test.dart';

Contact c(String id, {String name = '', String company = '', String mobile = '', String office = '', bool mine = false, int created = 0}) => Contact(
      id: id, name: name, company: company, department: '', title: '', phoneMobile: mobile, phoneOffice: office, fax: '', email: '',
      address: '', website: '', memo: '', imageFront: null, imageBack: null, thumb: null, ocrRaw: '', source: 'manual',
      lowConfidence: '[]', createdAt: created, updatedAt: created, favorite: false, isMine: mine,
    );

void main() {
  test('통화 식별 엔트리: E.164 정수, 오름차순, 중복은 먼저 온 사람, 내 명함 제외', () {
    final e = CallDir.entriesOf([
      c('1', name: '김전영', company: '폭스소프트', mobile: '010-1234-5678', office: '02-555-0123'),
      c('2', name: '박서연', company: '', mobile: '010-1234-5678'), // 같은 번호 → 김전영 유지
      c('3', name: '나', mobile: '010-0000-0000', mine: true),
      c('4', name: '', company: '', mobile: '010-9999-9999'), // 라벨 없음 → 제외
    ]);
    expect(e, [
      [8225550123, '김전영 · 폭스소프트'],
      [821012345678, '김전영 · 폭스소프트'],
    ]);
  });
}
