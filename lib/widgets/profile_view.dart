import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../pages/chat_room_page.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';
import 'item_viewer.dart';

/// โปรไฟล์แบบ Instagram: รูป สถิติ ปุ่ม และแท็บ โพสต์ | ประกาศขาย | การ์ด
/// ใช้ทั้งหน้า ME (own = true) และหน้าโปรไฟล์ของคนอื่น
class ProfileView extends StatefulWidget {
  final Profile user;
  final bool own;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenAdmin;
  const ProfileView({super.key, required this.user, required this.own, this.onEdit, this.onOpenAdmin});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = widget.user;
    final posts = s.posts.where((p) => p.authorId == u.id && !p.isStory).toList();
    final items = s.products.where((m) => m.sellerId == u.id).toList();
    final tabs = ['▦ โพสต์', '🛍️ ประกาศขาย'];
    if (tab >= tabs.length) tab = 0;

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (widget.own)
        Row(children: [
          Expanded(child: Text('@${u.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          if (s.isAdmin && widget.onOpenAdmin != null)
            IconButton(icon: const Icon(Icons.storage), tooltip: 'ฐานข้อมูล', onPressed: widget.onOpenAdmin),
          IconButton(icon: const Icon(Icons.brightness_6), tooltip: 'ธีม', onPressed: s.cycleTheme),
        ]),
      Row(children: [
        Avatar(u, radius: 38),
        const SizedBox(width: 20),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('${posts.length}', 'โพสต์'),
            _stat('${items.length}', 'ประกาศขาย'),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text('${u.level ?? ''} · ${u.major ?? ''}',
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
      if (u.bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(u.bio)),
      const SizedBox(height: 12),
      if (widget.own && widget.onEdit != null)
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: widget.onEdit, child: const Text('แก้ไขโปรไฟล์'))),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => guard(context, s.signOut),
              child: const Text('ออกจากระบบ'),
            ),
          ),
        ])
      else if (!widget.own)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('ส่งข้อความ'),
            onPressed: () async {
              final nav = Navigator.of(context);
              try {
                final id = await s.startChat(u.id);
                nav.push(MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: id)));
              } catch (e) {
                if (context.mounted) snack(context, errText(e));
              }
            },
          ),
        ),
      const SizedBox(height: 12),
      Row(children: [
        for (int i = 0; i < tabs.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab == i ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(tabs[i], style: TextStyle(fontWeight: tab == i ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      if (tab == 0) _grid(posts.map((p) => _Tile(url: p.imageUrl, text: p.caption, onTap: () => showItemViewer(context, post: p))).toList(), 'ยังไม่มีโพสต์'),
      if (tab == 1) _grid(items.map((m) => _Tile(url: m.imageUrl, text: m.title, price: m.price, onTap: () => showItemViewer(context, product: m))).toList(), 'ยังไม่มีประกาศขาย'),
    ]);
  }

  Widget _stat(String n, String label) => Column(children: [
        Text(n, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);

  Widget _grid(List<Widget> tiles, String emptyText) {
    if (tiles.isEmpty) return EmptyState(emptyText);
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }
}

class _Tile extends StatelessWidget {
  final String? url;
  final String text;
  final double? price;
  final VoidCallback onTap;
  const _Tile({required this.url, required this.text, required this.onTap, this.price});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(fit: StackFit.expand, children: [
          url != null
              ? NetImage(url!)
              : Container(
                  color: kAccent.withOpacity(.12),
                  padding: const EdgeInsets.all(6),
                  child: Text(text, maxLines: 5, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                ),
          if (price != null)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text('฿${price! % 1 == 0 ? price!.toInt() : price}',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
        ]),
      );
}
