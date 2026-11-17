DateTime _dt(dynamic v) => DateTime.parse(v as String).toLocal();
Set<String> _ids(dynamic list, String key) =>
    ((list as List?) ?? const []).map((x) => (x as Map)[key] as String).toSet();

class Profile {
  final String id, username, name, bio, role;
  final String? level, major, avatarUrl;
  final DateTime createdAt;
  Profile({
    required this.id, required this.username, required this.name, required this.bio,
    required this.role, required this.createdAt, this.level, this.major, this.avatarUrl,
  });
  bool get isAdmin => role == 'admin';
  factory Profile.unknown(String id) =>
      Profile(id: id, username: '?', name: 'ผู้ใช้', bio: '', role: 'student', createdAt: DateTime.now());
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        username: j['username'] as String,
        name: j['name'] as String,
        bio: (j['bio'] ?? '') as String,
        role: (j['role'] ?? 'student') as String,
        level: j['level'] as String?,
        major: j['major'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        createdAt: _dt(j['created_at']),
      );
}

class Comment {
  final String id, authorId, body;
  final String? parentId;
  final DateTime createdAt;
  final Set<String> likes;
  final List<Comment> replies = [];
  Comment({
    required this.id, required this.authorId, required this.body,
    required this.createdAt, required this.likes, this.parentId,
  });
}

class Post {
  final String id, authorId, caption;
  final String? imageUrl;
  final bool isStory;
  final DateTime createdAt;
  final Set<String> likes;
  final List<Comment> comments; // เฉพาะความเห็นหลัก (ตอบกลับอยู่ใน replies)
  Post({
    required this.id, required this.authorId, required this.caption, required this.isStory,
    required this.createdAt, required this.likes, required this.comments, this.imageUrl,
  });
  int get commentCount => comments.fold(0, (a, c) => a + 1 + c.replies.length);

  factory Post.fromJson(Map<String, dynamic> j) {
    final all = ((j['comments'] as List?) ?? const []).map((c) {
      final m = c as Map<String, dynamic>;
      return Comment(
        id: m['id'] as String,
        authorId: m['author_id'] as String,
        body: m['body'] as String,
        parentId: m['parent_id'] as String?,
        createdAt: _dt(m['created_at']),
        likes: _ids(m['comment_likes'], 'user_id'),
      );
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final top = all.where((c) => c.parentId == null).toList();
    for (final r in all.where((c) => c.parentId != null)) {
      for (final t in top) {
        if (t.id == r.parentId) {
          t.replies.add(r);
          break;
        }
      }
    }
    return Post(
      id: j['id'] as String,
      authorId: j['author_id'] as String,
      caption: (j['caption'] ?? '') as String,
      imageUrl: j['image_url'] as String?,
      isStory: j['is_story'] as bool,
      createdAt: _dt(j['created_at']),
      likes: _ids(j['post_likes'], 'user_id'),
      comments: top,
    );
  }
}

class Product {
  final String id, sellerId, title, category, condition, contact;
  final double price;
  final String? imageUrl;
  final DateTime createdAt;
  Product({
    required this.id, required this.sellerId, required this.title, required this.price,
    required this.category, required this.condition, required this.contact,
    required this.createdAt, this.imageUrl,
  });
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        sellerId: j['seller_id'] as String,
        title: j['title'] as String,
        price: (j['price'] as num).toDouble(),
        category: (j['category'] ?? '') as String,
        condition: (j['condition'] ?? '') as String,
        contact: j['contact'] as String,
        imageUrl: j['image_url'] as String?,
        createdAt: _dt(j['created_at']),
      );
}

class Buddy {
  final String id, ownerId, type, title, bio;
  final String? imageUrl;
  Buddy({required this.id, required this.ownerId, required this.type, required this.title,
      required this.bio, this.imageUrl});
  factory Buddy.fromJson(Map<String, dynamic> j) => Buddy(
        id: j['id'] as String,
        ownerId: j['owner_id'] as String,
        type: j['type'] as String,
        title: j['title'] as String,
        bio: (j['bio'] ?? '') as String,
        imageUrl: j['image_url'] as String?,
      );
}

class EventItem {
  final String id, creatorId, title, place, note;
  final DateTime date;
  final String time; // HH:mm
  final String? imageUrl;
  final Set<String> rsvps;
  EventItem({
    required this.id, required this.creatorId, required this.title, required this.place,
    required this.note, required this.date, required this.time, required this.rsvps, this.imageUrl,
  });
  factory EventItem.fromJson(Map<String, dynamic> j) {
    final t = (j['event_time'] ?? '') as String;
    return EventItem(
      id: j['id'] as String,
      creatorId: j['creator_id'] as String,
      title: j['title'] as String,
      place: (j['place'] ?? '') as String,
      note: (j['note'] ?? '') as String,
      date: DateTime.parse(j['event_date'] as String),
      time: t.length >= 5 ? t.substring(0, 5) : '',
      imageUrl: j['image_url'] as String?,
      rsvps: _ids(j['event_rsvps'], 'user_id'),
    );
  }
}

class Report {
  final String id, reporterId, title, location, detail;
  final String? imageUrl;
  int status; // 0 รอตรวจสอบ 1 กำลังแก้ไข 2 แก้ไขแล้ว
  final DateTime createdAt;
  Report({
    required this.id, required this.reporterId, required this.title, required this.location,
    required this.detail, required this.status, required this.createdAt, this.imageUrl,
  });
  static const labels = ['รอตรวจสอบ 🟡', 'กำลังแก้ไข 🔵', 'แก้ไขแล้ว 🟢'];
  factory Report.fromJson(Map<String, dynamic> j) => Report(
        id: j['id'] as String,
        reporterId: j['reporter_id'] as String,
        title: j['title'] as String,
        location: j['location'] as String,
        detail: (j['detail'] ?? '') as String,
        imageUrl: j['image_url'] as String?,
        status: j['status'] as int,
        createdAt: _dt(j['created_at']),
      );
}

class Message {
  final String id, senderId, body;
  final String? imageUrl, postId;
  bool liked;
  final DateTime createdAt;
  Message({
    required this.id, required this.senderId, required this.body, required this.liked,
    required this.createdAt, this.imageUrl, this.postId,
  });
  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        body: (j['body'] ?? '') as String,
        imageUrl: j['image_url'] as String?,
        postId: j['post_id'] as String?,
        liked: (j['liked'] ?? false) as bool,
        createdAt: _dt(j['created_at']),
      );
}

class Chat {
  final String id, otherId;
  final DateTime createdAt;
  final List<Message> messages; // เรียงเก่า -> ใหม่
  Chat({required this.id, required this.otherId, required this.createdAt, required this.messages});
  Message? get last => messages.isEmpty ? null : messages.last;
  factory Chat.fromJson(Map<String, dynamic> j, String myId) {
    final msgs = ((j['messages'] as List?) ?? const [])
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Chat(
      id: j['id'] as String,
      otherId: (j['user_a'] as String) == myId ? j['user_b'] as String : j['user_a'] as String,
      createdAt: _dt(j['created_at']),
      messages: msgs,
    );
  }
}
