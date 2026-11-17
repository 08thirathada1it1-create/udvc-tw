# UDVC Vibe (Flutter + Supabase)

แอปชุมชนนักเรียนวิทยาลัยอาชีวศึกษาอุดรธานี เขียนด้วย Dart/Flutter แยกไฟล์ตามหน้า ต่อกับฐานข้อมูล Supabase

## โครงสร้างโค้ด (lib/)

| ไฟล์ | หน้าที่ |
|---|---|
| `main.dart` | จุดเริ่มต้นแอป เลือกหน้า (ตั้งค่า / ล็อกอิน / หน้าหลัก) |
| `config.dart` | **ใส่ Supabase URL และ key ที่นี่** + รายการระดับชั้น/สาขา/หมวด |
| `theme.dart` | ธีมสว่าง/มืด |
| `models/models.dart` | โครงสร้างข้อมูล (Profile, Post, Comment, Product, Buddy, EventItem, Report, Chat, Message) |
| `services/app_state.dart` | ศูนย์กลางข้อมูล: โหลด/บันทึก Supabase, realtime, สมัคร/ล็อกอิน, อัปโหลดรูป |
| `pages/auth_page.dart` | เข้าสู่ระบบ / สมัครสมาชิก |
| `pages/home_shell.dart` | แถบบน (🔍 ค้นหา, 💬 แชท) + แถบล่าง 5 แท็บ |
| `pages/feed_page.dart` | **Feed** (สตอรี่ + โพสต์ ปัดขวาเพื่อสร้าง) |
| `pages/create_post_page.dart` | สร้างโพสต์ / สตอรี่ (เลื่อนเข้าจากซ้าย) |
| `pages/friends_page.dart` | **Friends** (การ์ดปัดแมตช์ → เปิดแชท) |
| `pages/activities_page.dart` | **กิจกรรม** + แจ้งปัญหา |
| `pages/shop_page.dart` | **Shop** (กรองหมวด ติดต่อ ทักแชท) |
| `pages/me_page.dart` | **ME** (โปรไฟล์แบบ IG แก้ไขโปรไฟล์) |
| `pages/user_profile_page.dart` | โปรไฟล์ของผู้ใช้คนอื่น |
| `pages/chats_page.dart` | รายการแชท |
| `pages/chat_room_page.dart` | ห้องแชท (ถูกใจข้อความ ยกเลิกการส่ง ส่งรูป) |
| `pages/search_page.dart` | ค้นหา |
| `pages/admin_db_page.dart` | ดูข้อมูลทั้งหมดในฐานข้อมูล (เฉพาะ admin) |
| `widgets/post_card.dart` | การ์ดโพสต์ (แตะ 2 ครั้งถูกใจ) |
| `widgets/comments_sheet.dart` | ความเห็น ตอบกลับ ถูกใจความเห็น |
| `widgets/share_sheet.dart` | แชร์ลงสตอรี่ / ส่งให้เพื่อน |
| `widgets/story_tray.dart`, `story_viewer.dart` | แถบสตอรี่ และตัวดูสตอรี่ (แตะซ้าย/ขวา) |
| `widgets/profile_view.dart`, `item_viewer.dart` | โปรไฟล์ (แท็บโพสต์ \| ประกาศขาย \| การ์ด) |
| `widgets/common.dart` | วิดเจ็ตและฟอร์มที่ใช้ร่วมกัน |
| `supabase/schema.sql` | โครงสร้างฐานข้อมูลทั้งหมด (ตาราง, สิทธิ์ RLS, ที่เก็บรูป, realtime) |

## ขั้นตอนติดตั้ง

### 1) ตั้งค่า Supabase
1. สมัคร supabase.com แล้วสร้างโปรเจกต์ (เลือกภูมิภาค Singapore)
2. **SQL Editor → New query** วางทั้งไฟล์ `supabase/schema.sql` แล้วกด Run
3. **Authentication → Providers → Email** : ปิด **Confirm email** (แอปใช้ชื่อผู้ใช้ + รหัสผ่าน ไม่ใช้อีเมลจริง)
4. **Settings → API Keys** : คัดลอก *Project URL* และ *publishable key* (ขึ้นต้น `sb_publishable_`)
   ห้ามใส่ *secret key* ในแอป

### 2) สร้างโปรเจกต์ Flutter ใน VS Code
```bash
flutter create udvc_vibe --org th.ac.udvc
cd udvc_vibe
```
จากนั้น **คัดลอกทับ** โฟลเดอร์ `lib/` และไฟล์ `pubspec.yaml` จากโปรเจกต์นี้ลงไป และลบไฟล์ `test/widget_test.dart` (อ้างถึง MyApp เดิม)

```bash
flutter pub get
```

### 3) ใส่คีย์
แก้ `lib/config.dart` : `supabaseUrl` และ `supabaseKey`

### 4) ตั้งค่า Android
เปิด `android/app/src/main/AndroidManifest.xml` เพิ่มก่อน `<application ...>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
</queries>
```
### 5) ตั้งค่า iOS (ถ้าจะรันบน iPhone)
เพิ่มใน `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key><string>ใช้ถ่ายรูปสำหรับโพสต์และสินค้า</string>
<key>NSPhotoLibraryUsageDescription</key><string>ใช้เลือกรูปสำหรับโพสต์และสินค้า</string>
```
### 6) รัน
```bash
flutter run
```
สร้างไฟล์ติดตั้ง Android: `flutter build apk --release`

## ตั้งตัวเองเป็นผู้ดูแลระบบ (admin)
สมัครสมาชิกในแอปก่อน แล้วรันใน SQL Editor:
```sql
update public.profiles set role = 'admin' where username = 'ชื่อผู้ใช้ของคุณ';
```
admin จะเห็นปุ่ม 🗄️ ในหน้า ME, เปลี่ยนสถานะแจ้งปัญหาได้ และลบเนื้อหาที่ไม่เหมาะสมได้
ดูข้อมูลทั้งหมดได้ที่ Supabase → Table Editor เช่นกัน

## หมายเหตุ
- นักเรียนบางคนอายุต่ำกว่า 18 ปี ควรมีหน้านโยบายความเป็นส่วนตัวและขอความยินยอมตาม พ.ร.บ.คุ้มครองข้อมูลส่วนบุคคล
- แผนฟรีของ Supabase จะพักโปรเจกต์ถ้าไม่มีการใช้งานนาน ถ้าใช้งานจริงควรพิจารณาแผน Pro
- เมื่อลบโพสต์/สินค้า ไฟล์รูปใน Storage ยังไม่ถูกลบอัตโนมัติ
