import 'package:flutter/material.dart';

import 'activities_page.dart';
import 'chats_page.dart';
import 'feed_page.dart';
import 'friends_page.dart';
import 'me_page.dart';
import 'search_page.dart';
import 'shop_page.dart';

/// โครงหลักของแอป: แถบบน (ค้นหา/แชท) + แถบล่าง 5 แท็บ
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const _pages = <Widget>[
    FeedPage(),
    FriendsPage(),
    ActivitiesPage(),
    ShopPage(),
    MePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UDVC TW'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'ค้นหา',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'แชท',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatsPage())),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Friends'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'กิจกรรม'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'ME'),
        ],
      ),
    );
  }
}
