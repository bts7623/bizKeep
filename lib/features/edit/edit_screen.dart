import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db.dart';

/// 직접 입력 / 수정. 섹션: 기본 → 한 줄 메모 → 연락처.
class EditScreen extends ConsumerStatefulWidget {
  const EditScreen({super.key, this.existing, this.prefill});
  final Contact? existing;
  /// OCR 결과 등 초기값 (신규일 때)
  final Map<String, String>? prefill;

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  late final Map<String, TextEditingController> _c;
  bool _saving = false;

  static const _keys = ['name', 'company', 'department', 'title', 'memo', 'phoneMobile', 'phoneOffice', 'email', 'address'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final p = widget.prefill ?? const {};
    _c = {
      for (final k in _keys)
        k: TextEditingController(text: e == null ? (p[k] ?? '') : switch (k) {
              'name' => e.name, 'company' => e.company, 'department' => e.department, 'title' => e.title,
              'memo' => e.memo, 'phoneMobile' => e.phoneMobile, 'phoneOffice' => e.phoneOffice,
              'email' => e.email, 'address' => e.address, _ => '',
            }),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave => _c['name']!.text.trim().isNotEmpty || _c['company']!.text.trim().isNotEmpty || _c['phoneMobile']!.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = ref.read(repoProvider);
    String v(String k) => _c[k]!.text.trim();
    final e = widget.existing;
    String id;
    if (e == null) {
      final c = await repo.create(
        name: v('name'), company: v('company'), department: v('department'), title: v('title'), memo: v('memo'),
        phoneMobile: v('phoneMobile'), phoneOffice: v('phoneOffice'), email: v('email'), address: v('address'),
        source: widget.prefill == null ? 'manual' : 'camera',
      );
      id = c.id;
    } else {
      await repo.update(e.copyWith(
        name: v('name'), company: v('company'), department: v('department'), title: v('title'), memo: v('memo'),
        phoneMobile: v('phoneMobile'), phoneOffice: v('phoneOffice'), email: v('email'), address: v('address'),
        lowConfidence: '[]',
      ));
      id = e.id;
    }
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Scaffold(
      backgroundColor: C.surface,
      appBar: AppBar(
        backgroundColor: C.surface, surfaceTintColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: C.inkMuted, fontSize: 16))),
        leadingWidth: 72,
        title: Text(isNew ? '새 연락처' : '수정', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: C.ink)),
        actions: [
          ListenableBuilder(
            listenable: Listenable.merge([_c['name'], _c['company'], _c['phoneMobile']]),
            builder: (_, __) => TextButton(
              onPressed: _canSave ? _save : null,
              child: Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _canSave ? C.accent : C.inkFaint)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _Section(title: '기본', children: [
            _Field(label: '이름', c: _c['name']!, autofocus: isNew && widget.prefill == null),
            _Field(label: '회사', c: _c['company']!),
            _Field(label: '부서', c: _c['department']!, hint: '예: 기술본부'),
            _Field(label: '직책', c: _c['title']!, last: true),
          ]),
          const SizedBox(height: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(left: 4, bottom: 10), child: Text('한 줄 메모', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.inkMuted))),
            Container(
              height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: C.memoBg, borderRadius: BorderRadius.circular(R.box), border: Border.all(color: C.memoBorder)),
              child: Row(children: [
                const Icon(Icons.edit_outlined, size: 18, color: C.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _c['memo'], maxLength: 40, maxLines: 1,
                    style: const TextStyle(fontSize: 16, color: C.memoInk),
                    decoration: const InputDecoration(counterText: '', hintText: '담당 업무, 만난 자리 등 (40자)', hintStyle: TextStyle(color: C.inkFaint, fontWeight: FontWeight.w400)),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: '연락처', children: [
            _Field(label: '휴대전화', c: _c['phoneMobile']!, type: TextInputType.phone),
            _Field(label: '사무실', c: _c['phoneOffice']!, type: TextInputType.phone),
            _Field(label: '이메일', c: _c['email']!, type: TextInputType.emailAddress),
            _Field(label: '주소', c: _c['address']!, last: true),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.inkMuted))),
        Container(
          decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(R.box)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ]);
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.c, this.hint, this.type, this.last = false, this.autofocus = false});
  final String label;
  final TextEditingController c;
  final String? hint;
  final TextInputType? type;
  final bool last;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => Container(
        height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFE9EBEF)))),
        child: Row(children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: C.inkMuted))),
          Expanded(
            child: TextField(
              controller: c, keyboardType: type, autofocus: autofocus, textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: C.ink),
              decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: C.inkFaint, fontWeight: FontWeight.w400)),
            ),
          ),
        ]),
      );
}
