import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// หน้าต่างความคิดเห็นแบบ IG: ตอบกลับ / ถูกใจความเห็น / ลบความเห็นของตัวเอง
Future<void> showCommentsSheet(BuildContext context, String postId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CommentsSheet(postId: postId),
  );
}

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final ctrl = TextEditingController();
  final focus = FocusNode();
  Comment? replyTo;

  @override
  void dispose() {
    ctrl.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> _send(AppState s) async {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    final parent = replyTo?.id;
    ctrl.clear();
    setState(() => replyTo = null);
    await guard(context, () => s.addComment(widget.postId, t, parentId: parent));
  }

  Widget _tile(AppState s, Comment c, {bool reply = false}) {
    final u = s.pf(c.authorId);
    final liked = c.likes.contains(s.me!.id);
    return Padding(
      padding: EdgeInsets.only(left: reply ? 44 : 0, top: 6, bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Avatar(u, radius: reply ? 13 : 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '${u.username} ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: c.body),
            ])),
            Wrap(spacing: 12, children: [
              Text(ago(c.createdAt), style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              if (!reply)
                GestureDetector(
                  onTap: () {
                    setState(() => replyTo = c);
                    focus.requestFocus();
                  },
                  child: const Text('ตอบกลับ', style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
                ),
              if (c.authorId == s.me!.id)
                GestureDetector(
                  onTap: () => guard(context, () => s.deleteComment(c.id)),
                  child: const Text('ลบ', style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
                ),
            ]),
          ]),
        ),
        InkWell(
          onTap: () => s.toggleCommentLike(c),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(children: [
              Icon(liked ? Icons.favorite : Icons.favorite_border, size: 18, color: liked ? Colors.red : null),
              if (c.likes.isNotEmpty) Text('${c.likes.length}', style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final post = s.postById(widget.postId);
    final h = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: h,
        child: Column(children: [
          const Text('ความคิดเห็น', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Expanded(
            child: post == null || post.comments.isEmpty
                ? const EmptyState('ยังไม่มีความคิดเห็น\nเป็นคนแรกที่แสดงความคิดเห็น')
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final c in post.comments) ...[
                        _tile(s, c),
                        for (final r in c.replies) _tile(s, r, reply: true),
                      ],
                    ],
                  ),
          ),
          if (replyTo != null)
            ListTile(
              dense: true,
              title: Text('กำลังตอบกลับ ${s.pf(replyTo!.authorId).username}'),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => replyTo = null)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  focusNode: focus,
                  maxLength: 300,
                  onSubmitted: (_) => _send(s),
                  decoration: InputDecoration(
                    hintText: replyTo != null ? 'เขียนข้อความตอบกลับ...' : 'เพิ่มความคิดเห็น...',
                    counterText: '',
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: () => _send(s)),
            ]),
          ),
        ]),
      ),
    );
  }
}
