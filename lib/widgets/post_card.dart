import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../pages/user_profile_page.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import 'comments_sheet.dart';
import 'common.dart';
import 'share_sheet.dart';

/// การ์ดโพสต์แบบ Instagram: แตะชื่อ = ดูโปรไฟล์, แตะ 2 ครั้ง = ถูกใจ
class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _heart = false;

  void _doubleTap() {
    context.read<AppState>().toggleLike(widget.post, force: true);
    setState(() => _heart = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _heart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = widget.post;
    final author = s.pf(p.authorId);
    final liked = p.likes.contains(s.me!.id);
    final canDelete = p.authorId == s.me!.id || s.isAdmin;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => openProfile(context, p.authorId),
                child: Row(children: [
                  Avatar(author),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('@${author.username} · ${ago(p.createdAt)}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                    ]),
                  ),
                ]),
              ),
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (await confirmDelete(context) && context.mounted) {
                    await guard(context, () => s.deletePost(p.id));
                  }
                },
              ),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onDoubleTap: _doubleTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(alignment: Alignment.center, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (p.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: NetImage(p.imageUrl!, width: double.infinity),
                  ),
                if (p.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(p.caption),
                  ),
              ]),
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedScale(
                      scale: _heart ? 1.2 : 0.3,
                      duration: const Duration(milliseconds: 250),
                      child: AnimatedOpacity(
                        opacity: _heart ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 96,
                            shadows: [Shadow(blurRadius: 12, color: Colors.black54)]),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Row(children: [
            TextButton.icon(
              onPressed: () => s.toggleLike(p),
              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
              label: Text('${p.likes.length}'),
            ),
            TextButton.icon(
              onPressed: () => showCommentsSheet(context, p.id),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text('${p.commentCount}'),
            ),
            IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: () => showShareSheet(context, p),
            ),
          ]),
        ]),
      ),
    );
  }
}
