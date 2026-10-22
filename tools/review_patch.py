import sys, re
root=sys.argv[1]
def patch(path, pairs):
    p=f'{root}/{path}'; s=open(p).read()
    for a,b in pairs:
        if a not in s: print('MISS', path, a[:50]); continue
        s=s.replace(a,b)
    open(p,'w').write(s)

# 1) ImagePaths.resolve: 파일명만 저장된 경우 I/O 없이 조합 (목록 행마다 existsSync 호출 제거)
patch('lib/core/image_paths.dart', [(
"""  static String resolve(String stored) {
    if (stored.isEmpty) return stored;
    if (File(stored).existsSync()) return stored;
    return p.join(cardsDir, p.basename(stored));
  }""",
"""  static String resolve(String stored) {
    if (stored.isEmpty) return stored;
    // 파일명만 저장된 정상 케이스: I/O 없이 조합
    if (!stored.startsWith('/')) return p.join(cardsDir, stored);
    // 구버전 절대경로: 살아있으면 그대로, 아니면 현재 샌드박스로 재조합
    if (File(stored).existsSync()) return stored;
    return p.join(cardsDir, p.basename(stored));
  }""")])

# 2) 시스템 폰트 사용 (번들 안 된 폰트명 제거)
patch('lib/core/theme.dart', [(
"""  const font = 'NotoSansKR';
  final base = ThemeData(""","""  final base = ThemeData("""),
("""    fontFamily: font,
""","")])

# 3) 전화·문자·메일: canLaunchUrl 생략 (iOS는 LSApplicationQueriesSchemes 없으면 false 반환)
patch('lib/core/actions.dart', [(
"""  static Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }""",
"""  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }""")])

# 4) 명함 보기 → "상세 정보": pop 된 context 로 시트를 열지 않도록 결과값으로 돌려줌
patch('lib/features/detail/card_view_screen.dart', [(
"""                  onTap: () { Navigator.pop(context); DetailSheet.show(context, c.id); },""",
"""                  onTap: () => Navigator.pop(context, 'detail'),"""),
("import 'detail_sheet.dart';\n","")])
patch('lib/features/list/list_screen.dart', [(
"""    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardViewScreen(contactId: c.id), fullscreenDialog: true));
  }""",
"""    Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => CardViewScreen(contactId: c.id), fullscreenDialog: true))
        .then((r) { if (r == 'detail' && mounted) _openDetail(c); });
  }""")])
print('done')
