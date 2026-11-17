const List<String> _months = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
];
String _two(int n) => n.toString().padLeft(2, '0');

String ago(DateTime t) {
  final m = DateTime.now().difference(t).inMinutes;
  if (m < 1) return 'เมื่อสักครู่';
  if (m < 60) return '$m นาทีที่แล้ว';
  if (m < 1440) return '${m ~/ 60} ชม.ที่แล้ว';
  return '${m ~/ 1440} วันที่แล้ว';
}

/// วันที่แบบไทย (พ.ศ.) เช่น 9 พ.ย. 2569
String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year + 543}';

/// เวลา 24 ชั่วโมง เช่น 09:30
String fmtTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String fmtDateTime(DateTime d) => '${fmtDate(d)} ${fmtTime(d)} น.';

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// วันนี้ => เวลา, วันอื่น => วัน เดือน
String shortTime(DateTime t) =>
    sameDay(t, DateTime.now()) ? fmtTime(t) : '${t.day} ${_months[t.month - 1]}';

String dayLabel(DateTime t) =>
    '${sameDay(t, DateTime.now()) ? 'วันนี้' : '${t.day} ${_months[t.month - 1]}'} ${fmtTime(t)}';
