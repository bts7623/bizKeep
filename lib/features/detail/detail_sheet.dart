import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/actions.dart';
import '../../core/image_paths.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/contact_repo.dart';
import '../../data/db.dart';
import '../edit/edit_screen.dart';
import '../list/widgets.dart';
import 'card_view_screen.dart';

/// 상세 바텀시트. 이미 저장된 데이터를 보여준다 (확인-저장 구조 아님).
class DetailSheet extends ConsumerStatefulWidget {
  const DetailSheet({super.key, required this.contactId, this.justSaved = false});
  final String contactId;
  final bool justSaved;

  /// 반환: 'next' 면 사용자가 "다음 명함" 을 눌러 바로 촬영을 이어가길 원함.
  static Future<String?> show(BuildContext context, String id, {bool justSaved = false}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: C.ink.withValues(alpha: 0.42),
      builder: (_) => DetailSheet(contactId: id, justSaved: justSaved),
    );
  }

  @override
  ConsumerState<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends ConsumerState<DetailSheet> {
  late String _id = widget.contactId;
  Contact? _dup; // 촬영 직후 같은 사람이 이미 있으면
  bool _dupChecked = false;
  bool _dupDismissed = false;

  @override
  void initState() {
    super.initState();
    if (widget.justSaved) _checkDup();
  }

  Future<void> _checkDup() async {
    final repo = ref.read(repoProvider);
    final me = await repo.get(_id);
    if (me == null) return;
    final d = await repo.findDuplicate(me);
    if (mounted) setState(() { _dup = d; _dupChecked = true; });
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(contactsProvider).value?.where((c) => c.id == _id).firstOrNull;
    if (contact == null) return const SizedBox.shrink();
    final dup = (_dupChecked && !_dupDismissed) ? _dup : null;
    final low = contact.lowConfidenceFields.toSet();
    final h = MediaQuery.sizeOf(context).height;

    return Container(
      height: h * 0.92,
      decoration: const BoxDecoration(color: C.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFD5D8DE), borderRadius: BorderRadius.circular(3))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 0),
            child: Row(children: [
              if (widget.justSaved)
                Container(
                  height: 28, padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: C.callTint, borderRadius: BorderRadius.circular(14)),
                  child: const Row(children: [
                    Icon(Icons.check_rounded, size: 14, color: C.callInk),
                    SizedBox(width: 6),
                    Text('저장됨 · 방금', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.callInk)),
                  ]),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => ref.read(repoProvider).setFavorite(contact.id, !contact.favorite),
                tooltip: contact.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                icon: Icon(contact.favorite ? Icons.star_rounded : Icons.star_outline_rounded, color: contact.favorite ? const Color(0xFFF5B301) : C.inkMuted, size: 26),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: C.inkMuted), tooltip: '닫기'),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              children: [
                if (dup != null) ...[
                  _DupBanner(old: dup, fresh: contact, onTap: () => _resolveDup(context, dup, contact), onDismiss: () => setState(() => _dupDismissed = true)),
                  const SizedBox(height: 12),
                ],
                _CardArea(contact: contact),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(contact.name.isEmpty ? '이름 없음' : contact.name, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text([contact.company, contact.title].where((s) => s.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 15, color: C.inkMuted)),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Semantics(
                    button: true, label: '휴대전화로 전화 걸기',
                    child: GestureDetector(
                      onTap: contact.primaryPhone.isEmpty ? null : () => Act.call(contact.primaryPhone),
                      onLongPress: contact.phoneOffice.isEmpty ? null : () => Act.call(contact.phoneOffice),
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: contact.primaryPhone.isEmpty ? C.line : C.call, shape: BoxShape.circle,
                          boxShadow: contact.primaryPhone.isEmpty ? null : [BoxShadow(color: C.call.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Icon(Icons.call, color: contact.primaryPhone.isEmpty ? C.inkFaint : Colors.white, size: 28),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _MemoField(contact: contact),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(R.box)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    FieldRow(label: '휴대전화', value: contact.phoneMobile, warn: low.contains('phoneMobile'),
                        trailing: SmallActionButton(icon: Icons.chat_bubble_outline_rounded, label: '문자 보내기', onTap: () => Act.sms(contact.phoneMobile)),
                        onTap: () => Act.copy(contact.phoneMobile)),
                    FieldRow(label: '사무실', value: contact.phoneOffice,
                        trailing: SmallActionButton(icon: Icons.call_outlined, label: '사무실로 전화', onTap: () => Act.call(contact.phoneOffice)),
                        onTap: () => Act.copy(contact.phoneOffice)),
                    FieldRow(label: '이메일', value: contact.email,
                        trailing: SmallActionButton(icon: Icons.mail_outline_rounded, label: '메일 보내기', onTap: () => Act.mail(contact.email)),
                        onTap: () => Act.copy(contact.email)),
                    FieldRow(label: '부서', value: contact.department, warn: low.contains('department'), onTap: () => _edit(context, contact)),
                    FieldRow(label: '직책', value: contact.title, warn: low.contains('title'), onTap: () => _edit(context, contact)),
                    FieldRow(label: '주소', value: contact.address,
                        trailing: SmallActionButton(icon: Icons.place_outlined, label: '지도에서 보기', onTap: () => Act.map(contact.address)),
                        onTap: () => Act.copy(contact.address)),
                    if (contact.fax.isNotEmpty) FieldRow(label: '팩스', value: contact.fax),
                    FieldRow(label: '웹', value: contact.website, last: true, onTap: contact.website.isEmpty ? null : () => Act.web(contact.website)),
                  ]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
            child: Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _edit(context, contact),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF0F2F5), foregroundColor: C.ink, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              if (widget.justSaved)
                // 촬영 직후: 메모 적고 바로 다음 명함 (연속 등록)
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, 'next'),
                    style: FilledButton.styleFrom(backgroundColor: C.ink, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text('다음 명함', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                )
              else
                SizedBox(
                  width: 52, height: 52,
                  child: FilledButton(
                    onPressed: () => _delete(context, contact),
                    style: FilledButton.styleFrom(backgroundColor: C.dangerTint, foregroundColor: C.danger, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Icon(Icons.delete_outline_rounded, size: 22),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  /// 중복 처리: 달라진 게 없으면 바로 새 레코드 삭제, 있으면 비교 시트.
  Future<void> _resolveDup(BuildContext context, Contact old, Contact fresh) async {
    final diffs = ContactRepo.diffFields(old, fresh);
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      builder: (_) => _CompareSheet(old: old, fresh: fresh, diffs: diffs),
    );
    if (!context.mounted || choice == null || choice == 'keep') {
      if (choice == 'keep' && mounted) setState(() => _dupDismissed = true);
      return;
    }
    final repo = ref.read(repoProvider);
    if (choice == 'replace') {
      final oldImages = await repo.replaceWith(old: old, fresh: fresh);
      for (final p in oldImages) {
        try { await File(ImagePaths.resolve(p)).delete(); } catch (_) {}
      }
    } else if (choice == 'drop') {
      for (final p in [fresh.imageFront, fresh.imageBack, fresh.thumb]) {
        if (p != null) { try { await File(ImagePaths.resolve(p)).delete(); } catch (_) {} }
      }
      await repo.delete(fresh.id);
    }
    if (mounted) setState(() { _id = old.id; _dup = null; });
  }

  void _edit(BuildContext context, Contact c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditScreen(existing: c), fullscreenDialog: true));
  }

  Future<void> _delete(BuildContext context, Contact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${c.name.isEmpty ? '이 연락처' : c.name} 삭제'),
        content: const Text('명함 이미지도 함께 삭제돼요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: C.danger), child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) {
      for (final p in [c.imageFront, c.imageBack, c.thumb]) {
        if (p != null) {
          try { await File(ImagePaths.resolve(p)).delete(); } catch (_) {}
        }
      }
      await ref.read(repoProvider).delete(c.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _CardArea extends StatelessWidget {
  const _CardArea({required this.contact});
  final Contact contact;
  @override
  Widget build(BuildContext context) {
    final img = contact.imageFront == null ? null : ImagePaths.resolve(contact.imageFront!);
    return GestureDetector(
      onTap: img == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardViewScreen(contactId: contact.id), fullscreenDialog: true)),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(R.box),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E2A44), Color(0xFF0F1524)]),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Center(
            child: img != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(img), height: 121, fit: BoxFit.contain))
                : const Text('명함 이미지 없음', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          if (img != null)
            Positioned(
              right: 12, bottom: 12,
              child: Container(
                height: 30, padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                child: const Row(children: [
                  Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('크게 보기', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

/// 한 줄 메모 — 탭하면 그 자리에서 편집, 포커스 아웃 시 자동 저장.
class _MemoField extends ConsumerStatefulWidget {
  const _MemoField({required this.contact});
  final Contact contact;
  @override
  ConsumerState<_MemoField> createState() => _MemoFieldState();
}

class _MemoFieldState extends ConsumerState<_MemoField> {
  late final TextEditingController _c = TextEditingController(text: widget.contact.memo);
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) _save();
    });
  }

  @override
  void didUpdateWidget(covariant _MemoField old) {
    super.didUpdateWidget(old);
    if (!_f.hasFocus && old.contact.memo != widget.contact.memo) _c.text = widget.contact.memo;
  }

  Future<void> _save() async {
    final v = _c.text.trim();
    if (v != widget.contact.memo) await ref.read(repoProvider).updateMemo(widget.contact.id, v);
  }

  @override
  void dispose() {
    _save();
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: C.memoBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.memoBorder)),
      child: Row(children: [
        const Icon(Icons.edit_outlined, size: 18, color: C.accent),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _c, focusNode: _f, maxLength: 40, maxLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _f.unfocus(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: C.memoInk),
            decoration: const InputDecoration(counterText: '', hintText: '한 줄 메모 (담당 업무, 만난 자리 등)', hintStyle: TextStyle(color: C.inkFaint, fontWeight: FontWeight.w400)),
          ),
        ),
      ]),
    );
  }
}

/// 촬영 직후 "이미 있는 사람" 배너
class _DupBanner extends StatelessWidget {
  const _DupBanner({required this.old, required this.fresh, required this.onTap, required this.onDismiss});
  final Contact old;
  final Contact fresh;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(old.createdAt);
    final same = ContactRepo.diffFields(old, fresh).isEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(color: C.warnBg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.people_alt_outlined, size: 20, color: C.warnInk),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${old.name.isEmpty ? '이 사람' : old.name} 님이 이미 있어요', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.warnInk)),
              const SizedBox(height: 1),
              Text(same ? '똑같은 명함이에요 · 탭해서 정리' : '${d.year}.${d.month} 등록 · 탭해서 비교', style: const TextStyle(fontSize: 12, color: C.warnInk)),
            ]),
          ),
          IconButton(onPressed: onDismiss, icon: const Icon(Icons.close_rounded, size: 18, color: C.warnInk), tooltip: '닫기'),
        ]),
      ),
    );
  }
}

