/// OCR 텍스트 → 명함 필드 분류 (순수 Dart — 테스트 대상). docs/spec.md §6
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

class OcrParser {
  const OcrParser();

  static const titles = [
    '대표이사', '대표', '회장', '부회장', '사장', '부사장', '전무', '상무', '이사', '본부장', '실장', '센터장', '소장',
    '부장', '차장', '과장', '대리', '주임', '사원', '팀장', '파트장', '그룹장', '수석', '책임', '선임', '선임연구원',
    '책임연구원', '수석연구원', '연구원', '연구위원', '교수', '부교수', '조교수', '박사', '변호사', '변리사', '회계사',
    '세무사', '노무사', '기술사', '감정평가사', '사무관', '서기관', '주무관', '행정관', '전문위원', '위원', '원장',
    '국장', '과장보', '매니저', 'manager', 'director', 'ceo', 'cto', 'cfo', 'coo', 'vp', 'president',
    'engineer', 'consultant', 'partner', 'associate', 'pm', 'pl',
  ];

  static final _emailRe = RegExp(r'[\w.+\-]+@[\w\-]+(\.[\w\-]+)+', caseSensitive: false);
  static final _urlRe = RegExp(r'(https?://)?(www\.)[\w\-]+(\.[\w\-]+)+(/\S*)?|[\w\-]+\.(co\.kr|com|net|org|kr|io|go\.kr|or\.kr|ac\.kr)(/\S*)?', caseSensitive: false);
  static final _phoneRe = RegExp(r'(\+82[\s\-]?\d{1,2}|0\d{1,2})[\s\-.)]?\d{3,4}[\s\-.]?\d{4}');
  static final _mobilePrefix = RegExp(r'^(\+82[\s\-]?1[016789]|01[016789])');
  static final _labelRe = RegExp(r'^\s*(m|mobile|h\.?p|hp|c|cell|휴대|핸드폰|t|tel|전화|o|office|f|fax|팩스|e|e-?mail|이메일|w|web|www)\s*[:.]?\s*', caseSensitive: false);
  static final _addressRe = RegExp(r'(서울|부산|대구|인천|광주|대전|울산|세종|경기|강원|충북|충남|전북|전남|경북|경남|제주)[^\n]*(로|길|동|읍|면|구|시)\s*\d*[^\n]*|\(?\d{5}\)?\s*[^\n]*(로|길)\s*\d+[^\n]*');
  static final _companySuffix = RegExp(r'^(주식회사|㈜|\(주\))|(주식회사|㈜|\(주\)|유한회사|재단법인|사단법인|공사|공단|연구원|진흥원|정보원|안전원|원|청|부|처|센터|협회|학교|대학교|병원|은행|Co\.,?\s*Ltd\.?|Inc\.?|Corp\.?|LLC|Ltd\.?)\s*$', caseSensitive: false);
  static final _deptRe = RegExp(r'^[가-힣A-Za-z0-9 ·/&]{2,24}(팀|과|실|본부|센터|연구소|그룹|사업단|사업부|파트)$');
  static final _koreanName = RegExp(r'^[가-힣]{2,4}$');
  static final _noise = RegExp(r'[|•·▪■□●○★☆※]+');

  ParsedCard parse(String raw) {
    final card = ParsedCard();
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.replaceAll(_noise, ' ').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final consumed = List<bool>.filled(lines.length, false);

    // 1) 메일·웹
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final em = _emailRe.firstMatch(l);
      if (em != null && card.email.isEmpty) {
        card.email = em.group(0)!;
        consumed[i] = true;
        continue;
      }
      final um = _urlRe.firstMatch(l);
      if (um != null && card.website.isEmpty && !l.contains('@')) {
        card.website = um.group(0)!;
        consumed[i] = true;
      }
    }

    // 2) 전화·팩스 (라벨 우선, 없으면 번호 패턴)
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      final l = lines[i];
      final matches = _phoneRe.allMatches(l).toList();
      if (matches.isEmpty) continue;
      // 한 줄에 여러 번호: "T 02-555-0123 F 02-555-0124 M 010-1234-5678"
      final segments = l.split(RegExp(r'(?=(?:^|\s)(?:[TFMHCEOW]\.?|Tel|Fax|Mobile|H\.?P|휴대|전화|팩스)\s*[:.]?\s*)', caseSensitive: false));
      bool any = false;
      for (final seg in segments) {
        final pm = _phoneRe.firstMatch(seg);
        if (pm == null) continue;
        final num = _normPhone(pm.group(0)!);
        final label = _labelRe.firstMatch(seg)?.group(1)?.toLowerCase() ?? '';
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
      if (any) consumed[i] = true;
    }

