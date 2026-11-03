import 'package:bizkeep/core/phone_book.dart';
import 'package:bizkeep/data/db.dart';
import 'package:flutter_test/flutter_test.dart';

Contact c({String name = '', String company = '', String title = ''}) => Contact(
      id: 'x', name: name, company: company, department: '', title: title,
      phoneMobile: '', phoneOffice: '', fax: '', email: '', address: '', website: '', memo: '',
      ocrRaw: '', source: 'manual', lowConfidence: '[]', favorite: false, isMine: false, createdAt: 0, updatedAt: 0,
    );

void main() {
  test('회사_이름_직책, # 접두어', () {
    expect(PhoneBook.displayName(c(name: '변태섭', company: '안전원', title: '대리'), hash: true), '#안전원_변태섭_대리');
    expect(PhoneBook.displayName(c(name: '변태섭', company: '안전원', title: '대리'), hash: false), '안전원_변태섭_대리');
  });
  test('빈 항목은 건너뜀', () {
    expect(PhoneBook.displayName(c(name: '홍길동'), hash: true), '#홍길동');
    expect(PhoneBook.displayName(c(name: '홍길동', title: '팀장'), hash: false), '홍길동_팀장');
    expect(PhoneBook.displayName(c(), hash: true), '#명함');
  });
  test('공백 정리', () {
    expect(PhoneBook.displayName(c(name: ' 홍 길동 ', company: '한국  교육'), hash: false), '한국 교육_홍 길동');
  });
}
