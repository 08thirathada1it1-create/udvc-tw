import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import 'common.dart';

/// แชร์โพสต์: ลงสตอรี่ / ส่งให้เพื่อนในแชท / คัดลอกข้อความ
Future<void> showShareSheet(BuildContext context, Post post) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ShareSheet(post: post),
  );
}

class _ShareSheet extends StatefulWidget {
  final Post post;
  const _ShareSheet({required this.post});
  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final sent = <String>{};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = widget.post;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          Text('แชร์', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.auto_stories),
            title: const Text('เพิ่มลงสตอรี่ของคุณ'),
            onTap: () async {
              if (p.imageUrl == null) {
                snack(context, 'โพสต์นี้ไม่มีรูปภาพ แชร์ลงสตอรี่ไม่ได้');
                return;
              }
              final nav = Navigator.of(context);
              final ok = await guard(context, () => s.shareToStory(p), ok: 'เพิ่มลงสตอรี่แล้ว');
              if (ok) nav.pop();
            },
          ),
          const Divider(),
          const Text('ส่งให้เพื่อน', style: TextStyle(fontWeight: FontWeight.bold)),
          if (s.chats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('ยังไม่มีเพื่อนในแชท แมตช์ในหน้า Friends ก่อน'),
            ),
          for (final c in s.chats)
            ListTile(
              leading: Avatar(s.pf(c.otherId)),
              title: Text(s.pf(c.otherId).name),
              trailing: OutlinedButton(
                onPressed: sent.contains(c.id)
                    ? null
                    : () async {
                        final ok = await guard(context, () => s.sendPostToChat(c.id, p));
                        if (ok && mounted) setState(() => sent.add(c.id));
                      },
                child: Text(sent.contains(c.id) ? 'ส่งแล้ว ✓' : 'ส่ง'),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('คัดลอกข้อความ'),
            onTap: () => copyText(context, '${p.caption} #UDVCTW'),
          ),
        ]),
      ),
    );
  }
}
