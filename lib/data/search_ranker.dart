/// 검색 가중치·우선순위 (순수 Dart — 테스트 대상).
///
/// 규칙 (docs/spec.md §4)
/// - 입력 ≤2글자: 이름·회사만. ≥3글자: 전 필드.
/// - 숫자로 시작 → 번호 우선. '@' 포함 → 이메일 우선.
/// - 가중치: 이름 완전일치 100 > 이름 prefix 80 > 회사 60 > 직책/부서 40
///   > 번호·메일 30 > 주소·메모 20 > OCR 원문 10. 동점은 최근 등록순.
library;

enum MatchField { name, company, department, title, phone, email, address, memo, ocr }

class SearchDoc {
  final String id;
  final String name;
  final String company;
  final String department;
  final String title;
  final String phoneMobile;
  final String phoneOffice;
  final String email;
  final String address;
  final String memo;
  final String ocrRaw;
  final int createdAt;

  const SearchDoc({
    required this.id,
    this.name = '',
    this.company = '',
    this.department = '',
    this.title = '',
    this.phoneMobile = '',
    this.phoneOffice = '',
    this.email = '',
    this.address = '',
    this.memo = '',
    this.ocrRaw = '',
    this.createdAt = 0,
  });
}

class SearchHit {
  final SearchDoc doc;
  final int score;
  final MatchField field;

  /// 이름·회사 외 필드에서 걸렸을 때만 목록에 보여줄 힌트. 예: "주소 · 강남구 테헤란로"
  final String? hint;

  const SearchHit(this.doc, this.score, this.field, this.hint);
}

enum QueryKind { text, phone, email }

class SearchQuery {
  final String raw;
  final String norm; // 소문자, 앞뒤 공백 제거
  final String digits; // 숫자만
  final QueryKind kind;
  final bool allFields;

  SearchQuery._(this.raw, this.norm, this.digits, this.kind, this.allFields);

  factory SearchQuery.parse(String input) {
    final norm = input.trim().toLowerCase();
    final digits = norm.replaceAll(RegExp(r'[^0-9]'), '');
    QueryKind kind = QueryKind.text;
    if (norm.isNotEmpty && RegExp(r'^[0-9+\-\s()]+$').hasMatch(norm) && digits.isNotEmpty) {
      kind = QueryKind.phone;
    } else if (norm.contains('@')) {
      kind = QueryKind.email;
    }
    final allFields = kind != QueryKind.text || _charLen(norm) >= 3;
    return SearchQuery._(input, norm, digits, kind, allFields);
  }

  static int _charLen(String s) => s.runes.length;
}

const _fieldLabel = {
  MatchField.department: '부서',
  MatchField.title: '직책',
  MatchField.phone: '번호',
  MatchField.email: '메일',
  MatchField.address: '주소',
  MatchField.memo: '메모',
  MatchField.ocr: '명함',
};

class SearchRanker {
  const SearchRanker();

  List<SearchHit> rank(String input, Iterable<SearchDoc> docs, {int limit = 200}) {
    final q = SearchQuery.parse(input);
    if (q.norm.isEmpty) return const [];
    final hits = <SearchHit>[];
    for (final d in docs) {
      final h = score(q, d);
      if (h != null) hits.add(h);
    }
    hits.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : b.doc.createdAt.compareTo(a.doc.createdAt);
    });
    return hits.length > limit ? hits.sublist(0, limit) : hits;
  }

  /// null이면 미일치.
  SearchHit? score(SearchQuery q, SearchDoc d) {
    final n = q.norm;
    int best = 0;
    MatchField? field;
    String? hintText;

    void consider(int s, MatchField f, [String? h]) {
      if (s > best) {
        best = s;
        field = f;
        hintText = h;
      }
    }

    if (q.kind == QueryKind.phone) {
      final m = _digits(d.phoneMobile);
      final o = _digits(d.phoneOffice);
      if (m.contains(q.digits)) consider(m.startsWith(q.digits) ? 90 : 70, MatchField.phone, d.phoneMobile);
      if (o.contains(q.digits)) consider(o.startsWith(q.digits) ? 85 : 65, MatchField.phone, d.phoneOffice);
      if (best == 0) return null;
      return SearchHit(d, best, field!, _hint(field!, hintText));
    }

    if (q.kind == QueryKind.email) {
      final e = d.email.toLowerCase();
      if (e.contains(n)) consider(e.startsWith(n) ? 90 : 70, MatchField.email, d.email);
      if (best == 0) return null;
      return SearchHit(d, best, field!, _hint(field!, hintText));
    }

    // 텍스트 검색
    final name = d.name.toLowerCase();
    if (name == n) {
      consider(100, MatchField.name);
    } else if (name.startsWith(n)) {
      consider(80, MatchField.name);
    } else if (name.contains(n)) {
      consider(70, MatchField.name);
    }
    final company = d.company.toLowerCase();
    if (company.startsWith(n)) {
      consider(60, MatchField.company);
    } else if (company.contains(n)) {
      consider(55, MatchField.company);
    }

    if (q.allFields) {
      if (d.title.toLowerCase().contains(n)) consider(40, MatchField.title, d.title);
      if (d.department.toLowerCase().contains(n)) consider(40, MatchField.department, d.department);
      if (d.email.toLowerCase().contains(n)) consider(30, MatchField.email, d.email);
      if (q.digits.isNotEmpty &&
          (_digits(d.phoneMobile).contains(q.digits) || _digits(d.phoneOffice).contains(q.digits))) {
        consider(30, MatchField.phone, d.phoneMobile.isNotEmpty ? d.phoneMobile : d.phoneOffice);
      }
      if (d.address.toLowerCase().contains(n)) consider(20, MatchField.address, _snippet(d.address, n));
      if (d.memo.toLowerCase().contains(n)) consider(20, MatchField.memo, _snippet(d.memo, n));
      if (d.ocrRaw.toLowerCase().contains(n)) consider(10, MatchField.ocr, _snippet(d.ocrRaw, n));
    }

    if (best == 0) return null;
    return SearchHit(d, best, field!, _hint(field!, hintText));
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  static String? _hint(MatchField f, String? text) {
    final label = _fieldLabel[f];
    if (label == null || text == null || text.isEmpty) return null;
    return '$label · $text';
  }

  /// 매칭 지점 주변 최대 18자.
  static String _snippet(String text, String needle) {
    final i = text.toLowerCase().indexOf(needle);
    if (i < 0) return text;
    final start = (i - 4).clamp(0, text.length);
    final end = (start + 18).clamp(0, text.length);
    final s = text.substring(start, end).replaceAll('\n', ' ');
    return (start > 0 ? '…' : '') + s + (end < text.length ? '…' : '');
  }
}