    // 3) 주소
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      final am = _addressRe.firstMatch(lines[i]);
      if (am != null && card.address.isEmpty) {
        card.address = lines[i].replaceFirst(RegExp(r'^(주소|address|a)\s*[:.]?\s*', caseSensitive: false), '').trim();
        consumed[i] = true;
      }
    }

    // 4) 직책 + 이름 (같은 줄 또는 인접 줄)
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      final tokens = lines[i].split(RegExp(r'[\s/|,]+')).where((t) => t.isNotEmpty).toList();
      final titleIdx = tokens.indexWhere((t) => titles.contains(t.toLowerCase()) || titles.any((x) => t.toLowerCase().endsWith(x) && t.length <= x.length + 1));
      if (titleIdx < 0) continue;
      card.title = tokens[titleIdx];
      final rest = [...tokens]..removeAt(titleIdx);
      final nameTok = rest.where((t) => _koreanName.hasMatch(t)).toList();
      if (nameTok.isNotEmpty) {
        card.name = nameTok.first;
      } else {
        // 인접 줄에서 2~4자 한글 단독 토큰
        for (final j in [i - 1, i + 1]) {
          if (j < 0 || j >= lines.length || consumed[j]) continue;
          if (_koreanName.hasMatch(lines[j])) {
            card.name = lines[j];
            consumed[j] = true;
            break;
          }
        }
      }
      // 부서: 직책 줄의 나머지 한글 토큰(이름 제외) 중 "팀/부/실/본부/센터" 포함
      final dept = rest.where((t) => t != card.name && RegExp(r'(팀|부|실|본부|센터|사업|개발|영업|연구소|그룹)$').hasMatch(t)).toList();
      if (dept.isNotEmpty) card.department = dept.first;
      consumed[i] = true;
      break;
    }

    // 4.5) 부서: 팀/과/실/본부/센터… 로 끝나는 줄 (회사보다 먼저 가려낸다)
    if (card.department.isEmpty) {
      for (var i = 0; i < lines.length; i++) {
        if (consumed[i]) continue;
        if (_deptRe.hasMatch(lines[i]) && lines[i] != card.name) {
          card.department = lines[i];
          consumed[i] = true;
          break;
        }
      }
    }

    // 5) 회사: 접두/접미 패턴 > 최상단 미소비 줄
    for (var i = 0; i < lines.length; i++) {
      if (consumed[i]) continue;
      if (_companySuffix.hasMatch(lines[i]) && lines[i] != card.name) {
        card.company = lines[i];
        consumed[i] = true;
        break;
      }
    }
    if (card.company.isEmpty) {
      final first = lines.indexWhere((l) => !consumed[lines.indexOf(l)] && !_koreanName.hasMatch(l) && l.length <= 30);
      if (first >= 0) {
        card.company = lines[first];
        consumed[first] = true;
        card.lowConfidence.add('company');
      }
    }

    // 6) 이름이 비었으면 미소비 줄 중 2~4자 한글
    if (card.name.isEmpty) {
      for (var i = 0; i < lines.length; i++) {
        if (consumed[i]) continue;
        if (_koreanName.hasMatch(lines[i])) {
          card.name = lines[i];
          consumed[i] = true;
          card.lowConfidence.add('name');
          break;
        }
      }
    }
    for (final f in ['name', 'company']) {
      final v = f == 'name' ? card.name : card.company;
      if (v.isEmpty) card.lowConfidence.add(f);
    }
    if (card.title.isEmpty) card.lowConfidence.add('title');
    if (card.department.isEmpty) card.lowConfidence.add('department');
    return card;
  }

  static bool _isFax(String l) => l.startsWith('f') || l == '팩스';
  static bool _isMobile(String l) => ['m', 'mobile', 'hp', 'h.p', 'c', 'cell', '휴대', '핸드폰'].contains(l);

  /// 010-1234-5678 / 02-555-0123 형태로 정규화. +82 → 0.
  static String _normPhone(String s) {
    var d = s.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+82')) d = '0${d.substring(3)}';
    d = d.replaceAll('+', '');
    if (d.startsWith('02')) {
      if (d.length == 9) return '02-${d.substring(2, 5)}-${d.substring(5)}';
      if (d.length == 10) return '02-${d.substring(2, 6)}-${d.substring(6)}';
    }
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
