/// OCR 텍스트 → 명함 필드 분류 (순수 Dart — 테스트 대상). docs/spec.md §6, docs/ocr-plan.md
library;

class ParsedCard {
  String name = '';
  String company = '';
  String department = '';
  String title = '';
  String phoneMobile = '';
  String phoneOffice = '';
  String fax = '';
  String email = '';
  String address = '';
  String website = '';

  /// 신뢰도 낮아 비워두거나 추정한 필드명. 상세 화면에서 노란 하이라이트.
  final Set<String> lowConfidence = {};

  Map<String, Object> toMap() => {
        'name': name,
        'company': company,
        'department': department,
        'title': title,
        'phoneMobile': phoneMobile,
        'phoneOffice': phoneOffice,
        'fax': fax,
        'email': email,
        'address': address,
        'website': website,
        'lowConfidence': lowConfidence.toList(),
      };
}

/// OCR 한 줄. 좌표는 이미지 기준 0~1 정규화(좌상단 원점). 텍스트만 있으면 h = 0.
class OcrLine {
  OcrLine(this.text, {this.x = 0, this.y = 0, this.w = 0, this.h = 0});
  final String text;
  final double x, y, w, h;

  /// 같은 행(세로 겹침)에 있는 조각들을 한 줄로 합친다 — "위원장" + "김 성 고".
  static List<OcrLine> mergeRows(List<OcrLine> lines) {
    if (lines.isEmpty || lines.every((l) => l.h == 0)) return lines;
    final sorted = [...lines]..sort((a, b) => a.y.compareTo(b.y));
    final rows = <List<OcrLine>>[];
    for (final l in sorted) {
      final cy = l.y + l.h / 2;
      final row = rows.lastOrNull;
      if (row != null) {
        final r = row.last;
        final rcy = r.y + r.h / 2;
        if ((cy - rcy).abs() < (l.h < r.h ? l.h : r.h) * 0.6) {
          row.add(l);
          continue;
        }
      }
      rows.add([l]);
    }
    return [
      for (final row in rows)
        () {
          row.sort((a, b) => a.x.compareTo(b.x));
          final minY = row.map((e) => e.y).reduce((a, b) => a < b ? a : b);
          final maxY = row.map((e) => e.y + e.h).reduce((a, b) => a > b ? a : b);
          final minX = row.first.x;
          final maxX = row.map((e) => e.x + e.w).reduce((a, b) => a > b ? a : b);
          return OcrLine(row.map((e) => e.text).join('  '), x: minX, y: minY, w: maxX - minX, h: maxY - minY);
        }(),
    ];
  }
}

class OcrParser {
  const OcrParser();

  /// 한글 직책. 긴 것이 먼저 오도록 (접미 매칭).
  static const koTitles = [
    '대표이사', '대표변호사', '대표변리사', '부회장', '부사장', '전무이사', '상무이사', '본부장', '센터장', '사무총장',
    '파트장', '그룹장', '선임연구원', '책임연구원', '수석연구원', '연구위원', '전문위원', '부교수', '조교수',
    '감정평가사', '공인노무사', '공인회계사', '과장보', '위원장', '사무국장',
    '대표', '회장', '사장', '전무', '상무', '이사', '실장', '소장', '부장', '차장', '과장', '대리', '주임', '사원',
    '팀장', '팀원', '리더', '수석', '책임', '선임', '연구원', '교수', '박사', '변호사', '변리사', '회계사', '세무사',
    '노무사', '법무사', '기술사', '사무관', '서기관', '주무관', '행정관', '위원', '원장', '국장', '매니저', '프로',
    '담당', '컨설턴트', '엔지니어',
  ];
  static const enTitles = [
    'manager', 'director', 'ceo', 'cto', 'cfo', 'coo', 'cio', 'vp', 'president', 'engineer', 'consultant',
    'partner', 'associate', 'pm', 'pl', 'head', 'lead', 'leader', 'member', 'officer', 'executive',
  ];
  static const _publicDomains = ['naver', 'gmail', 'daum', 'hanmail', 'kakao', 'nate', 'hotmail', 'outlook', 'yahoo', 'icloud'];
  static const _ignoreLines = ['profile', 'kosdaq', 'kospi', '코스닥상장법인', '코스피상장법인', '상장법인', 'digital trust'];

