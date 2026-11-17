import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_room_page.dart';

/// หน้า Friends: การ์ดรูปใหญ่ ปัดขวา/กด 💚 = แมตช์ (เปิดแชท) ปัดซ้าย/กด ✕ = ข้าม
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  String filter = 'ทั้งหมด';

  Future<void> _match(AppState s, Buddy b) async {
    await s.pass(b.id);
    if (!mounted) return;
    snack(context, 'แมตช์แล้ว 💚');
    try {
      final chatId = await s.startChat(b.ownerId);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: chatId)));
    } catch (e) {
      if (mounted) snack(context, errText(e));
    }
  }

  void _addCard() {
    final s = context.read<AppState>();
    final image = ValueNotifier<Uint8List?>(null);
    final type = ValueNotifier<String>(kBuddyTypes.first);
    final title = TextEditingController();
    final bio = TextEditingController();
    showFormSheet(
      context,
      title: 'สร้างการ์ดหาเพื่อน',
      fields: [
        ImagePickerBox(bytes: image, aspect: 1.2),
        DropField(label: 'ประเภท', items: kBuddyTypes, value: type),
        textField('หัวข้อ *', title, hint: 'เช่น หาเพื่อนติวบัญชี', maxLength: 80),
        textField('รายละเอียด', bio, lines: 3, maxLength: 300),
      ],
      onSubmit: () async {
        if (image.value == null) throw 'ต้องใส่รูปภาพ';
        if (title.text.trim().isEmpty) throw 'กรอกหัวข้อ';
        await s.addBuddy(type: type.value, title: title.text.trim(), bio: bio.text.trim(), image: image.value!);
      },
    ).whenComplete(() {
      image.dispose();
      type.dispose();
      title.dispose();
      bio.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final deck = s.buddies
        .where((b) => b.ownerId != s.me!.id && !s.passed.contains(b.id) && (filter == 'ทั้งหมด' || b.type == filter))
        .toList();
    final b = deck.isEmpty ? null : deck.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        ChipBar(
          items: ['ทั้งหมด', ...kBuddyTypes],
          selected: filter,
          onSelected: (v) => setState(() => filter = v),
        ),
        Expanded(
          child: b == null
              ? EmptyState(
                  'ไม่มีโปรไฟล์ให้ดูแล้ว\nกด + เพื่อสร้างการ์ดของคุณ',
                  action: OutlinedButton(onPressed: s.resetPassed, child: const Text('ดูใหม่อีกครั้ง')),
                )
              : Column(children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Dismissible(
                        key: ValueKey(b.id),
                        background: _swipeBg(Alignment.centerLeft, Colors.green, Icons.favorite),
                        secondaryBackground: _swipeBg(Alignment.centerRight, Colors.grey, Icons.close),
                        onDismissed: (dir) {
                          if (dir == DismissDirection.startToEnd) {
                            _match(s, b);
                          } else {
                            s.pass(b.id);
                          }
                        },
                        child: _BuddyCard(buddy: b, owner: s.pf(b.ownerId)),
                      ),
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _roundBtn(Icons.close, Colors.grey, () => s.pass(b.id)),
                    const SizedBox(width: 32),
                    _roundBtn(Icons.favorite, Colors.green, () => _match(s, b)),
                  ]),
                  const SizedBox(height: 16),
                ]),
        ),
      ]),
    );
  }

  Widget _swipeBg(Alignment a, Color c, IconData i) => Container(
        alignment: a,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(color: c.withOpacity(.25), borderRadius: BorderRadius.circular(22)),
        child: Icon(i, color: c, size: 48),
      );

  Widget _roundBtn(IconData i, Color c, VoidCallback f) => Material(
        color: c,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: f,
          child: Padding(padding: const EdgeInsets.all(16), child: Icon(i, color: Colors.white, size: 30)),
        ),
      );
}

class _BuddyCard extends StatelessWidget {
  final Buddy buddy;
  final Profile owner;
  const _BuddyCard({required this.buddy, required this.owner});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(fit: StackFit.expand, children: [
          buddy.imageUrl != null
              ? NetImage(buddy.imageUrl!)
              : Container(color: kAccent.withOpacity(.2), child: Center(child: Avatar(owner, radius: 60))),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Chip(label: Text(buddy.type), visualDensity: VisualDensity.compact),
                Text(owner.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(buddy.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                if (buddy.bio.isNotEmpty) Text(buddy.bio, style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          ),
        ]),
      );
}