/// 기존 ↔ 새 명함 비교. 달라진 필드만. 반환: replace / drop / keep
class _CompareSheet extends StatelessWidget {
  const _CompareSheet({required this.old, required this.fresh, required this.diffs});
  final Contact old;
  final Contact fresh;
  final List<(String, String, String)> diffs;
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final same = diffs.isEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFD5D8DE), borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 16),
        Text(same ? '똑같은 명함이에요' : '달라진 정보 ${diffs.length}개', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(same ? '방금 등록한 것을 지우고 기존 연락처를 그대로 둘게요.' : '교체하면 기존 메모·즐겨찾기는 그대로 두고 정보와 명함 이미지만 새것으로 바꿔요.',
            style: const TextStyle(fontSize: 14, color: C.inkMuted)),
        if (!same) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(R.box)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, d) in diffs.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: i == diffs.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFE9EBEF)))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 64, child: Text(d.$1, style: const TextStyle(fontSize: 13, color: C.inkMuted))),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.$2.isEmpty ? '—' : d.$2, style: const TextStyle(fontSize: 14, color: C.inkFaint, decoration: TextDecoration.lineThrough)),
                        const SizedBox(height: 2),
                        Text(d.$3.isEmpty ? '—' : d.$3, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.ink)),
                      ]),
                    ),
                  ]),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, 'keep'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF0F2F5), foregroundColor: C.ink, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('따로 둘게요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, same ? 'drop' : 'replace'),
              style: FilledButton.styleFrom(backgroundColor: C.ink, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(same ? '중복 삭제' : '새 명함으로 교체', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}
