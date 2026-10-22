import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../edit/edit_screen.dart';

/// 1단계 자리표시자: 2단계에서 camera + ML Kit OCR → 즉시 저장으로 교체.
/// 지금은 "직접 입력"으로 안내.
class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white), tooltip: '닫기'),
          ]),
          const Spacer(),
          const Icon(Icons.photo_camera_outlined, color: Colors.white54, size: 56),
          const SizedBox(height: 16),
          const Text('카메라 촬영은 2단계에서 켜져요', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('지금은 직접 입력으로 등록해 주세요', style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 13)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton(
              onPressed: () async {
                final id = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const EditScreen(), fullscreenDialog: true));
                if (context.mounted) Navigator.pop(context, id);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: C.ink, minimumSize: const Size.fromHeight(54), shape: const StadiumBorder()),
              child: const Text('직접 입력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
