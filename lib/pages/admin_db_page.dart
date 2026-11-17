import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// หน้าดูข้อมูลทั้งหมดในฐานข้อมูล (เฉพาะผู้ดูแลระบบ role = admin)
class AdminDbPage extends StatefulWidget {
  const AdminDbPage({super.key});
  @override
  State<AdminDbPage> createState() => _AdminDbPageState();
}

class _AdminDbPageState extends State<AdminDbPage> {
  String tab = 'users';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.isAdmin) {
      return Scaffold(appBar: AppBar(title: const Text('ฐานข้อมูล')), body: const EmptyState('เฉพาะผู้ดูแลระบบ'));
    }
    final users = s.profiles.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    Widget table;
    switch (tab) {
      case 'posts':
        table = _table(
          ['เวลา', 'ผู้โพสต์', 'ประเภท', 'ข้อความ', 'ถูกใจ', 'ความเห็น'],
          [
            for (final p in s.posts)
              [fmtDateTime(p.createdAt), '@${s.pf(p.authorId).username}', p.isStory ? 'สตอรี่' : 'โพสต์',
                p.caption.length > 40 ? p.caption.substring(0, 40) : p.caption, '${p.likes.length}', '${p.commentCount}'],
          ],
        );
        break;
      case 'products':
        table = _table(
          ['เวลา', 'ผู้ขาย', 'สินค้า', 'ราคา', 'หมวด', 'ติดต่อ'],
          [
            for (final m in s.products)
              [fmtDateTime(m.createdAt), '@${s.pf(m.sellerId).username}', m.title, '฿${m.price}', m.category, m.contact],
          ],
        );
        break;
      default:
        table = _table(
          ['ชื่อผู้ใช้', 'ชื่อ', 'ระดับ/สาขา', 'ลงทะเบียนเมื่อ'],
          [
            for (final u in users)
              ['@${u.username}', u.name, '${u.level ?? ''} ${u.major ?? ''}', fmtDateTime(u.createdAt)],
          ],
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗄️ ฐานข้อมูล'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('คัดลอก JSON'),
            onPressed: () => copyText(context, s.exportJson(), 'คัดลอกข้อมูลทั้งหมดเป็น JSON แล้ว'),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('${users.length}', 'ผู้ใช้'),
              _stat('${s.posts.length}', 'โพสต์/สตอรี่'),
              _stat('${s.products.length}', 'สินค้า'),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'users', label: Text('ผู้ใช้')),
            ButtonSegment(value: 'posts', label: Text('โพสต์')),
            ButtonSegment(value: 'products', label: Text('สินค้า')),
          ],
          selected: {tab},
          onSelectionChanged: (v) => setState(() => tab = v.first),
        ),
        const SizedBox(height: 12),
        table,
      ]),
    );
  }

  Widget _stat(String n, String l) => Column(children: [
        Text(n, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(l, style: const TextStyle(fontSize: 12)),
      ]);

  Widget _table(List<String> head, List<List<String>> rows) {
    if (rows.isEmpty) return const EmptyState('ยังไม่มีข้อมูล');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [for (final h in head) DataColumn(label: Text(h))],
        rows: [
          for (final r in rows) DataRow(cells: [for (final c in r) DataCell(Text(c))]),
        ],
      ),
    );
  }
}
