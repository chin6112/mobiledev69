import 'package:flutter/material.dart';

import '../viewmodels/trip_view_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.userName,
    required this.trip,
    required this.onOpenPlanner,
    required this.onCreateTrip,
  });

  final String userName;
  final TripViewModel trip;
  final void Function([String? focus]) onOpenPlanner;
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('สวัสดี, $userName'),
        const SizedBox(height: 4),
        Text(
          'พร้อมออกเดินทางหรือยัง?',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(Icons.add_rounded),
            label: const Text('สร้างทริปใหม่'),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF176B87),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ทริปที่กำลังจะมาถึง',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                trip.tripTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_dateLabel(trip.tripStart)} - ${_dateLabel(trip.tripEnd)}  •  ${trip.tripDestination}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpenPlanner,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('เปิดแผนทริป'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF176B87),
                ),
              ),
            ],
          ),
        ),
        if (trip.syncing)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        const SizedBox(height: 24),
        Text(
          'สิ่งที่ต้องจัดการ',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.hotel_rounded,
          title: 'เลือกที่พัก',
          subtitle: 'ยังไม่มีใครจองที่พักสำหรับคืนแรก',
          badge: 'ด่วน',
          onTap: () => onOpenPlanner('ที่พัก'),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.confirmation_number_rounded,
          title: 'ตั๋วรถไฟ',
          subtitle: 'มินท์รับผิดชอบ • ครบกำหนดพรุ่งนี้',
          badge: 'งาน',
          onTap: () => onOpenPlanner('ตั๋วรถไฟ'),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.backpack_rounded,
          title: 'เตรียมของใช้ส่วนกลาง',
          subtitle: 'เช็กลิสต์ 6 จาก 8 รายการ',
          badge: 'ทีม',
          onTap: () => onOpenPlanner('ของใช้ส่วนกลาง'),
        ),
      ],
    );
  }

  static String _dateLabel(DateTime date) =>
      '${date.day} ${_months[date.month]}';

  static const _months = [
    '',
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE4F1F5),
        child: Icon(icon, color: const Color(0xFF176B87)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Chip(label: Text(badge), visualDensity: VisualDensity.compact),
    ),
  );
}
