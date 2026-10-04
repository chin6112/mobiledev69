import 'package:flutter/material.dart';

String? _required(String? value) =>
    (value == null || value.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null;

String? _positiveNumber(String? value) {
  final number = double.tryParse((value ?? '').replaceAll(',', ''));
  return (number == null || number <= 0) ? 'กรุณากรอกจำนวนที่มากกว่า 0' : null;
}

Future<T?> _formDialog<T>({
  required BuildContext context,
  required String title,
  required String submitLabel,
  required List<Widget> Function(StateSetter setState) fields,
  required T Function() result,
}) {
  final formKey = GlobalKey<FormState>();
  return showDialog<T>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: fields(setState)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, result());
              }
            },
            child: Text(submitLabel),
          ),
        ],
      ),
    ),
  );
}

Future<({String title, String destination})?> showTripDialog(
  BuildContext context,
) {
  final title = TextEditingController();
  final destination = TextEditingController();
  return _formDialog(
    context: context,
    title: 'สร้างทริปใหม่',
    submitLabel: 'สร้างทริป',
    fields: (_) => [
      TextFormField(
        controller: title,
        autofocus: true,
        validator: _required,
        decoration: const InputDecoration(labelText: 'ชื่อทริป'),
      ),
      TextFormField(
        controller: destination,
        validator: _required,
        decoration: const InputDecoration(labelText: 'จุดหมาย'),
      ),
    ],
    result: () =>
        (title: title.text.trim(), destination: destination.text.trim()),
  ).whenComplete(() {
    title.dispose();
    destination.dispose();
  });
}

Future<({String description, double amount})?> showExpenseDialog(
  BuildContext context,
) {
  final description = TextEditingController();
  final amount = TextEditingController();
  return _formDialog(
    context: context,
    title: 'เพิ่มค่าใช้จ่าย',
    submitLabel: 'เพิ่มรายการ',
    fields: (_) => [
      TextFormField(
        controller: description,
        autofocus: true,
        validator: _required,
        decoration: const InputDecoration(labelText: 'รายการ'),
      ),
      TextFormField(
        controller: amount,
        keyboardType: TextInputType.number,
        validator: _positiveNumber,
        decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
      ),
    ],
    result: () => (
      description: description.text.trim(),
      amount: double.parse(amount.text.replaceAll(',', '')),
    ),
  ).whenComplete(() {
    description.dispose();
    amount.dispose();
  });
}

Future<({String title, String slotType, int capacity, double price})?>
showSlotDialog(BuildContext context) {
  final title = TextEditingController();
  final capacity = TextEditingController(text: '1');
  final price = TextEditingController(text: '0');
  var slotType = 'activity';
  return _formDialog(
    context: context,
    title: 'เพิ่มรายการจอง',
    submitLabel: 'บันทึก',
    fields: (setState) => [
      TextFormField(
        controller: title,
        autofocus: true,
        validator: _required,
        decoration: const InputDecoration(labelText: 'ชื่อรายการ'),
      ),
      DropdownButtonFormField<String>(
        initialValue: slotType,
        decoration: const InputDecoration(labelText: 'ประเภท'),
        items: const [
          DropdownMenuItem(value: 'transport', child: Text('การเดินทาง')),
          DropdownMenuItem(value: 'accommodation', child: Text('ที่พัก')),
          DropdownMenuItem(value: 'activity', child: Text('กิจกรรม')),
        ],
        onChanged: (value) => setState(() => slotType = value ?? slotType),
      ),
      TextFormField(
        controller: capacity,
        keyboardType: TextInputType.number,
        validator: (value) =>
            (int.tryParse(value ?? '') ?? 0) < 1 ? 'อย่างน้อย 1 ที่' : null,
        decoration: const InputDecoration(labelText: 'จำนวนที่'),
      ),
      TextFormField(
        controller: price,
        keyboardType: TextInputType.number,
        validator: (value) =>
            (double.tryParse(value ?? '') ?? -1) < 0 ? 'ราคาไม่ถูกต้อง' : null,
        decoration: const InputDecoration(labelText: 'ราคา/คน'),
      ),
    ],
    result: () => (
      title: title.text.trim(),
      slotType: slotType,
      capacity: int.parse(capacity.text),
      price: double.parse(price.text),
    ),
  ).whenComplete(() {
    title.dispose();
    capacity.dispose();
    price.dispose();
  });
}

Future<String?> showTaskDialog(BuildContext context) {
  final title = TextEditingController();
  return _formDialog(
    context: context,
    title: 'เพิ่มงานเตรียมทริป',
    submitLabel: 'เพิ่มงาน',
    fields: (_) => [
      TextFormField(
        controller: title,
        autofocus: true,
        validator: _required,
        decoration: const InputDecoration(labelText: 'ชื่องาน'),
      ),
    ],
    result: () => title.text.trim(),
  ).whenComplete(title.dispose);
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
