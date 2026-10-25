import 'package:flutter/material.dart';

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
  });
  final Contact contact;
  final String? hint;
  final VoidCallback onTap;
  final VoidCallback onThumbTap;
  final VoidCallback onCall;
  final VoidCallback? onCallLong;
  final bool indent;

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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(R.row), boxShadow: rowShadow),
      child: Row(
        children: [
          Semantics(
            button: true, label: '명함 이미지 보기',
            child: GestureDetector(onTap: onThumbTap, child: CardThumb(contact: contact)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
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

class GlassMenuCard extends StatelessWidget {
  const GlassMenuCard({super.key, required this.icon, required this.dark, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final bool dark;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white),
          boxShadow: [BoxShadow(color: C.ink.withValues(alpha: 0.22), blurRadius: 32, offset: const Offset(0, 12))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: dark ? C.ink : C.line, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: dark ? Colors.white : C.ink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.ink)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: C.inkMuted)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.inkFaint),
        ]),
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
