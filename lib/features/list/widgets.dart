import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/contact_repo.dart';
import '../../data/db.dart';
import 'list_screen.dart';

/// 목록 행. 메모가 있으면 3줄(높이 [heightWithSub]), 없으면 2줄([heightPlain]) — 인덱스 점프 계산용 고정 높이.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onThumbTap,
    required this.onCall,
    this.onCallLong,
    this.hint,
    this.indent = false,
    this.onLongPress,
    this.selecting = false,
    this.selected = false,
  });
  final Contact contact;
  final String? hint;
  final VoidCallback onTap;
  final VoidCallback onThumbTap;
  final VoidCallback onCall;
  final VoidCallback? onCallLong;
  final bool indent;
  /// 꾹 누르면 선택 모드 진입
  final VoidCallback? onLongPress;
  /// 선택 모드: 썸네일 자리에 체크, 전화 버튼 숨김, 행 탭은 토글
  final bool selecting;
  final bool selected;

  static const double heightPlain = 66;
  static const double heightWithSub = 88;
  static double heightOf(Contact c, {String? hint}) => (hint != null || c.memo.isNotEmpty) ? heightWithSub : heightPlain;

  @override
  Widget build(BuildContext context) {
    final memo = contact.memo;
    final sub = hint ?? (memo.isNotEmpty ? memo : null);
    final subIsHint = hint != null;
    return Container(
      height: heightOf(contact, hint: hint),
      margin: indent ? const EdgeInsets.only(left: 14) : null,
      padding: const EdgeInsets.all(8.5), // + 1.5 테두리 = 10
      decoration: BoxDecoration(
        color: selected ? C.accentTint : C.surface,
        borderRadius: BorderRadius.circular(R.row),
        boxShadow: rowShadow,
        border: Border.all(color: selected ? C.accent : Colors.transparent, width: 1.5),
      ),
      child: Row(
        children: [
          if (selecting)
            GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: 64, height: 40,
                child: Center(
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? C.accent : Colors.transparent,
                      border: Border.all(color: selected ? C.accent : C.inkFaint, width: 2),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                  ),
                ),
              ),
            )
          else
            Semantics(
              button: true, label: '명함 이미지 보기',
              child: GestureDetector(onTap: onThumbTap, onLongPress: onLongPress, child: CardThumb(contact: contact)),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onLongPress: selecting ? null : onLongPress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(indent ? (contact.department.isEmpty ? ' ' : contact.department) : (contact.company.isEmpty ? '소속 없음' : contact.company),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.inkMuted)),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: contact.name.isEmpty ? '이름 없음' : contact.name, style: Theme.of(context).textTheme.titleMedium),
                      if (contact.title.isNotEmpty)
                        TextSpan(text: '  ${contact.title}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.inkMuted)),
                    ]),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(subIsHint ? Icons.search_rounded : Icons.edit_outlined, size: 12, color: subIsHint ? C.inkFaint : C.accent),
                      const SizedBox(width: 5),
                      Expanded(child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: subIsHint ? C.inkMuted : C.memoListInk))),
                    ]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!selecting)
            Semantics(
              button: true, label: '${contact.name}에게 전화',
              child: GestureDetector(
                onTap: contact.primaryPhone.isEmpty ? null : onCall,
                onLongPress: onCallLong,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: contact.primaryPhone.isEmpty ? C.line : C.callTint, shape: BoxShape.circle),
                  child: Icon(Icons.call, size: 20, color: contact.primaryPhone.isEmpty ? C.inkFaint : C.callInk),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SortChip extends StatelessWidget {
  const SortChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? C.ink : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? C.ink : Colors.white.withValues(alpha: 0.9)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? Colors.white : C.ink)),
      ),
    );
  }
}

class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true, label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [BoxShadow(color: C.ink.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 22, color: C.ink),
        ),
      ),
    );
  }
}

/// 상세·입력 공용: 라벨 + 값 한 줄
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.label, required this.value, this.warn = false, this.trailing, this.onTap, this.last = false});
  final String label;
  final String value;
  final bool warn;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: warn ? C.warnBg : null,
          border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFE9EBEF))),
        ),
        child: Row(children: [
          SizedBox(width: 72, child: Text(label, style: TextStyle(fontSize: 13, color: warn ? C.warnInk : C.inkMuted))),
          Expanded(
            child: Text(
              warn && empty ? '인식 불확실 · 탭해서 수정' : (empty ? '—' : value),
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: value.length > 20 ? 15 : 16, fontWeight: FontWeight.w500, color: warn ? C.warnInk : (empty ? C.inkFaint : C.ink)),
            ),
          ),
          if (trailing != null && !empty) ...[const SizedBox(width: 8), trailing!],
          if (warn) const Icon(Icons.chevron_right_rounded, size: 18, color: C.warnInk),
        ]),
      ),
    );
  }
}

class SmallActionButton extends StatelessWidget {
  const SmallActionButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true, label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, size: 18, color: C.accent)),
      ),
    );
  }
}

/// 섹션 구분 헤더 (월 · 초성 · 즐겨찾기)
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label});
  final String label;
  static const double height = 30;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Row(children: [
              if (label == '즐겨찾기') const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.star_rounded, size: 14, color: C.accent)),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.inkMuted, letterSpacing: 0.2)),
            ]),
          ),
        ),
      );
}

