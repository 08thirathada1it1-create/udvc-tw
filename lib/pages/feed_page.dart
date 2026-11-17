import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';
import '../widgets/story_tray.dart';
import 'create_post_page.dart';

/// หน้า Feed: แถบสตอรี่ + โพสต์ของทุกคน / ปัดขวาเพื่อสร้างโพสต์หรือสตอรี่
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final feed = s.posts.where((p) => !p.isStory).toList();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 500) {
          Navigator.push(context, slideFromLeft(const CreatePostPage()));
        }
      },
      child: RefreshIndicator(
        onRefresh: () => s.reload(['profiles', 'posts']),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const StoryTray(),
            if (feed.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: EmptyState('ยังไม่มีโพสต์\nปัดหน้าจอไปทางขวาเพื่อสร้างโพสต์หรือสตอรี่'),
              )
            else
              for (final p in feed) PostCard(key: ValueKey(p.id), post: p),
          ],
        ),
      ),
    );
  }
}