  static final _emailRe = RegExp(r'[\w.+\-]+@[\w\-]+(\.[\w\-]+)+', caseSensitive: false);
  static final _urlRe = RegExp(r'(https?://)?(www\.)[\w\-]+(\.[\w\-]+)+(/\S*)?|[\w\-]+\.(co\.kr|com|net|org|kr|io|go\.kr|or\.kr|ac\.kr)(/\S*)?', caseSensitive: false);
  static final _phoneRe = RegExp(r'(\+82[\s\-]?\d{1,2}|0\d{1,2})[\s\-.)]?\d{3,4}[\s\-.]?\d{4}|1[5-9]\d{2}[\s\-.]?\d{4}');
  static final _mobilePrefix = RegExp(r'^(\+82[\s\-]?1[016789]|01[016789])');
  static final _labelRe = RegExp(r'^\s*(hp|h\.?p|mobile|m|h|cell|c|휴대|핸드폰|tel|t|phone|p|전화|office|o|fax|f|팩스|e-?mail|e|이메일|web|w|www|a|addr|address|주\s*소)\s*[:.]?\s*', caseSensitive: false);
  static final _segmentRe = RegExp(r'(?=(?:^|\s)(?:[TFMHCEOWPA]\.?|Tel|Fax|Mobile|Phone|H\.?P|휴대|전화|팩스)\s*[:.]?\s*)', caseSensitive: false);
  static final _addressRe = RegExp(r'(서울|부산|대구|인천|광주|대전|울산|세종|경기|강원|충북|충남|전북|전남|경북|경남|제주)[^\n]*(로|길|동|읍|면|구|시)\s*\d*[^\n]*|\(?\d{5}\)?\s*[^\n]*(로|길)\s*\d+[^\n]*');
  static final _addressCont = RegExp(r'^[가-힣\d\s\-]*(로|길)\s*\d+|^\d+\s*(층|호|번지)');
  static final _addressLabel = RegExp(r'^(주\s*소|address|addr|a)\s*[:.]?\s*', caseSensitive: false);
  static final _companyRe = RegExp(
      r'^(주식회사|㈜|\(주\)|노무법인|법무법인|회계법인|세무법인|특허법인|법률사무소|재단법인|사단법인)|(주식회사|㈜|\(주\)|유한회사|재단법인|사단법인|공사|공단|연구원|진흥원|정보원|안전원|원|청|부|처|센터|협회|연맹|조합|노동조합|학교|대학교|병원|은행|재단|회관|법인|Co\.,?\s*Ltd\.?|Inc\.?|Corp\.?|LLC|Ltd\.?)\s*$',
      caseSensitive: false);
  static final _deptSuffix = RegExp(r'(팀|과|실|본부|센터|연구소|그룹|사업단|사업부|사업부문|부문|파트|유닛|unit|담당|국|처)$', caseSensitive: false);
  static final _deptRe = RegExp(r'^[가-힣A-Za-z0-9 ·/&]{2,40}$');
  static final _hangulTok = RegExp(r'^[가-힣]{1,4}$');
  static final _latinWord = RegExp(r'^[A-Za-z][A-Za-z.\-]*$');
  static final _latinNameLine = RegExp(r'^[A-Z][a-z]+(\s[A-Z][a-z]+){1,2}$');
  static final _logoLine = RegExp(r'^([A-Za-z]\s)?[A-Z][A-Z&.\-]{2,}(\s[A-Z][A-Z&.\-]*)*$');
  static final _logoLead = RegExp(r'^[A-Za-z]\s+(?=[A-Z]{3})');
  static final _spacedDigits = RegExp(r'\d(?:\s\d){2,}');
  static final _noise = RegExp(r'[|•·▪■□●○★☆※]+');
  static final _leadNoise = RegExp(r'^[\dA-Za-z]{1,2}\s*/?\s+(?=[가-힣])');
  static final _sepRe = RegExp(r'[\s/|,]+');

  ParsedCard parse(String raw) => parseLines(raw.split(RegExp(r'\r?\n')).map((l) => OcrLine(l)).toList());

