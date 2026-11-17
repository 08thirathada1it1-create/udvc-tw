import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/models.dart';

/// แปลงข้อผิดพลาดเป็นข้อความที่อ่านง่าย
String errText(Object e) {
  if (e is AuthException) return e.message;
  if (e is PostgrestException) return e.message;
  if (e is StorageException) return e.message;
  if (e is String) return e;
  return e.toString();
}

/// ศูนย์กลางข้อมูลและการเชื่อมต่อ Supabase ของทั้งแอป
class AppState extends ChangeNotifier {
  final SupabaseClient sb = Supabase.instance.client;

  Profile? me;
  Map<String, Profile> profiles = {};
  List<Post> posts = [];
  List<Product> products = [];
  List<Buddy> buddies = [];
  List<EventItem> events = [];
  List<Report> reports = [];
  List<Chat> chats = [];

  ThemeMode themeMode = ThemeMode.system;
  Set<String> passed = {};
  bool booting = true;

  SharedPreferences? _prefs;
  RealtimeChannel? _channel;
  Timer? _debounce;
  final Set<String> _pending = {};
  StreamSubscription<AuthState>? _authSub;

  bool get isAdmin => me?.isAdmin ?? false;
  Profile pf(String id) => profiles[id] ?? Profile.unknown(id);
  Post? postById(String id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Chat? chatById(String id) {
    for (final c in chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------------- เริ่มต้น
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    passed = (_prefs!.getStringList('passed') ?? []).toSet();
    final t = _prefs!.getInt('theme') ?? 0;
    themeMode = ThemeMode.values[t.clamp(0, 2).toInt()];
    _authSub = sb.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut && me != null) boot();
    });
    await boot();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _debounce?.cancel();
    _unsubscribe();
    super.dispose();
  }

  late final Map<String, Future<void> Function()> _loaders = {
    'profiles': _loadProfiles,
    'posts': _loadPosts,
    'products': _loadProducts,
    'buddies': _loadBuddies,
    'events': _loadEvents,
    'reports': _loadReports,
    'chats': _loadChats,
  };

  Future<void> boot() async {
    final session = sb.auth.currentSession;
    if (session == null) {
      me = null;
      posts = []; products = []; buddies = []; events = []; reports = []; chats = [];
      _unsubscribe();
      booting = false;
      notifyListeners();
      return;
    }
    try {
      await _loadProfiles();
      me = profiles[session.user.id];
      if (me == null) {
        await sb.auth.signOut();
        booting = false;
        notifyListeners();
        return;
      }
      await Future.wait(['posts', 'products', 'buddies', 'events', 'reports', 'chats']
          .map((n) => _loaders[n]!().catchError((Object e) {})));
      _subscribe();
    } catch (e) {
      debugPrint('boot error: $e');
    }
    booting = false;
    notifyListeners();
  }

  Future<void> reload(List<String> names) async {
    await Future.wait(names.map((n) => _loaders[n]!().catchError((Object e) {
          debugPrint('load $n: $e');
        })));
    if (me != null) me = profiles[me!.id] ?? me;
    notifyListeners();
  }

  // ----------------------------------------------------------------- realtime
  void _subscribe() {
    _unsubscribe();
    final ch = sb.channel('db');
    const map = {
      'profiles': 'profiles', 'posts': 'posts', 'post_likes': 'posts', 'comments': 'posts',
      'comment_likes': 'posts', 'products': 'products', 'buddies': 'buddies', 'events': 'events',
      'event_rsvps': 'events', 'reports': 'reports', 'messages': 'chats', 'chats': 'chats',
    };
    map.forEach((table, name) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) => _sched(name),
      );
    });
    ch.subscribe();
    _channel = ch;
  }

  void _unsubscribe() {
    if (_channel != null) {
      sb.removeChannel(_channel!);
      _channel = null;
    }
  }

  void _sched(String name) {
    _pending.add(name);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final l = _pending.toList();
      _pending.clear();
      reload(l);
    });
  }

  // -------------------------------------------------------------- โหลดข้อมูล
  Future<void> _loadProfiles() async {
    final data = await sb.from('profiles').select();
    profiles = {
      for (final j in data) (j['id'] as String): Profile.fromJson(j),
    };
  }

  Future<void> _loadPosts() async {
    final data = await sb
        .from('posts')
        .select('id,author_id,caption,image_url,is_story,created_at,post_likes(user_id),'
            'comments(id,parent_id,author_id,body,created_at,comment_likes(user_id))')
        .order('created_at', ascending: false)
        .limit(150);
    posts = data.map((j) => Post.fromJson(j)).toList();
  }

  Future<void> _loadProducts() async {
    final data = await sb.from('products').select().order('created_at', ascending: false).limit(200);
    products = data.map((j) => Product.fromJson(j)).toList();
  }

  Future<void> _loadBuddies() async {
    final data = await sb.from('buddies').select().order('created_at', ascending: false).limit(200);
    buddies = data.map((j) => Buddy.fromJson(j)).toList();
  }

  Future<void> _loadEvents() async {
    final data = await sb
        .from('events')
        .select('*,event_rsvps(user_id)')
        .order('event_date', ascending: true)
        .limit(200);
    events = data.map((j) => EventItem.fromJson(j)).toList();
  }

  Future<void> _loadReports() async {
    final data = await sb.from('reports').select().order('created_at', ascending: false).limit(200);
    reports = data.map((j) => Report.fromJson(j)).toList();
  }

  Future<void> _loadChats() async {
    final data = await sb
        .from('chats')
        .select('id,user_a,user_b,created_at,'
            'messages(id,sender_id,body,image_url,post_id,liked,created_at)')
        .order('created_at', referencedTable: 'messages', ascending: false)
        .limit(200, referencedTable: 'messages');
    chats = data.map((j) => Chat.fromJson(j, me!.id)).toList();
  }

  // ---------------------------------------------------------- สมัคร / เข้าระบบ
  String _email(String username) => '$username@${AppConfig.emailDomain}';

  Future<void> signIn(String username, String password) async {
    try {
      await sb.auth.signInWithPassword(email: _email(username), password: password);
    } on AuthException {
      throw 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
    }
    await boot();
  }

  Future<void> signUp({
    required String username,
    required String password,
    required String name,
    required String level,
    required String major,
  }) async {
    final ok = await sb.rpc('username_available', params: {'u': username});
    if (ok == false) throw 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';
    final res = await sb.auth.signUp(
      email: _email(username),
      password: password,
      data: {'username': username, 'name': name, 'level': level, 'major': major},
    );
    if (res.session == null) {
      throw 'สมัครแล้ว แต่ต้องปิด "Confirm email" ใน Supabase ก่อน (Authentication > Providers > Email)';
    }
    await boot();
  }

  Future<void> signOut() async {
    await sb.auth.signOut();
    await boot();
  }

  // -------------------------------------------------------------- ตั้งค่า
  Future<void> cycleTheme() async {
    themeMode = ThemeMode.values[(themeMode.index + 1) % 3];
    await _prefs?.setInt('theme', themeMode.index);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String? level,
    required String? major,
    required String bio,
    Uint8List? newAvatar,
  }) async {
    final url = newAvatar != null ? await upload(newAvatar) : me!.avatarUrl;
    await sb.from('profiles').update({
      'name': name, 'level': level, 'major': major, 'bio': bio, 'avatar_url': url,
    }).eq('id', me!.id);
    await reload(['profiles']);
  }

  // ----------------------------------------------------------------- รูปภาพ
  Future<String?> upload(Uint8List? bytes) async {
    if (bytes == null) return null;
    final path = '${me!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await sb.storage
        .from('images')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return sb.storage.from('images').getPublicUrl(path);
  }

  // ------------------------------------------------------------ โพสต์ / สตอรี่
  Future<void> createPost({required String caption, Uint8List? image, required bool story}) async {
    final url = await upload(image);
    await sb.from('posts').insert({'caption': caption, 'image_url': url, 'is_story': story});
    await reload(['posts']);
  }

  Future<void> deletePost(String id) async {
    await sb.from('posts').delete().eq('id', id);
    await reload(['posts']);
  }

  Future<void> toggleLike(Post p, {bool? force}) async {
    final liked = p.likes.contains(me!.id);
    final want = force ?? !liked;
    if (want == liked) return;
    if (want) {
      p.likes.add(me!.id);
    } else {
      p.likes.remove(me!.id);
    }
    notifyListeners();
    try {
      if (want) {
        await sb.from('post_likes').insert({'post_id': p.id});
      } else {
        await sb.from('post_likes').delete().match({'post_id': p.id, 'user_id': me!.id});
      }
    } catch (e) {
      await reload(['posts']);
    }
  }

  Future<void> addComment(String postId, String body, {String? parentId}) async {
    await sb.from('comments').insert({'post_id': postId, 'parent_id': parentId, 'body': body});
    await reload(['posts']);
  }

  Future<void> deleteComment(String id) async {
    await sb.from('comments').delete().eq('id', id);
    await reload(['posts']);
  }

  Future<void> toggleCommentLike(Comment c) async {
    final liked = c.likes.contains(me!.id);
    if (liked) {
      c.likes.remove(me!.id);
    } else {
      c.likes.add(me!.id);
    }
    notifyListeners();
    try {
      if (liked) {
        await sb.from('comment_likes').delete().match({'comment_id': c.id, 'user_id': me!.id});
      } else {
        await sb.from('comment_likes').insert({'comment_id': c.id});
      }
    } catch (e) {
      await reload(['posts']);
    }
  }

  Future<void> shareToStory(Post p) async {
    await sb.from('posts').insert({'caption': p.caption, 'image_url': p.imageUrl, 'is_story': true});
    await reload(['posts']);
  }

  Future<void> sendPostToChat(String chatId, Post p) async {
    final text = p.caption.length > 60 ? p.caption.substring(0, 60) : p.caption;
    await sb.from('messages').insert({'chat_id': chatId, 'body': '📎 โพสต์: $text', 'post_id': p.id});
    await reload(['chats']);
  }

  // ------------------------------------------------------------------ สินค้า
  Future<void> addProduct({
    required String title,
    required double price,
    required String category,
    required String condition,
    required String contact,
    Uint8List? image,
  }) async {
    final url = await upload(image);
    await sb.from('products').insert({
      'title': title, 'price': price, 'category': category,
      'condition': condition, 'contact': contact, 'image_url': url,
    });
    await reload(['products']);
  }

  Future<void> deleteProduct(String id) async {
    await sb.from('products').delete().eq('id', id);
    await reload(['products']);
  }

  Future<void> sendProductToChat(String chatId, Product m) async {
    final p = m.price % 1 == 0 ? m.price.toInt() : m.price;
    await sb.from('messages').insert({
      'chat_id': chatId,
      'body': '🛍️ สนใจสินค้า: ${m.title} (฿$p)',
      'image_url': m.imageUrl,
    });
    await reload(['chats']);
  }

  // ------------------------------------------------------------------ เพื่อน
  Future<void> addBuddy({
    required String type,
    required String title,
    required String bio,
    required Uint8List image,
  }) async {
    final url = await upload(image);
    await sb.from('buddies').insert({'type': type, 'title': title, 'bio': bio, 'image_url': url});
    await reload(['buddies']);
  }

  Future<void> deleteBuddy(String id) async {
    await sb.from('buddies').delete().eq('id', id);
    await reload(['buddies']);
  }

  Future<void> pass(String id) async {
    passed.add(id);
    await _prefs?.setStringList('passed', passed.toList());
    notifyListeners();
  }

  Future<void> resetPassed() async {
    passed.clear();
    await _prefs?.setStringList('passed', []);
    notifyListeners();
  }

  /// เริ่มแชทกับผู้ใช้ (ถ้ามีห้องอยู่แล้วจะคืนห้องเดิม) คืนค่า id ของห้อง
  Future<String> startChat(String otherUserId) async {
    final id = await sb.rpc('start_chat', params: {'other': otherUserId});
    await reload(['chats']);
    return id as String;
  }

  // -------------------------------------------------------------------- แชท
  Future<void> sendMessage(String chatId, {String? body, Uint8List? image}) async {
    final url = await upload(image);
    await sb.from('messages').insert({'chat_id': chatId, 'body': body ?? '', 'image_url': url});
    await reload(['chats']);
  }

  Future<void> unsend(String messageId) async {
    await sb.from('messages').delete().eq('id', messageId);
    await reload(['chats']);
  }

  Future<void> toggleMessageLike(Message m) async {
    m.liked = !m.liked;
    notifyListeners();
    try {
      await sb.rpc('toggle_message_like', params: {'msg': m.id});
    } catch (e) {
      await reload(['chats']);
    }
  }

  // ---------------------------------------------------------------- กิจกรรม
  Future<void> addEvent({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required String place,
    required String note,
    Uint8List? image,
  }) async {
    final url = await upload(image);
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final t = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await sb.from('events').insert({
      'title': title, 'event_date': d, 'event_time': t, 'place': place, 'note': note, 'image_url': url,
    });
    await reload(['events']);
  }

  Future<void> deleteEvent(String id) async {
    await sb.from('events').delete().eq('id', id);
    await reload(['events']);
  }

  Future<void> toggleRsvp(EventItem e) async {
    final joined = e.rsvps.contains(me!.id);
    if (joined) {
      e.rsvps.remove(me!.id);
    } else {
      e.rsvps.add(me!.id);
    }
    notifyListeners();
    try {
      if (joined) {
        await sb.from('event_rsvps').delete().match({'event_id': e.id, 'user_id': me!.id});
      } else {
        await sb.from('event_rsvps').insert({'event_id': e.id});
      }
    } catch (_) {
      await reload(['events']);
    }
  }

  // ------------------------------------------------------------- แจ้งปัญหา
  Future<void> addReport({
    required String title,
    required String location,
    required String detail,
    Uint8List? image,
  }) async {
    final url = await upload(image);
    await sb.from('reports').insert({
      'title': title, 'location': location, 'detail': detail, 'image_url': url,
    });
    await reload(['reports']);
  }

  Future<void> deleteReport(String id) async {
    await sb.from('reports').delete().eq('id', id);
    await reload(['reports']);
  }

  Future<void> cycleReportStatus(Report r) async {
    await sb.from('reports').update({'status': (r.status + 1) % 3}).eq('id', r.id);
    await reload(['reports']);
  }

  // ------------------------------------------------------- ส่งออกข้อมูล (admin)
  String exportJson() {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'users': profiles.values
          .map((u) => {
                'id': u.id, 'username': u.username, 'name': u.name, 'level': u.level,
                'major': u.major, 'role': u.role, 'created_at': u.createdAt.toIso8601String(),
              })
          .toList(),
      'posts': posts
          .map((p) => {
                'id': p.id, 'author': pf(p.authorId).username, 'story': p.isStory,
                'caption': p.caption, 'likes': p.likes.length, 'comments': p.commentCount,
                'created_at': p.createdAt.toIso8601String(),
              })
          .toList(),
      'products': products
          .map((m) => {
                'id': m.id, 'seller': pf(m.sellerId).username, 'title': m.title, 'price': m.price,
                'category': m.category, 'contact': m.contact,
                'created_at': m.createdAt.toIso8601String(),
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
