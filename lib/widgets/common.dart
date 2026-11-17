import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

/// รันงานแล้วแสดงข้อผิดพลาดเป็น SnackBar (คืน true ถ้าสำเร็จ)
Future<bool> guard(BuildContext context, Future<void> Function() job, {String? ok}) async {
  try {
    await job();
    if (ok != null && context.mounted) snack(context, ok);
    return true;
  } catch (e) {
    if (context.mounted) snack(context, errText(e));
    return false;
  }
}

/// เปิดหน้าใหม่โดยเลื่อนเข้ามาจากทางซ้าย (เหมือนปัดไปหน้ากล้องของ IG)
Route<T> slideFromLeft<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    );

/// โทรหรือคัดลอกช่องทางติดต่อ
Future<void> contactSeller(BuildContext context, String contact) async {
  final isPhone = RegExp(r'^[0-9+\-\s]{8,}$').hasMatch(contact);
  if (isPhone) {
    final uri = Uri(scheme: 'tel', path: contact.replaceAll(RegExp(r'[^0-9+]'), ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
  }
  await Clipboard.setData(ClipboardData(text: contact));
  if (context.mounted) snack(context, 'คัดลอกแล้ว: $contact');
}

Future<void> copyText(BuildContext context, String text, [String? msg]) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) snack(context, msg ?? 'คัดลอกแล้ว');
}

Future<bool> confirmDelete(BuildContext context, {String title = 'ยืนยันการลบ?'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
      ],
    ),
  );
  return r ?? false;
}

/// เลือกรูปจากกล้องหรือแกลเลอรี
Future<Uint8List?> pickImage(BuildContext context) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera),
          title: const Text('ถ่ายรูป'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('เลือกจากแกลเลอรี'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ]),
    ),
  );
  if (src == null) return null;
  final f = await ImagePicker().pickImage(source: src, maxWidth: 1080, imageQuality: 80);
  if (f == null) return null;
  return await f.readAsBytes();
}

// ============================================================ วิดเจ็ตทั่วไป
class Avatar extends StatelessWidget {
  final Profile? user;
  final double radius;
  const Avatar(this.user, {super.key, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: kAccent,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(
              (user?.name.isNotEmpty ?? false) ? user!.name.characters.first : '?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * .9),
            )
          : null,
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;
  final Widget? action;
  const EmptyState(this.text, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor)),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ]),
        ),
      );
}

/// แถบตัวกรองแนวนอน (ทั้งหมด + ตัวเลือก)
class ChipBar extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;
  const ChipBar({super.key, required this.items, required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          children: [
            for (final i in items)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(i),
                  selected: selected == i,
                  selectedColor: kAccent,
                  labelStyle: TextStyle(color: selected == i ? Colors.white : null),
                  onSelected: (_) => onSelected(i),
                ),
              ),
          ],
        ),
      );
}

class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width, height;
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height});
  @override
  Widget build(BuildContext context) => Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (c, child, p) => p == null
            ? child
            : Container(
                width: width, height: height ?? 200,
                color: Theme.of(c).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
        errorBuilder: (c, _, __) => Container(
          width: width, height: height ?? 200,
          color: Theme.of(c).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image),
        ),
      );
}

// ================================================================== ฟอร์ม
Widget textField(String label, TextEditingController c,
        {int lines = 1, TextInputType? type, int? maxLength, String? hint, bool obscure = false}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        minLines: lines,
        maxLines: lines,
        keyboardType: type,
        maxLength: maxLength,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
      ),
    );

class DropField extends StatelessWidget {
  final String label;
  final List<String> items;
  final ValueNotifier<String> value;
  const DropField({super.key, required this.label, required this.items, required this.value});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: value,
        builder: (_, v, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: items.contains(v) ? v : items.first,
            decoration: InputDecoration(labelText: label),
            items: [for (final e in items) DropdownMenuItem(value: e, child: Text(e))],
            onChanged: (x) {
              if (x != null) value.value = x;
            },
          ),
        ),
      );
}

class ImagePickerBox extends StatelessWidget {
  final ValueNotifier<Uint8List?> bytes;
  final String? existingUrl;
  final double aspect;
  const ImagePickerBox({super.key, required this.bytes, this.existingUrl, this.aspect = 1.6});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Uint8List?>(
        valueListenable: bytes,
        builder: (ctx, b, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final x = await pickImage(ctx);
              if (x != null) bytes.value = x;
            },
            child: AspectRatio(
              aspectRatio: aspect,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(ctx).dividerColor, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: b != null
                    ? Image.memory(b, fit: BoxFit.cover, width: double.infinity)
                    : existingUrl != null
                        ? NetImage(existingUrl!, width: double.infinity)
                        : const Center(child: Text('📷\nแตะเพื่อถ่ายรูปหรือเลือกจากแกลเลอรี', textAlign: TextAlign.center)),
              ),
            ),
          ),
        ),
      );
}

/// หน้าต่างฟอร์มจากด้านล่าง: onSubmit โยน String เพื่อแสดงข้อความผิดพลาดในฟอร์ม
Future<void> showFormSheet(
  BuildContext context, {
  required String title,
  required List<Widget> fields,
  required Future<void> Function() onSubmit,
  String button = 'บันทึก',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      bool busy = false;
      String? err;
      return StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...fields,
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(err!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            set(() {
                              busy = true;
                              err = null;
                            });
                            try {
                              await onSubmit();
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (ctx.mounted) {
                                set(() {
                                  busy = false;
                                  err = errText(e);
                                });
                              }
                            }
                          },
                    child: Text(busy ? 'กำลังบันทึก…' : button),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );
    },
  );
}