  ParsedCard parseLines(List<OcrLine> input) {
    final card = ParsedCard();
    final rows = OcrLine.mergeRows(input);
    final lines = <String>[];
    final heights = <double>[];
    for (final r in rows) {
      final t = _clean(r.text);
      if (t.isEmpty || _ignoreLines.contains(t.toLowerCase())) continue;
      lines.add(t);
      heights.add(r.h);
    }
    // 라벨만 있는 줄("F") 은 다음 줄과 합친다
    for (var i = 0; i + 1 < lines.length; i++) {
      if (RegExp(r'^[TFMHEPA]\.?$').hasMatch(lines[i])) {
        lines[i] = '${lines[i]} ${lines[i + 1]}';
        lines.removeAt(i + 1);
        heights.removeAt(i + 1);
      }
    }
    final consumed = List<bool>.filled(lines.length, false);
    final residue = [...lines]; // 메일·웹 추출 후 남은 텍스트

    // 1) 메일·웹 — 추출하고 줄에서 제거 (같은 줄 전화번호는 2)에서 처리)
    for (var i = 0; i < lines.length; i++) {
      var l = lines[i];
      final em = _emailRe.firstMatch(l);
      if (em != null && card.email.isEmpty) {
        card.email = em.group(0)!;
        l = l.replaceFirst(em.group(0)!, ' ');
      }
      final um = _urlRe.firstMatch(l);
      if (um != null && card.website.isEmpty && !um.group(0)!.contains('@')) {
        card.website = um.group(0)!;
        l = l.replaceFirst(um.group(0)!, ' ');
      }
      if (l != lines[i]) {
        residue[i] = _joinSpacedDigits(l.replaceAll('/', ' ')).trim();
        if (!RegExp(r'\d{3}|[가-힣]{2}').hasMatch(residue[i])) consumed[i] = true;
      }
    }
    _fixEmailDomain(card);

    // 2) 전화·팩스 (라벨 우선, 없으면 번호 패턴)
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      final l = _joinSpacedDigits(residue[i]).replaceAll(RegExp(r'\s*-\s*'), '-');
      if (!_phoneRe.hasMatch(l)) continue;
      final segments = l.split(_segmentRe);
      bool any = false;
      for (final seg in segments) {
        final label = _labelRe.firstMatch(seg)?.group(1)?.toLowerCase() ?? '';
        if (label == 'a' || label.startsWith('addr') || label.startsWith('주')) continue;
        final pm = _phoneRe.firstMatch(seg);
        if (pm == null) continue;
        final num = _normPhone(pm.group(0)!);
        if (_isFax(label)) {
          if (card.fax.isEmpty) card.fax = num;
        } else if (_isMobile(label) || _mobilePrefix.hasMatch(num)) {
          if (card.phoneMobile.isEmpty) {
            card.phoneMobile = num;
          } else if (card.phoneOffice.isEmpty) {
            card.phoneOffice = num;
          }
        } else {
          if (card.phoneOffice.isEmpty) {
            card.phoneOffice = num;
          } else if (card.fax.isEmpty && label.isEmpty) {
            card.fax = num;
          }
        }
        any = true;
      }
      if (any) {
        // 주소 라벨(A)이 같은 줄에 붙어 있으면 그 부분만 남긴다
        final aIdx = segments.indexWhere((s) => RegExp(r'^\s*(a|addr|address|주\s*소)\s*[:.]?\s', caseSensitive: false).hasMatch(s));
        if (aIdx >= 0 && _addressRe.hasMatch(segments[aIdx])) {
          residue[i] = segments[aIdx].trim();
        } else {
          consumed[i] = true;
        }
      }
    }

