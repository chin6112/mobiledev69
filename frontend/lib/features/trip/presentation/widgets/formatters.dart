const _months = [
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

String shortDate(DateTime date) => '${date.day} ${_months[date.month]}';

String dateRange(DateTime start, DateTime end) =>
    '${shortDate(start)} - ${shortDate(end)} ${end.year}';

String baht(double amount) => '฿${amount.toStringAsFixed(2)}';