/// 회사 트리 헤더: 탭하면 접었다 펴기, 별로 회사 즐겨찾기.
class CompanyHeader extends StatelessWidget {
  const CompanyHeader({super.key, required this.name, required this.count, required this.expanded, required this.favorite, required this.onTap, required this.onStar});
  final String name;
  final int count;
  final bool expanded;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onStar;
  static const double height = 52;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: expanded ? C.ink : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(R.row),
          border: Border.all(color: expanded ? C.ink : Colors.white.withValues(alpha: 0.9)),
        ),
        child: Row(children: [
          AnimatedRotation(
            turns: expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 150),
            child: Icon(Icons.chevron_right_rounded, size: 22, color: expanded ? Colors.white70 : C.inkMuted),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: expanded ? Colors.white : C.ink))),
          Text('$count명', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: expanded ? Colors.white70 : C.inkMuted)),
          IconButton(
            onPressed: onStar,
            tooltip: favorite ? '회사 즐겨찾기 해제' : '회사 즐겨찾기',
            icon: Icon(favorite ? Icons.star_rounded : Icons.star_outline_rounded, size: 22, color: favorite ? const Color(0xFFF5B301) : (expanded ? Colors.white54 : C.inkFaint)),
          ),
        ]),
      ),
    );
  }
}

/// 이름순 인덱스 바 (ㄱ~ㅎ·A~Z·#). 드래그/탭으로 점프.
class IndexBar extends StatelessWidget {
  const IndexBar({super.key, required this.keys, required this.onSelect});
  final List<String> keys;
  final ValueChanged<String> onSelect;

  void _hit(Offset local, double itemH) {
    final i = (local.dy / itemH).floor().clamp(0, keys.length - 1);
    onSelect(keys[i]);
  }

  @override
  Widget build(BuildContext context) {
    if (keys.isEmpty) return const SizedBox.shrink();
    const itemH = 17.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _hit(d.localPosition, itemH),
      onVerticalDragUpdate: (d) => _hit(d.localPosition, itemH),
      child: Container(
        width: 24,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in keys)
              SizedBox(height: itemH, child: Center(child: Text(k, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: C.accent)))),
          ],
        ),
      ),
    );
  }
}



/// 파괴적 동작 확인 — 가운데 다이얼로그 대신 하단 시트 (손가락·시선이 아래에 머문다)
abstract final class ConfirmSheet {
  static Future<bool> show(BuildContext context, {required String title, String? message, String action = '삭제'}) async {
    final r = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + MediaQuery.paddingOf(ctx).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFD5D8DE), borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(ctx).textTheme.headlineMedium),
          if (message != null) ...[const SizedBox(height: 4), Text(message, style: const TextStyle(fontSize: 14, color: C.inkMuted))],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: C.danger, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(action, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF0F2F5), foregroundColor: C.ink, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('취소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
    return r == true;
  }
}

/// 행을 왼쪽으로 살짝 밀면 오른쪽에 삭제 버튼이 드러난다 (iOS 메일식). 끝까지 밀어도 자동 삭제는 안 함.
class SwipeReveal extends StatefulWidget {
  const SwipeReveal({super.key, required this.child, required this.open, required this.onOpenChanged, required this.onDelete, this.actionWidth = 84});
  final Widget child;
  /// 외부에서 관리하는 열림 상태 (한 번에 한 행만)
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onDelete;
  final double actionWidth;
  @override
  State<SwipeReveal> createState() => _SwipeRevealState();
}

class _SwipeRevealState extends State<SwipeReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: widget.open ? 1 : 0);
  double _dragStart = 0;

  @override
  void didUpdateWidget(covariant SwipeReveal old) {
    super.didUpdateWidget(old);
    if (old.open != widget.open) widget.open ? _c.forward() : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onStart(DragStartDetails d) => _dragStart = _c.value;
  void _onUpdate(DragUpdateDetails d) => _c.value = (_c.value - d.primaryDelta! / widget.actionWidth).clamp(0.0, 1.0);
  void _onEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final open = v < -200 ? true : v > 200 ? false : _c.value > 0.5;
    if (open != widget.open) {
      widget.onOpenChanged(open);
    } else {
      open ? _c.forward() : _c.reverse();
    }
    if (open && _dragStart < 0.5) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onStart,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final dx = -widget.actionWidth * _c.value;
          return ClipRect(child: Stack(children: [
            // 뒤에 깔리는 삭제 버튼 (행 높이에 맞춰 늘어남)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: IgnorePointer(
                  ignoring: _c.value < 0.5,
                  child: Opacity(
                  opacity: _c.value.clamp(0, 1),
                  child: Semantics(
                    button: true, label: '삭제',
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: widget.actionWidth - 10,
                        decoration: BoxDecoration(color: C.danger, borderRadius: BorderRadius.circular(R.row)),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                          SizedBox(height: 2),
                          Text('삭제', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ),
            Transform.translate(offset: Offset(dx, 0), child: child),
          ]));
        },
        child: widget.child,
      ),
    );
  }
}

/// 가벼운 토스트 — 하단 독 위에 떠서 1.6초 뒤 스르륵 사라진다.
abstract final class Toast {
  static OverlayEntry? _entry;
  static void show(BuildContext context, String text, {IconData icon = Icons.check_rounded}) {
    _entry?.remove();
    _entry = null;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final bottom = MediaQuery.paddingOf(context).bottom;
    late OverlayEntry e;
    e = OverlayEntry(builder: (_) => _ToastView(text: text, icon: icon, bottom: 86 + bottom, onDone: () { if (_entry == e) _entry = null; e.remove(); }));
    _entry = e;
    overlay.insert(e);
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.text, required this.icon, required this.bottom, required this.onDone});
  final String text;
  final IconData icon;
  final double bottom;
  final VoidCallback onDone;
  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), reverseDuration: const Duration(milliseconds: 400));
  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1600), () async {
      if (!mounted) return;
      await _c.reverse();
      if (mounted) widget.onDone();
    });
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    return Positioned(
      left: 0, right: 0, bottom: widget.bottom,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 40, padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: C.ink.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20), boxShadow: dockShadow),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(widget.icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
