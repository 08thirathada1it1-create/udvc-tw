import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/profile_view.dart';

/// เปิดโปรไฟล์ของผู้ใช้จากโพสต์ / ผลค้นหา / แชท
void openProfile(BuildContext context, String userId) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: userId)));
}

class UserProfilePage extends StatelessWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.pf(userId);
    final own = userId == s.me!.id;
    return Scaffold(
      appBar: AppBar(title: Text('@${u.username}')),
      body: ProfileView(user: u, own: own),
    );
  }
}
