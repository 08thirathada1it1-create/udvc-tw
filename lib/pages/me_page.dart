import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/profile_view.dart';
import 'admin_db_page.dart';

/// หน้า ME: โปรไฟล์ของตัวเองแบบ Instagram (โพสต์ -> ประกาศขายอยู่ในแท็บข้างกัน)
class MePage extends StatelessWidget {
  const MePage({super.key});

  void _edit(BuildContext context) {
    final s = context.read<AppState>();
    final me = s.me!;
    final name = TextEditingController(text: me.name);
    final bio = TextEditingController(text: me.bio);
    final level = ValueNotifier<String>(me.level ?? kLevels.first);
    final major = ValueNotifier<String>(me.major ?? kMajors.first);
    final photo = ValueNotifier<Uint8List?>(null);
    showFormSheet(
      context,
      title: 'แก้ไขโปรไฟล์',
      fields: [
        ImagePickerBox(bytes: photo, existingUrl: me.avatarUrl, aspect: 2),
        textField('ชื่อที่แสดง *', name, maxLength: 40),
        DropField(label: 'ระดับชั้น', items: kLevels, value: level),
        DropField(label: 'สาขาวิชา', items: kMajors, value: major),
        textField('แนะนำตัว', bio, lines: 3, maxLength: 200),
      ],
      onSubmit: () async {
        if (name.text.trim().isEmpty) throw 'กรอกชื่อที่แสดง';
        await s.updateProfile(
          name: name.text.trim(), level: level.value, major: major.value,
          bio: bio.text.trim(), newAvatar: photo.value,
        );
      },
    ).whenComplete(() {
      name.dispose();
      bio.dispose();
      level.dispose();
      major.dispose();
      photo.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: () => s.reload(['profiles', 'posts', 'products', 'buddies']),
      child: ProfileView(
        user: s.me!,
        own: true,
        onEdit: () => _edit(context),
        onOpenAdmin: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDbPage())),
      ),
    );
  }
}
