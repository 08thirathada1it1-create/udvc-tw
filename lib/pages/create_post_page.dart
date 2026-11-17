import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/common.dart';

/// หน้าสร้างโพสต์/สตอรี่ (เลื่อนเข้ามาจากทางซ้ายเมื่อปัดขวาที่ Feed / ปัดซ้ายเพื่อกลับ)
class CreatePostPage extends StatefulWidget {
  final bool initialStory;
  const CreatePostPage({super.key, this.initialStory = false});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final caption = TextEditingController();
  final image = ValueNotifier<Uint8List?>(null);
  late bool story = widget.initialStory;
  bool busy = false;

  @override
  void dispose() {
    caption.dispose();
    image.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = caption.text.trim();
    if (text.isEmpty && image.value == null) {
      snack(context, 'ใส่แคปชั่นหรือรูปภาพอย่างน้อยหนึ่งอย่าง');
      return;
    }
    if (story && image.value == null) {
      snack(context, 'สตอรี่ต้องมีรูปภาพ');
      return;
    }
    final s = context.read<AppState>();
    final nav = Navigator.of(context);
    setState(() => busy = true);
    final ok = await guard(
      context,
      () => s.createPost(caption: text, image: image.value, story: story),
      ok: story ? 'ลงสตอรี่แล้ว (แสดง 24 ชม.)' : 'โพสต์แล้ว',
    );
    if (ok) {
      nav.pop();
    } else if (mounted) {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -500) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('สร้างใหม่'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: busy ? null : _publish,
                child: Text(busy ? 'กำลังโพสต์…' : 'แชร์'),
              ),
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('โพสต์')),
                ButtonSegment(value: true, label: Text('สตอรี่')),
              ],
              selected: {story},
              onSelectionChanged: (v) => setState(() => story = v.first),
            ),
          ),
          const SizedBox(height: 16),
          ImagePickerBox(bytes: image, aspect: 1),
          textField('แคปชั่น', caption, lines: 4, maxLength: 600, hint: 'เล่าเรื่องราววันนี้ หรือใส่ #UDVC'),
          Center(
            child: Text('ปัดซ้ายเพื่อกลับหน้า Feed',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ),
        ]),
      ),
    );
  }
}
