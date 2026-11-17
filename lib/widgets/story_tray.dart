import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../pages/create_post_page.dart';
import '../services/app_state.dart';
import '../theme.dart';
import 'common.dart';
import 'story_viewer.dart';

/// แถบสตอรี่ด้านบน Feed (สตอรี่แสดง 24 ชม.)
class StoryTray extends StatelessWidget {
  const StoryTray({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final groups = <String, List<Post>>{};
    for (final p in s.posts) {
      if (p.isStory && now.difference(p.createdAt).inHours < 24) {
        groups.putIfAbsent(p.authorId, () => []).add(p);
      }
    }
    for (final l in groups.values) {
      l.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    final myId = s.me!.id;
    final others = groups.keys.where((k) => k != myId).toList()
      ..sort((a, b) => groups[b]!.last.createdAt.compareTo(groups[a]!.last.createdAt));
    final order = [if (groups.containsKey(myId)) myId, ...others];
    final lists = [for (final k in order) groups[k]!];

    void open(String userId) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerPage(groups: lists, start: order.indexOf(userId))));

    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _bubble(
            context,
            user: s.me!,
            label: 'สตอรี่ของคุณ',
            ring: groups.containsKey(myId),
            plus: true,
            onTap: () => groups.containsKey(myId)
                ? open(myId)
                : Navigator.push(context, slideFromLeft(const CreatePostPage(initialStory: true))),
            onPlus: () => Navigator.push(context, slideFromLeft(const CreatePostPage(initialStory: true))),
          ),
          for (final k in others)
            _bubble(context, user: s.pf(k), label: s.pf(k).username, ring: true, onTap: () => open(k)),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context,
      {required Profile user,
      required String label,
      required bool ring,
      required VoidCallback onTap,
      bool plus = false,
      VoidCallback? onPlus}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 66,
        child: Column(children: [
          Stack(children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: ring ? Border.all(color: kAccent, width: 2.5) : null,
                ),
                child: Avatar(user, radius: 28),
              ),
            ),
            if (plus)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onPlus,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
        ]),
      ),
    );
  }
}
