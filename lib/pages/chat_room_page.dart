import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'user_profile_page.dart';

/// ห้องแชทแบบ IG: ฟองข้อความ, แตะ 2 ครั้งถูกใจ, กดค้าง = คัดลอก/ยกเลิกการส่ง, ส่งรูป, ปุ่มหัวใจ
class ChatRoomPage extends StatefulWidget {
  final String chatId;
  const ChatRoomPage({super.key, required this.chatId});
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  int _lastCount = -1;

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send(AppState s) async {
    final t = input.text.trim();
    input.clear();
    await guard(context, () => s.sendMessage(widget.chatId, body: t.isEmpty ? '❤️' : t));
  }

  Future<void> _sendPhoto(AppState s) async {
    final b = await pickImage(context);
    if (b == null || !mounted) return;
    await guard(context, () => s.sendMessage(widget.chatId, image: b));
  }

  void _menu(AppState s, Message m) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (m.body.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('คัดลอก'),
              onTap: () {
                Navigator.pop(ctx);
                copyText(context, m.body);
              },
            ),
          if (m.senderId == s.me!.id)
            ListTile(
              leading: const Icon(Icons.undo, color: Colors.red),
              title: const Text('ยกเลิกการส่ง', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                guard(context, () => s.unsend(m.id));
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final chat = s.chatById(widget.chatId);
    if (chat == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState('ไม่พบแชท'));
    }
    final other = s.pf(chat.otherId);
    final msgs = chat.messages;
    if (msgs.length != _lastCount) {
      _lastCount = msgs.length;
      _toBottom();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => openProfile(context, other.id),
          child: Row(children: [
            Avatar(other, radius: 18),
            const SizedBox(width: 10),
            Text(other.name, style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.onSurface)),
          ]),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: msgs.isEmpty
              ? const EmptyState('ทักทายเพื่อนใหม่ได้เลย 👋')
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final prev = i > 0 ? msgs[i - 1] : null;
                    final showSep = prev == null || m.createdAt.difference(prev.createdAt).inMinutes > 60;
                    final isLast = i == msgs.length - 1;
                    return Column(children: [
                      if (showSep)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(dayLabel(m.createdAt),
                              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                        ),
                      _Bubble(
                        message: m,
                        mine: m.senderId == s.me!.id,
                        post: m.postId != null ? s.postById(m.postId!) : null,
                        onLike: () => s.toggleMessageLike(m),
                        onLongPress: () => _menu(s, m),
                      ),
                      if (isLast && m.senderId == s.me!.id)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('ส่งแล้ว', style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
                        ),
                    ]);
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.photo_camera_outlined), onPressed: () => _sendPhoto(s)),
              Expanded(
                child: TextField(
                  controller: input,
                  maxLength: 500,
                  onSubmitted: (_) => _send(s),
                  decoration: InputDecoration(
                    hintText: 'ข้อความ...',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: input,
                builder: (_, v, __) => IconButton(
                  // ช่องว่าง = ปุ่มหัวใจ (ส่ง ❤️) / มีข้อความ = ปุ่มส่ง
                  icon: Icon(v.text.trim().isEmpty ? Icons.favorite : Icons.send, color: kAccent),
                  onPressed: () => _send(s),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool mine;
  final Post? post;
  final VoidCallback onLike, onLongPress;
  const _Bubble({
    required this.message, required this.mine, required this.post,
    required this.onLike, required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final m = message;
    final bigHeart = m.body == '❤️';
    final img = m.imageUrl ?? post?.imageUrl;
    final bare = bigHeart || (img != null && m.body.isEmpty);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onDoubleTap: onLike,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: bare ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: bare
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: mine
                          ? const LinearGradient(colors: [kAccent, Color(0xFFE58A4D)])
                          : null,
                      color: mine ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (img != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: m.body.isNotEmpty ? 6 : 0),
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(img, width: 200)),
                  ),
                if (m.body.isNotEmpty)
                  Text(
                    m.body,
                    style: TextStyle(
                      fontSize: bigHeart ? 44 : 15,
                      color: bigHeart ? null : (mine ? Colors.white : null),
                    ),
                  ),
              ]),
            ),
            if (m.liked)
              Positioned(
                right: mine ? 8 : null,
                left: mine ? null : 8,
                bottom: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: const Text('❤️', style: TextStyle(fontSize: 13)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
