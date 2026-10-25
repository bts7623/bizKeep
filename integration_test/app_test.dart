import 'package:bizkeep/core/providers.dart';
import 'package:bizkeep/features/detail/detail_sheet.dart';
import 'package:bizkeep/features/list/list_screen.dart';
import 'package:bizkeep/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 시뮬레이터 화면 점검용: 샘플 데이터 넣고 주요 화면을 캡처한다.
/// flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d `<UDID>`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester t, String name) async {
    await t.pumpAndSettle(const Duration(milliseconds: 300));
    await binding.takeScreenshot(name);
  }

  testWidgets('screens walkthrough', (t) async {
    final container = ProviderContainer();
    final repo = container.read(repoProvider);
    // 기존 데이터 비우고 샘플 8건
    for (final c in await repo.db.select(repo.db.contacts).get()) {
      await repo.delete(c.id);
    }
    final samples = [
      ('김전영', '폭스소프트', '부장', '010-1234-5678', '02-555-0123', 'jy.kim@foxsoft.co.kr', '서울 강남구 테헤란로 123, 7층', 'DR 환경 구축 담당 · 데이터가드 이슈 문의'),
      ('박서연', '한국교육학술정보원', '선임연구원', '010-9876-5432', '', 'sy.park@keris.or.kr', '대구 동구 동내로 64', 'NDMS 연계 데이터 담당'),
      ('이도현', '위즈코리아', '과장', '010-2222-3333', '02-333-4444', 'dh.lee@wiz.co.kr', '서울 금천구 가산디지털1로', '개인정보 이력 보고서 세팅 요청 중'),
      ('최민재', 'KT 클라우드', '팀장', '010-1111-2222', '', 'mj.choi@kt.com', '경기 성남시 분당구', ''),
      ('정하늘', '교육부', '사무관', '010-5555-6666', '044-203-6000', 'hnjeong@korea.kr', '세종특별자치시 갈매로 408', '교육시설 안전점검 통계 협의'),
      ('한지우', '제니퍼소프트', '대리', '010-7777-8888', '', 'jw.han@jennifersoft.com', '경기 파주시', ''),
      ('오세훈', '조달청', '주무관', '010-4444-5555', '042-481-7000', 'sh.oh@korea.kr', '대전 서구 청사로 189', '나라장터 공고 문의 창구'),
      ('윤재호', '(주)에이스정보', '이사', '010-3333-9999', '02-777-8888', 'jh.yoon@aceinfo.co.kr', '서울 강남구 역삼동', ''),
      ('강민호', '폭스소프트', '차장', '010-6666-1111', '', 'mh.kang@foxsoft.co.kr', '', ''),
      ('송지민', '교육부', '주무관', '010-8888-2222', '', 'jm.song@korea.kr', '', '시설 예산 담당'),
    ];
    for (final s in samples.reversed) {
      final c = await repo.create(name: s.$1, company: s.$2, title: s.$3, phoneMobile: s.$4, phoneOffice: s.$5, email: s.$6, address: s.$7, memo: s.$8);
      if (s.$1 == '정하늘') await repo.setFavorite(c.id, true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await repo.setCompanyFavorite('교육부', true);

    await t.pumpWidget(UncontrolledProviderScope(container: container, child: const BizKeepApp()));
    await t.pumpAndSettle(const Duration(seconds: 1));
    await shot(t, '01_list');

    // 검색: 주소 매칭 힌트
    await t.enterText(find.byType(TextField).first, '강남구');
    await t.pumpAndSettle(const Duration(milliseconds: 500));
    await shot(t, '02_search_address');

    await t.enterText(find.byType(TextField).first, '0101234');
    await t.pumpAndSettle(const Duration(milliseconds: 500));
    await shot(t, '03_search_phone');

    await t.enterText(find.byType(TextField).first, '');
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();

    // 상세
    await t.tap(find.textContaining('김전영').first);
    await shot(t, '04_detail');

    // 메모 인라인 편집
    final memoField = find.byWidgetPredicate((w) => w is TextField && (w.controller?.text.startsWith('DR') ?? false));
    await t.enterText(memoField, '통합정보망 DR 담당');
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    await shot(t, '05_detail_memo_edited');

    // 수정 화면
    await t.tap(find.text('수정'));
    await shot(t, '06_edit');
    await t.tap(find.text('취소'));
    await t.pumpAndSettle();
    // 상세 닫기
    await t.tap(find.byIcon(Icons.close_rounded).first);
    await t.pumpAndSettle();
    await shot(t, '07_list_after_memo');

    // + 메뉴
    await t.tap(find.bySemanticsLabel('명함 등록'));
    await t.pump(const Duration(milliseconds: 400));
    await shot(t, '08_add_menu');
    await t.tap(find.text('직접 입력'));
    await shot(t, '09_new_contact');
    await t.tap(find.text('취소'));
    await t.pumpAndSettle();

    // 설정
    await t.tap(find.bySemanticsLabel('설정'));
    await shot(t, '10_settings');
    await t.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await t.pumpAndSettle();

    // 스크롤로 헤더 숨김
    await t.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await t.pumpAndSettle();
    await shot(t, '11_scrolled_header_hidden');
    await t.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await t.pumpAndSettle();
    await shot(t, '12_scroll_back_header_shown');
    await t.drag(find.byType(CustomScrollView), const Offset(0, 800));
    await t.pumpAndSettle();

    // 이름순: 초성 구분 + 인덱스 바
    await t.tap(find.text('이름순'));
    await shot(t, '13_sort_name_index');
    await t.tap(find.text('ㅊ').last);
    await shot(t, '14_index_jump');
    await t.drag(find.byType(CustomScrollView), const Offset(0, 1500));
    await t.pumpAndSettle();

    // 회사순: 트리 (교육부는 즐겨찾기라 펼침, 폭스소프트는 접힘)
    await t.tap(find.text('회사순'));
    await shot(t, '15_sort_company_tree');
    await t.scrollUntilVisible(find.text('폭스소프트'), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('폭스소프트'));
    await shot(t, '16_company_expanded');

    // 내 명함 (비어 있음)
    await t.drag(find.byType(CustomScrollView), const Offset(0, 1500));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('내 명함'));
    await shot(t, '17_my_cards_empty');
    await t.tap(find.byIcon(Icons.close_rounded).first);
    await t.pumpAndSettle();
    await t.tap(find.text('최근 등록'));
    await t.pumpAndSettle();

    // 중복 명함: 김전영 (같은 휴대전화, 직책 승진) 을 다시 등록한 상황
    final dupe = await repo.create(name: '김전영', company: '폭스소프트', title: '이사', phoneMobile: '010-1234-5678', email: 'jy.kim@foxsoft.co.kr', source: 'camera');
    await t.pumpAndSettle();
    final ctx = t.element(find.byType(ListScreen));
    final fut = DetailSheet.show(ctx, dupe.id, justSaved: true);
    await t.pumpAndSettle(const Duration(milliseconds: 600));
    await shot(t, '18_dup_banner');
    await t.tap(find.textContaining('이미 있어요'));
    await shot(t, '19_dup_compare');
    await t.tap(find.text('새 명함으로 교체'));
    await t.pumpAndSettle(const Duration(milliseconds: 500));
    await shot(t, '20_after_replace');
    await t.tap(find.byIcon(Icons.close_rounded).first);
    await fut;
    await t.pumpAndSettle();
    await shot(t, '21_list_after_replace');
  });
}
