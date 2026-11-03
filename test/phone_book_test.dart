import 'package:bizkeep/core/phone_book.dart';
import 'package:bizkeep/data/db.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_test/flutter_test.dart';

Contact c({String name = '', String company = '', String title = '', String mobile = '', String email = '', String office = ''}) => Contact(
      id: 'x', name: name, company: company, department: '', title: title,
      phoneMobile: mobile, phoneOffice: office, fax: '', email: email, address: '', website: '', memo: '',
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

  group('주소록 중복', () {
    final book = [
      fc.Contact(name: fc.Name(first: '홍길동'), phones: [fc.Phone('+82 10-1234-5678')], emails: [fc.Email('hong@a.com')]),
      fc.Contact(name: fc.Name(first: '김철수'), phones: [fc.Phone('02-123-4567')]),
    ];
    test('휴대전화 번호로 찾기 (국가번호·하이픈 무시)', () {
      expect(PhoneBook.findIn(book, c(name: '홍길동', mobile: '010-1234-5678'))?.name.first, '홍길동');
      expect(PhoneBook.findIn(book, c(name: '홍길동', mobile: '01012345678'))?.name.first, '홍길동');
      expect(PhoneBook.findIn(book, c(name: '아무개', mobile: '010-9999-0000')), isNull);
    });
    test('번호 없으면 이메일로', () {
      expect(PhoneBook.findIn(book, c(name: 'X', email: 'HONG@a.com'))?.name.first, '홍길동');
    });
    test('달라진 항목 요약', () {
      final d = PhoneBook.diff(book[0], c(name: '홍길동', company: '안전원', title: '대리', mobile: '010-1234-5678', office: '02-555-1234'), hash: true);
      expect(d, ['이름: 홍길동 → #안전원_홍길동_대리', '회사: (없음) → 안전원', '직책: (없음) → 대리', '사무실 추가: 02-555-1234']);
    });
    test('같으면 빈 목록', () {
      final e = fc.Contact(name: fc.Name(first: '#안전원_홍길동_대리'), phones: [fc.Phone('010-1234-5678')], organizations: [fc.Organization(company: '안전원', title: '대리')]);
      expect(PhoneBook.diff(e, c(name: '홍길동', company: '안전원', title: '대리', mobile: '010-1234-5678'), hash: true), isEmpty);
    });
    test('덮어쓰기는 기존 번호 유지', () {
      final e = fc.Contact(name: fc.Name(first: '홍길동'), phones: [fc.Phone('010-1234-5678'), fc.Phone('010-0000-1111')]);
      PhoneBook.applyTo(e, c(name: '홍길동', company: '안전원', mobile: '010-1234-5678', office: '02-1'), hash: true);
      expect(e.name.first, '#안전원_홍길동');
      expect(e.phones.map((p) => p.number), ['010-1234-5678', '010-0000-1111', '02-1']);
      expect(e.organizations.single.company, '안전원');
    });
  });
}