    // 3) 주소 (+ 다음 줄 이어붙이기)
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      final l = residue[i];
      if (_addressRe.firstMatch(l) == null || card.address.isNotEmpty) continue;
      card.address = l.replaceFirst(_addressLabel, '').trim();
      consumed[i] = true;
      if (i + 1 < lines.length && !consumed[i + 1] && _addressCont.hasMatch(residue[i + 1]) && !_phoneRe.hasMatch(residue[i + 1])) {
        card.address = '${card.address} ${residue[i + 1].trim()}';
        consumed[i + 1] = true;
      }
    }

    // 4) 직책 (+ 같은 줄 이름·부서). 한글 직책 우선, 없을 때만 영문.
    int titleLine = -1;
    int nameLine = -1;
    for (final useEn in [false, true]) {
      if (card.title.isNotEmpty) break;
      for (var i = 0; i < lines.length; i++) {
        if (consumed[i]) continue;
        final tokens = _tokens(lines[i]);
        final isTitle = tokens.map((t) => _titleOf(t, en: useEn) != null).toList();
        if (!isTitle.contains(true)) continue;
        // 마지막 직책 토큰 = 직책. 바로 앞의 연속 직책 토큰(자격명 등)은 합친다: "대표 공인노무사"
        var last = isTitle.lastIndexOf(true);
        var first = last;
        while (first > 0 && isTitle[first - 1]) {
          first--;
        }
        // "본부장 / 상무" 처럼 구분자로 나뉜 두 직책은 마지막 것만
        if (first < last && lines[i].contains(RegExp(r'[/|]'))) first = last;
        card.title = tokens.sublist(first, last + 1).map((t) => _titleOf(t, en: useEn)!).join(' ');
        final rest = [for (var k = 0; k < tokens.length; k++) if (k < first || k > last) tokens[k]];
        // 이름: 나머지 한글 토큰(1~4자, 부서·회사 아님) 합쳐 2~4자
        final hangul = rest.where((t) => _hangulTok.hasMatch(t) && !(t.length >= 2 && _looksLikeOrg(t))).toList();
        final joined = hangul.join();
        if (hangul.isNotEmpty && joined.length >= 2 && joined.length <= 4 && !_looksLikeOrg(joined)) {
          card.name = joined;
        }
        // 부서: 이름·직책 아닌 토큰 중 부서 접미사
        final dept = rest.where((t) => !hangul.contains(t) && _deptSuffix.hasMatch(t) && _titleOf(t, en: true) == null).toList();
        if (dept.isNotEmpty) card.department = dept.join(' / ');
        consumed[i] = true;
        titleLine = i;
        if (card.name.isNotEmpty) nameLine = i;
        break;
      }
    }

    // 4.1) 영문 번역줄·로마자 이름줄 제거
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      final l = lines[i];
      final tokens = _tokens(l);
      final allLatin = tokens.isNotEmpty && tokens.every((t) => _latinWord.hasMatch(t) || RegExp(r'^\d+$').hasMatch(t));
      if (!allLatin) continue;
      if (card.title.isNotEmpty && tokens.any((t) => enTitles.contains(t.toLowerCase()))) consumed[i] = true;
      if (_latinNameLine.hasMatch(l)) consumed[i] = true;
    }

    // 4.2) 이름이 아직 없으면: 직책 줄 인접 → 글자 큰 줄 → 첫 후보
    if (card.name.isEmpty) {
      final cands = <int>[];
      for (var i = 0; i < lines.length; i++) {
        if (!consumed[i] && _nameFrom(lines[i]) != null) cands.add(i);
      }
      int? pick;
      if (titleLine >= 0) {
        pick = cands.where((i) => (i - titleLine).abs() == 1).firstOrNull;
      }
      if (pick == null && cands.isNotEmpty && heights.any((h) => h > 0)) {
        final byH = [...cands]..sort((a, b) => heights[b].compareTo(heights[a]));
        pick = byH.first;
      }
      pick ??= cands.firstOrNull;
      if (pick != null) {
        card.name = _nameFrom(lines[pick])!;
        consumed[pick] = true;
        nameLine = pick;
        if (titleLine < 0 && cands.length > 1) card.lowConfidence.add('name');
      }
    }

    // 4.5) 부서 줄: 부서 접미사로 끝나는 줄 (회사+부서 한 줄이면 분리)
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      final l = lines[i];
      if (!_deptRe.hasMatch(l) || l == card.name) continue;
      final parts = l.split(RegExp(r'\s*/\s*')).where((p) => p.isNotEmpty).toList();
      if (!parts.every((p) => _deptSuffix.hasMatch(p))) continue;
      var dept = parts.join(' / ');
      if (parts.length == 1) {
        final words = l.split(RegExp(r'\s+'));
        if (words.length >= 2 && _companyRe.hasMatch(words.first) && !_deptSuffix.hasMatch(words.first)) {
          // "세종문화회관 재무행정팀"
          if (card.company.isEmpty) card.company = words.sublist(0, words.length - 1).join(' ');
          dept = words.last;
        }
      }
      card.department = card.department.isEmpty ? dept : '$dept / ${card.department}';
      consumed[i] = true;
      break;
    }

    // 5) 회사: 한글 패턴 > 영문 로고(+도메인) > 도메인 > 첫 미소비 줄
    if (card.company.isEmpty) {
      final hits = <int>[];
      for (var i = 0; i < lines.length; i++) {
        if (consumed[i]) continue;
        if (_companyRe.hasMatch(lines[i]) && lines[i] != card.name && !_phoneRe.hasMatch(lines[i])) hits.add(i);
      }
      if (hits.isNotEmpty) {
        var pick = hits.first;
        // 상위조직 + 본조직 2줄: 글자 큰 쪽, 없으면 아래쪽
        if (hits.length >= 2 && hits[1] == hits[0] + 1) {
          pick = heights[hits[1]] >= heights[hits[0]] ? hits[1] : hits[0];
          final other = pick == hits[0] ? hits[1] : hits[0];
          if (card.department.isEmpty) {
            card.department = lines[other];
            consumed[other] = true;
          }
        }
        card.company = lines[pick];
        consumed[pick] = true;
      }
    }
    final domain = _domainLabel(card.email);
    if (card.company.isEmpty) {
      // 한글이 섞인 짧은 미소비 줄 (이름·전화 아님)
      final first = _firstIndex(lines, consumed, (l) => RegExp('[가-힣]').hasMatch(l) && _nameFrom(l) == null && l.length <= 30 && !_phoneRe.hasMatch(l));
      if (first >= 0) {
        card.company = lines[first];
        consumed[first] = true;
        card.lowConfidence.add('company');
      }
    }
    if (card.company.isEmpty) {
      // 영문 로고 (단독 줄 또는 이름 줄에 붙은 대문자 토큰) — 메일 도메인과 맞으면 확신
      String? logo;
      final li = _firstIndex(lines, consumed, (l) => _logoLine.hasMatch(l));
      if (li >= 0) {
        logo = lines[li];
        consumed[li] = true;
      } else if (nameLine >= 0) {
        logo = _tokens(lines[nameLine]).where((t) => _logoLine.hasMatch(t) && t.length >= 3).firstOrNull;
      }
      if (logo != null) {
        logo = logo.replaceFirst(_logoLead, '');
        card.company = logo;
        final key = logo.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (domain == null || !(key == domain || key.startsWith(domain) || domain.startsWith(key))) card.lowConfidence.add('company');
      }
    }
    if (card.company.isEmpty) {
      final first = _firstIndex(lines, consumed, (l) => _nameFrom(l) == null && !_latinNameLine.hasMatch(l) && l.length <= 30 && !_phoneRe.hasMatch(l));
      if (first >= 0) {
        card.company = lines[first];
        consumed[first] = true;
        card.lowConfidence.add('company');
      } else if (domain != null) {
        card.company = domain;
        card.lowConfidence.add('company');
      }
    }
    card.company = card.company.replaceFirst(_leadNoise, '').trim();

    if (card.name.isEmpty) card.lowConfidence.add('name');
    if (card.company.isEmpty) card.lowConfidence.add('company');
    if (card.title.isEmpty && card.name.isNotEmpty) card.lowConfidence.add('title');
    return card;
  }

  // ---- helpers ----

  static String _clean(String l) => l.replaceAll(_noise, ' / ').replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'^(/\s*)+|(\s*/)+$'), '').trim();

  /// 토큰 분리 + 끊긴 직책 합치기 ("위 원장" → 위원장)
  static List<String> _tokens(String l) {
    final raw = l.split(_sepRe).where((t) => t.isNotEmpty).toList();
    final out = <String>[];
    for (var i = 0; i < raw.length; i++) {
      if (i + 1 < raw.length && raw[i].length <= 2 && koTitles.contains(raw[i] + raw[i + 1])) {
        out.add(raw[i] + raw[i + 1]);
        i++;
      } else {
        out.add(raw[i]);
      }
    }
    return out;
  }

  static String _joinSpacedDigits(String l) => l.replaceAllMapped(_spacedDigits, (m) => m.group(0)!.replaceAll(' ', ''));

  /// 토큰이 직책이면 정규화된 직책, 아니면 null. 한글은 접미 매칭("대표변호사"), 영문은 완전 일치.
  static String? _titleOf(String t, {required bool en}) {
    final lower = t.toLowerCase();
    for (final k in koTitles) {
      if (t == k) return k;
      if (t.endsWith(k) && RegExp(r'^[가-힣]+$').hasMatch(t) && !_deptSuffix.hasMatch(t)) {
        final prefix = t.substring(0, t.length - k.length);
        if (koTitles.contains(prefix)) return '$prefix $k';
        if (t.length <= k.length + 2) return t;
      }
    }
    if (en && enTitles.contains(lower)) return t;
    return null;
  }

  static bool _looksLikeOrg(String s) => _companyRe.hasMatch(s) || _deptSuffix.hasMatch(s) || koTitles.contains(s);

  /// 줄이 "이름 (+ 로마자)" 형태면 이름, 아니면 null. "이 영 우 Lee Yeongwoo" → 이영우
  static String? _nameFrom(String l) {
    final tokens = _tokens(l);
    if (tokens.isEmpty) return null;
    final hangul = tokens.where((t) => _hangulTok.hasMatch(t)).toList();
    if (hangul.isEmpty || hangul.length != tokens.where((t) => RegExp('[가-힣]').hasMatch(t)).length) return null;
    if (!tokens.every((t) => _hangulTok.hasMatch(t) || _latinWord.hasMatch(t))) return null;
    final joined = hangul.join();
    if (joined.length < 2 || joined.length > 4) return null;
    if (_looksLikeOrg(joined) || _titleOf(joined, en: false) != null) return null;
    return joined;
  }

  static String? _domainLabel(String email) {
    final at = email.indexOf('@');
    if (at < 0) return null;
    final label = email.substring(at + 1).split('.').first.toLowerCase();
    return _publicDomains.contains(label) ? null : label;
  }

  /// 같은 명함의 웹사이트 도메인과 편집거리 1 이내면 메일 도메인을 교정 (sojongpac → sejongpac)
  static void _fixEmailDomain(ParsedCard c) {
    if (c.email.isEmpty || c.website.isEmpty) return;
    final at = c.email.indexOf('@');
    final ed = c.email.substring(at + 1).toLowerCase();
    final wd = c.website.toLowerCase().replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'^www\.'), '').split('/').first;
    if (ed == wd || (ed.length - wd.length).abs() > 1) return;
    if (_editDistance(ed, wd) == 1) c.email = '${c.email.substring(0, at + 1)}$wd';
  }

  static int _editDistance(String a, String b) {
    final prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var diag = prev[0];
      prev[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final tmp = prev[j];
        prev[j] = [prev[j] + 1, prev[j - 1] + 1, diag + (a[i - 1] == b[j - 1] ? 0 : 1)].reduce((x, y) => x < y ? x : y);
        diag = tmp;
      }
    }
    return prev[b.length];
  }

  static int _firstIndex(List<String> lines, List<bool> consumed, bool Function(String) test) {
    for (var i = 0; i < lines.length; i++) {
      if (!consumed[i] && test(lines[i])) return i;
    }
    return -1;
  }

  static bool _isFax(String l) => l.startsWith('f') || l == '팩스';
  static bool _isMobile(String l) => ['m', 'mobile', 'hp', 'h.p', 'h', 'c', 'cell', '휴대', '핸드폰'].contains(l);

  /// 010-1234-5678 / 02-555-0123 형태로 정규화. +82 → 0.
  static String _normPhone(String s) {
    var d = s.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+82')) d = '0${d.substring(3)}';
    d = d.replaceAll('+', '');
    if (d.startsWith('02')) {
      if (d.length == 9) return '02-${d.substring(2, 5)}-${d.substring(5)}';
      if (d.length == 10) return '02-${d.substring(2, 6)}-${d.substring(6)}';
    }
    if (d.length == 8) return '${d.substring(0, 4)}-${d.substring(4)}';
    if (d.length == 10) return '${d.substring(0, 3)}-${d.substring(3, 6)}-${d.substring(6)}';
    if (d.length == 11) return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
    return s.trim();
  }

  /// 통화 식별 익스텐션용 E.164 (+8210…). 실패 시 null.
  static String? toE164(String phone) {
    var d = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+')) return d.length >= 10 ? d : null;
    if (d.startsWith('0') && d.length >= 9) return '+82${d.substring(1)}';
    return null;
  }
}
