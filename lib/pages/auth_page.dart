import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// หน้าเข้าสู่ระบบ / สมัครสมาชิก
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool register = false;
  bool busy = false;
  final user = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  final level = ValueNotifier<String>(kLevels.first);
  final major = ValueNotifier<String>(kMajors.first);

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    name.dispose();
    level.dispose();
    major.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final u = user.text.trim().toLowerCase();
    final p = pass.text;
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(u)) {
      snack(context, 'ชื่อผู้ใช้ใช้ได้เฉพาะ a-z 0-9 _ ยาว 3–20 ตัว');
      return;
    }
    if (p.length < 6) {
      snack(context, 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว');
      return;
    }
    if (register && name.text.trim().isEmpty) {
      snack(context, 'กรอกชื่อที่แสดง');
      return;
    }
    final s = context.read<AppState>();
    setState(() => busy = true);
    final ok = await guard(context, () async {
      if (register) {
        await s.signUp(
          username: u, password: p, name: name.text.trim(),
          level: level.value, major: major.value,
        );
      } else {
        await s.signIn(u, p);
      }
    });
    if (mounted && !ok) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(children: [
                const Text('UDVC TW',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kAccent)),
                const SizedBox(height: 4),
                Text('แอปชุมชนนักเรียนวิทยาลัยอาชีวศึกษาอุดรธานี',
                    style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('เข้าสู่ระบบ')),
                    ButtonSegment(value: true, label: Text('สมัครสมาชิก')),
                  ],
                  selected: {register},
                  onSelectionChanged: (v) => setState(() => register = v.first),
                ),
                const SizedBox(height: 20),
                textField('ชื่อผู้ใช้ (a-z 0-9 _)', user, maxLength: 20),
                textField('รหัสผ่าน (อย่างน้อย 6 ตัว)', pass, obscure: true),
                if (register) ...[
                  textField('ชื่อที่แสดง', name, maxLength: 40),
                  DropField(label: 'ระดับชั้น', items: kLevels, value: level),
                  DropField(label: 'สาขาวิชา', items: kMajors, value: major),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(busy ? 'กำลังดำเนินการ…' : (register ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ')),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
