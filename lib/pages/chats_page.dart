import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'chat_room_page.dart';

/// รายการแชท (แบบ IG: ช่องค้นหา + ข้อความล่าสุด + เวลา)
class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  String q = '';

  String _preview(AppState s, Message? m) {
    if (m == null) return 'เริ่มแชทเลย';
    final mine = m.senderId == s.me!.id ? 'คุณ: ' : '';
    final body = m.imageUrl != null && m.body.isEmpty
        ? '📷 รูปภาพ'
        : m.postId != null
            ? '📎 แชร์โพสต์'
            : m.body;
    return '$mine$body';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.chats.where((c) {
      final u = s.pf(c.otherId);
      final t = q.trim().toLowerCase();
      return t.isEmpty || u.name.toLowerCase().contains(t) || u.username.contains(t);
    }).toList()
      ..sort((a, b) => (b.last?.createdAt ?? b.createdAt).compareTo(a.last?.createdAt ?? a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('ข้อความ')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'ค้นหา',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? EmptyState(q.isEmpty ? 'ยังไม่มีแชท\nแมตช์กับเพื่อนในหน้า Friends เพื่อเริ่มแชท' : 'ไม่พบแชท')
              : RefreshIndicator(
                  onRefresh: () => s.reload(['chats']),
                  child: ListView(children: [
                    for (final c in list)
                      ListTile(
                        leading: Avatar(s.pf(c.otherId), radius: 26),
                        title: Text(s.pf(c.otherId).name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${_preview(s, c.last)}${c.last != null ? ' · ${shortTime(c.last!.createdAt)}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: c.id)),
                        ),
                      ),
                  ]),
                ),
        ),
      ]),
    );
  }
}
