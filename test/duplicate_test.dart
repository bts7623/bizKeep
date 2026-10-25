import 'package:bizkeep/data/contact_repo.dart';
import 'package:bizkeep/data/db.dart';
import 'package:flutter_test/flutter_test.dart';

Contact c(String id, {String name = '', String company = '', String mobile = '', String email = '', String title = '', bool mine = false}) => Contact(
      id: id, name: name, company: company, department: '', title: title, phoneMobile: mobile, phoneOffice: '', fax: '', email: email,
      address: '', website: '', memo: '', imageFront: null, imageBack: null, thumb: null, ocrRaw: '', source: 'manual',
      lowConfidence: '[]', createdAt: 0, updatedAt: 0, favorite: false, isMine: mine,
    );

void main() {
  test('같은 사람: 휴대전화 > 이메일 > 이름+회사', () {
    expect(ContactRepo.isSamePerson(c('1', mobile: '010-1234-5678'), c('2', mobile: '01012345678', name: '다른이름')), true);
    expect(ContactRepo.isSamePerson(c('1', email: 'A@x.com'), c('2', email: 'a@x.com')), true);
    expect(ContactRepo.isSamePerson(c('1', name: '김전영', company: '(주)폭스소프트'), c('2', name: '김전영', company: '폭스소프트')), true);
    expect(ContactRepo.isSamePerson(c('1', name: '김전영', company: '폭스소프트'), c('2', name: '김전영', company: '더존')), false);
    expect(ContactRepo.isSamePerson(c('1', name: '김전영'), c('2', name: '김전영')), false); // 회사 없으면 판단 안 함
    expect(ContactRepo.isSamePerson(c('1', mobile: '010-1234-5678'), c('1', mobile: '010-1234-5678')), false); // 자기 자신
    expect(ContactRepo.isSamePerson(c('1', mobile: '010-1234-5678'), c('2', mobile: '010-1234-5678', mine: true)), false);
  });

  test('달라진 필드만', () {
    final d = ContactRepo.diffFields(c('1', name: '김전영', title: '과장', mobile: '010-1'), c('2', name: '김전영', title: '부장', mobile: '010-1'));
    expect(d.length, 1);
    expect(d.first, ('직책', '과장', '부장'));
    expect(ContactRepo.diffFields(c('1', name: 'a'), c('2', name: 'a ')), isEmpty);
  });
}
