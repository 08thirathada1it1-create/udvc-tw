import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'pages/auth_page.dart';
import 'pages/home_shell.dart';
import 'services/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.configured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseKey);
  }
  runApp(const UdvcApp());
}

class UdvcApp extends StatelessWidget {
  const UdvcApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.configured) {
      return MaterialApp(
        title: 'UDVC TW',
        theme: buildTheme(Brightness.light),
        home: const _SetupPage(),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: Consumer<AppState>(
        builder: (context, s, _) => MaterialApp(
          title: 'UDVC TW',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: s.themeMode,
          home: s.booting
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : s.me == null
                  ? const AuthPage()
                  : const HomeShell(),
        ),
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  const _SetupPage();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '🛠️ ยังไม่ได้ตั้งค่า Supabase\n\nเปิดไฟล์ lib/config.dart แล้วใส่ supabaseUrl และ supabaseKey',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
}
