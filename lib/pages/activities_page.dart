import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'user_profile_page.dart';

/// หน้ากิจกรรม: กิจกรรมของวิทยาลัย + แจ้งปัญหา
class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});
  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  bool showReports = false;

  Future<void> _pickCupertinoDate(BuildContext context, ValueNotifier<DateTime?> date) async {
    final now = DateTime.now();
    DateTime temp = date.value ?? now;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 280,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('เลื่อนเลือก วัน / เดือน / ปี', style: TextStyle(fontWeight: FontWeight.bold)),
                FilledButton(
                  onPressed: () {
                    date.value = temp;
                    Navigator.pop(ctx);
                  },
                  child: const Text('ตกลง'),
                ),
              ]),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: temp,
                minimumYear: now.year - 1,
                maximumYear: now.year + 3,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickCupertinoTime(BuildContext context, ValueNotifier<TimeOfDay> time) async {
    final now = DateTime.now();
    DateTime temp = DateTime(now.year, now.month, now.day, time.value.hour, time.value.minute);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 280,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('เลื่อนเลือกเวลา (24 ชม.)', style: TextStyle(fontWeight: FontWeight.bold)),
                FilledButton(
                  onPressed: () {
                    time.value = TimeOfDay(hour: temp.hour, minute: temp.minute);
                    Navigator.pop(ctx);
                  },
                  child: const Text('ตกลง'),
                ),
              ]),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: temp,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _addEvent() {
    final s = context.read<AppState>();
    final title = TextEditingController();
    final place = TextEditingController();
    final note = TextEditingController();
    final image = ValueNotifier<Uint8List?>(null);
    final date = ValueNotifier<DateTime?>(DateTime.now());
    final time = ValueNotifier<TimeOfDay>(const TimeOfDay(hour: 9, minute: 0));
    showFormSheet(
      context,
      title: 'เพิ่มกิจกรรม',
      fields: [
        textField('ชื่อกิจกรรม *', title, maxLength: 80),
        ValueListenableBuilder<DateTime?>(
          valueListenable: date,
          builder: (ctx, d, _) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(d == null ? 'เลื่อนเลือก วัน / เดือน / ปี *' : 'วันที่: ${fmtDate(d)}'),
              onPressed: () => _pickCupertinoDate(ctx, date),
            ),
          ),
        ),
        ValueListenableBuilder<TimeOfDay>(
          valueListenable: time,
          builder: (ctx, t, _) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.access_time),
              label: Text('เวลา ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} น.'),
              onPressed: () => _pickCupertinoTime(ctx, time),
            ),
          ),
        ),
        textField('สถานที่', place, maxLength: 80),
        textField('หมายเหตุ', note, lines: 3, maxLength: 300),
        ImagePickerBox(bytes: image),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty) throw 'กรอกชื่อกิจกรรม';
        if (date.value == null) throw 'เลือกวันที่';
        await s.addEvent(
          title: title.text.trim(), date: date.value!, time: time.value,
          place: place.text.trim(), note: note.text.trim(), image: image.value,
        );
      },
    ).whenComplete(() {
      title.dispose();
      place.dispose();
      note.dispose();
      image.dispose();
      date.dispose();
      time.dispose();
    });
  }

  void _addReport() {
    final s = context.read<AppState>();
    final title = TextEditingController();
    final loc = TextEditingController();
    final detail = TextEditingController();
    final image = ValueNotifier<Uint8List?>(null);
    showFormSheet(
      context,
      title: 'แจ้งปัญหาในวิทยาลัย',
      fields: [
        textField('ปัญหาที่พบ *', title, hint: 'เช่น แอร์ห้อง Lab 421 ไม่เย็น', maxLength: 100),
        textField('สถานที่ *', loc, hint: 'อาคาร / ชั้น / ห้อง', maxLength: 80),
        textField('รายละเอียด', detail, lines: 3, maxLength: 400),
        ImagePickerBox(bytes: image),
      ],
      onSubmit: () async {
        if (title.text.trim().isEmpty || loc.text.trim().isEmpty) throw 'กรอกปัญหาและสถานที่';
        await s.addReport(title: title.text.trim(), location: loc.text.trim(), detail: detail.text.trim(), image: image.value);
      },
    ).whenComplete(() {
      title.dispose();
      loc.dispose();
      detail.dispose();
      image.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: showReports ? _addReport : _addEvent,
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('กิจกรรม')),
              ButtonSegment(value: true, label: Text('แจ้งปัญหา')),
            ],
            selected: {showReports},
            onSelectionChanged: (v) => setState(() => showReports = v.first),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => s.reload([showReports ? 'reports' : 'events']),
            child: showReports ? _reports(s) : _events(s),
          ),
        ),
      ]),
    );
  }

  Widget _events(AppState s) {
    if (s.events.isEmpty) {
      return ListView(children: const [SizedBox(height: 80), EmptyState('ยังไม่มีกิจกรรม กด + เพื่อเพิ่ม')]);
    }
    final today = DateTime.now();
    return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 80), children: [
      for (final e in s.events)
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (e.imageUrl != null) NetImage(e.imageUrl!, width: double.infinity),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '📅 ${fmtDate(e.date)}${e.time.isNotEmpty ? ' ${e.time} น.' : ''}'
                  '${e.place.isNotEmpty ? ' · 📍 ${e.place}' : ''}'
                  '${e.date.isBefore(DateTime(today.year, today.month, today.day)) ? ' · (ผ่านไปแล้ว)' : ''}',
                ),
                InkWell(
                  onTap: () => openProfile(context, e.creatorId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'โดย @${s.pf(e.creatorId).username}',
                      style: const TextStyle(fontSize: 12, color: kAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (e.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(e.note)),
                const SizedBox(height: 8),
                Row(children: [
                  FilledButton.tonal(
                    onPressed: () => s.toggleRsvp(e),
                    child: Text('${e.rsvps.contains(s.me!.id) ? '✅ เข้าร่วมแล้ว' : 'เข้าร่วม'} · ${e.rsvps.length}'),
                  ),
                  const Spacer(),
                  if (e.creatorId == s.me!.id || s.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirmDelete(context) && mounted) await guard(context, () => s.deleteEvent(e.id));
                      },
                    ),
                ]),
              ]),
            ),
          ]),
        ),
    ]);
  }

  Widget _reports(AppState s) {
    if (s.reports.isEmpty) {
      return ListView(children: const [SizedBox(height: 80), EmptyState('ยังไม่มีเรื่องแจ้งปัญหา กด + เพื่อแจ้ง')]);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 80), children: [
      for (final r in s.reports) _reportCard(s, r),
    ]);
  }

  Widget _reportCard(AppState s, Report r) {
    final who = s.pf(r.reporterId);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (r.imageUrl != null) NetImage(r.imageUrl!, width: double.infinity),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('📍 ${r.location} · ${fmtDate(r.createdAt)}${r.reporterId != s.me!.id ? ' · @${who.username}' : ''}'),
            if (r.detail.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.detail)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              s.isAdmin
                  ? FilledButton.tonal(
                      onPressed: () => guard(context, () => s.cycleReportStatus(r)),
                      child: Text(Report.labels[r.status]),
                    )
                  : Chip(label: Text(Report.labels[r.status])),
              if (r.reporterId == s.me!.id || s.isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirmDelete(context) && mounted) await guard(context, () => s.deleteReport(r.id));
                  },
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
