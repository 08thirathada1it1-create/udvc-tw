import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';
import 'user_profile_page.dart';

/// ค้นหาผู้ใช้ โพสต์ สินค้า การ์ดเพื่อน และกิจกรรม
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String q = '';

  bool _has(String? s) => (s ?? '').toLowerCase().contains(q.trim().toLowerCase());

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final has = q.trim().isNotEmpty;
    final List<Profile> users = has ? s.profiles.values.where((u) => _has(u.name) || _has(u.username)).toList() : <Profile>[];
    final List<Post> posts = has ? s.posts.where((p) => !p.isStory && _has(p.caption)).toList() : <Post>[];
    final List<Product> items = has ? s.products.where((m) => _has(m.title) || _has(m.category)).toList() : <Product>[];
    final List<Buddy> cards = has ? s.buddies.where((b) => _has(b.title) || _has(b.bio)).toList() : <Buddy>[];
    final List<EventItem> events = has ? s.events.where((e) => _has(e.title) || _has(e.place) || _has(e.note)).toList() : <EventItem>[];
    final none = has && users.isEmpty && posts.isEmpty && items.isEmpty && cards.isEmpty && events.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => q = v),
          decoration: const InputDecoration(hintText: 'ค้นหา', border: InputBorder.none),
        ),
      ),
      body: !has
          ? const EmptyState('พิมพ์เพื่อค้นหาผู้ใช้ โพสต์ สินค้า เพื่อน และกิจกรรม')
          : none
              ? const EmptyState('ไม่พบผลลัพธ์')
              : ListView(children: [
                  if (users.isNotEmpty) ...[
                    _h('ผู้ใช้'),
                    for (final u in users)
                      ListTile(
                        leading: Avatar(u),
                        title: Text(u.name),
                        subtitle: Text('@${u.username} · ${u.major ?? ''}'),
                        onTap: () => openProfile(context, u.id),
                      ),
                  ],
                  if (posts.isNotEmpty) ...[
                    _h('โพสต์'),
                    for (final p in posts) PostCard(key: ValueKey('s${p.id}'), post: p),
                  ],
                  if (items.isNotEmpty) ...[
                    _h('Shop'),
                    for (final m in items)
                      ListTile(
                        leading: m.imageUrl != null ? NetImage(m.imageUrl!, width: 48, height: 48) : const Icon(Icons.shopping_bag),
                        title: Text(m.title),
                        subtitle: Text('฿${m.price} · @${s.pf(m.sellerId).username}'),
                        trailing: TextButton(onPressed: () => contactSeller(context, m.contact), child: const Text('ติดต่อ')),
                      ),
                  ],
                  if (cards.isNotEmpty) ...[
                    _h('Friends'),
                    for (final b in cards)
                      ListTile(
                        leading: const Icon(Icons.favorite_border),
                        title: Text(b.title),
                        subtitle: Text('${b.type} · ${s.pf(b.ownerId).name}'),
                        onTap: () => openProfile(context, b.ownerId),
                      ),
                  ],
                  if (events.isNotEmpty) ...[
                    _h('กิจกรรม'),
                    for (final e in events)
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(e.title),
                        subtitle: Text('${fmtDate(e.date)} ${e.time} น. · ${e.place}'),
                      ),
                  ],
                ]),
    );
  }
}
