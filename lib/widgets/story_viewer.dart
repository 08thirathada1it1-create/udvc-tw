import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import 'common.dart';

/// ดูสตอรี่เต็มจอแบบ IG: แตะขวา = ถัดไป, แตะซ้าย = ย้อนกลับ, กดค้าง = หยุดชั่วคราว
class StoryViewerPage extends StatefulWidget {
  final List<List<Post>> groups; // หนึ่งกลุ่มต่อหนึ่งบัญชี
  final int start;
  const StoryViewerPage({super.key, required this.groups, this.start = 0});
  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late int g;
  int i = 0;

  @override
  void initState() {
    super.initState();
    g = widget.start < 0 ? 0 : widget.start;
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed) _next();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _restart() {
    _c
      ..reset()
      ..forward();
  }

  void _next() {
    if (i + 1 < widget.groups[g].length) {
      setState(() => i++);
    } else if (g + 1 < widget.groups.length) {
      setState(() {
        g++;
        i = 0;
      });
    } else {
      Navigator.pop(context);
      return;
    }
    _restart();
  }

  void _prev() {
    if (i > 0) {
      setState(() => i--);
    } else if (g > 0) {
      setState(() {
        g--;
        i = widget.groups[g].length - 1;
      });
    }
    _restart();
  }

  Future<void> _deleteCurrent(AppState s, Post post) async {
    _c.stop();
    final ok = await confirmDelete(context, title: 'ลบสตอรี่นี้?');
    if (!mounted) return;
    if (!ok) {
      _c.forward();
      return;
    }
    final deleted = await guard(context, () => s.deletePost(post.id), ok: 'ลบสตอรี่แล้ว');
    if (!mounted) return;
    if (deleted) {
      widget.groups[g].removeAt(i);
      if (widget.groups[g].isEmpty) {
        widget.groups.removeAt(g);
        if (widget.groups.isEmpty) {
          Navigator.pop(context);
          return;
        }
        if (g >= widget.groups.length) g = widget.groups.length - 1;
        i = 0;
      } else if (i >= widget.groups[g].length) {
        i = widget.groups[g].length - 1;
      }
      setState(() {});
      _restart();
    } else {
      _c.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = widget.groups[g];
    final post = list[i];
    final user = s.pf(post.authorId);
    final canDelete = post.authorId == s.me!.id || s.isAdmin;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          d.globalPosition.dx < w * .35 ? _prev() : _next();
        },
        onLongPressStart: (_) => _c.stop(),
        onLongPressEnd: (_) => _c.forward(),
        child: Stack(fit: StackFit.expand, children: [
          if (post.imageUrl != null)
            NetImage(post.imageUrl!, fit: BoxFit.contain)
          else
            const SizedBox.shrink(),
          SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => Row(children: [
                    for (int k = 0; k < list.length; k++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: k < i ? 1 : (k == i ? _c.value : 0),
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              ListTile(
                leading: Avatar(user),
                title: Text(user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(ago(post.createdAt), style: const TextStyle(color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        tooltip: 'ลบสตอรี่',
                        onPressed: () => _deleteCurrent(s, post),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (post.caption.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.black45,
                  padding: const EdgeInsets.all(16),
                  child: Text(post.caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
