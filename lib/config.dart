/// ตั้งค่าการเชื่อมต่อ Supabase
/// Supabase Dashboard > Settings > API Keys : คัดลอก Project URL และ publishable key
/// (ห้ามใส่ secret key ในแอปเด็ดขาด)
class AppConfig {
  static const String supabaseUrl = 'https://YOUR-PROJECT-REF.supabase.co';
  static const String supabaseKey = 'sb_publishable_YOUR_KEY';

  /// โดเมนอีเมลภายในที่ใช้สร้างจากชื่อผู้ใช้ (ผู้ใช้ไม่ต้องกรอกอีเมล)
  static const String emailDomain = 'udvc-vibe.app';

  static bool get configured =>
      !supabaseUrl.contains('YOUR-PROJECT-REF') && !supabaseKey.contains('YOUR_KEY');
}

const List<String> kLevels = ['ปวช.1', 'ปวช.2', 'ปวช.3', 'ปวส.1', 'ปวส.2'];
const List<String> kMajors = [
  'เทคโนโลยีสารสนเทศ', 'คอมพิวเตอร์ธุรกิจ', 'การบัญชี', 'การตลาด', 'คหกรรมศาสตร์',
  'ออกแบบแฟชั่น', 'ช่างยนต์', 'ช่างไฟฟ้า', 'อื่น ๆ',
];
const List<String> kShopCategories = ['ชีท/หนังสือ', 'อุปกรณ์การเรียน', 'เสื้อผ้า', 'อื่นๆ'];
const List<String> kBuddyTypes = ['เมคเฟรน', 'เพื่อนติวหนังสือ', 'เพื่อนเล่นเกม', 'เพื่อนกินข้าว'];
