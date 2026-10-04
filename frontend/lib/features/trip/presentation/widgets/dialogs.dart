import 'package:flutter/material.dart';

import '../../domain/trip_models.dart';

String? _required(String? value) =>
    (value == null || value.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null;

String? _positiveNumber(String? value) {
  final number = double.tryParse((value ?? '').replaceAll(',', ''));
  return (number == null || number <= 0) ? 'กรุณากรอกจำนวนที่มากกว่า 0' : null;
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    ) ??
    false;

typedef TripFormValue = ({
  String title,
  String destination,
  DateTime start,
  DateTime end,
});

Future<TripFormValue?> showTripDialog(BuildContext context, {Trip? initial}) =>
    showDialog<TripFormValue>(
      context: context,
      builder: (context) => _TripDialog(initial: initial),
    );

class _TripDialog extends StatefulWidget {
  const _TripDialog({this.initial});

  final Trip? initial;

  @override
  State<_TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<_TripDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _destination = TextEditingController(
    text: widget.initial?.destination,
  );
  late DateTime? _start = widget.initial?.startDate;
  late DateTime? _end = widget.initial?.endDate;

  @override
  void dispose() {
    _title.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isStart}) async {
    final now = DateTime.now();
    final current = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? _start ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
    _formKey.currentState?.validate();
  }

  String _label(DateTime? date) => date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Widget _dateField(String label, DateTime? value, bool isStart) =>
      TextFormField(
        key: ValueKey('$label-${value?.toIso8601String()}'),
        initialValue: _label(value),
        readOnly: true,
        onTap: () => _pick(isStart: isStart),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        validator: (_) {
          if (value == null) return 'กรุณาเลือกวันที่';
          if (!isStart && _start != null && value.isBefore(_start!)) {
            return 'วันสิ้นสุดต้องไม่ก่อนวันเริ่ม';
          }
          return null;
        },
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'สร้างทริปใหม่' : 'แก้ไขทริป'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              validator: _required,
              decoration: const InputDecoration(labelText: 'ชื่อทริป'),
            ),
            TextFormField(
              controller: _destination,
              validator: _required,
              decoration: const InputDecoration(labelText: 'จุดหมาย'),
            ),
            _dateField('วันเริ่มต้น', _start, true),
            _dateField('วันสิ้นสุด', _end, false),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, (
              title: _title.text.trim(),
              destination: _destination.text.trim(),
              start: _start!,
              end: _end!,
            ));
          }
        },
        child: Text(widget.initial == null ? 'สร้างทริป' : 'บันทึก'),
      ),
    ],
  );
}

Future<({String description, double amount})?> showExpenseDialog(
  BuildContext context, {
  Expense? initial,
}) => showDialog(
  context: context,
  builder: (context) => _SimpleFormDialog<({String description, double amount})>(
    title: initial == null ? 'เพิ่มค่าใช้จ่าย' : 'แก้ไขค่าใช้จ่าย',
    submitLabel: initial == null ? 'เพิ่มรายการ' : 'บันทึก',
    builder: (formKey) {
      final description = TextEditingController(text: initial?.description);
      final amount = TextEditingController(
        text: initial == null ? '' : initial.amount.toStringAsFixed(2),
      );
      return _FormBody(
        controllers: [description, amount],
        fields: (_) => [
          TextFormField(
            controller: description,
            autofocus: true,
            validator: _required,
            decoration: const InputDecoration(labelText: 'รายการ'),
          ),
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _positiveNumber,
            decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
          ),
        ],
        result: () => (
          description: description.text.trim(),
          amount: double.parse(amount.text.replaceAll(',', '')),
        ),
      );
    },
  ),
);

Future<({String title, String slotType, int capacity, double price})?>
showSlotDialog(BuildContext context) => showDialog(
  context: context,
  builder: (context) =>
      _SimpleFormDialog<
        ({String title, String slotType, int capacity, double price})
      >(
        title: 'เพิ่มรายการจอง',
        submitLabel: 'บันทึก',
        builder: (formKey) {
          final title = TextEditingController();
          final capacity = TextEditingController(text: '1');
          final price = TextEditingController(text: '0');
          var slotType = 'activity';
          return _FormBody(
            controllers: [title, capacity, price],
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
                  DropdownMenuItem(
                    value: 'transport',
                    child: Text('การเดินทาง'),
                  ),
                  DropdownMenuItem(
                    value: 'accommodation',
                    child: Text('ที่พัก'),
                  ),
                  DropdownMenuItem(value: 'activity', child: Text('กิจกรรม')),
                ],
                onChanged: (value) =>
                    setState(() => slotType = value ?? slotType),
              ),
              TextFormField(
                controller: capacity,
                keyboardType: TextInputType.number,
                validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                    ? 'อย่างน้อย 1 ที่'
                    : null,
                decoration: const InputDecoration(labelText: 'จำนวนที่'),
              ),
              TextFormField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) => (double.tryParse(value ?? '') ?? -1) < 0
                    ? 'ราคาไม่ถูกต้อง'
                    : null,
                decoration: const InputDecoration(labelText: 'ราคา/คน'),
              ),
            ],
            result: () => (
              title: title.text.trim(),
              slotType: slotType,
              capacity: int.parse(capacity.text),
              price: double.parse(price.text),
            ),
          );
        },
      ),
);

Future<String?> showTaskDialog(BuildContext context) => showDialog(
  context: context,
  builder: (context) => _SimpleFormDialog<String>(
    title: 'เพิ่มงานเตรียมทริป',
    submitLabel: 'เพิ่มงาน',
    builder: (formKey) {
      final title = TextEditingController();
      return _FormBody(
        controllers: [title],
        fields: (_) => [
          TextFormField(
            controller: title,
            autofocus: true,
            validator: _required,
            decoration: const InputDecoration(labelText: 'ชื่องาน'),
          ),
        ],
        result: () => title.text.trim(),
      );
    },
  ),
);

/// Describes a form's fields and how to read its value; owns its controllers.
class _FormBody<T> {
  _FormBody({
    required this.controllers,
    required this.fields,
    required this.result,
  });

  final List<TextEditingController> controllers;
  final List<Widget> Function(StateSetter setState) fields;
  final T Function() result;
}

class _SimpleFormDialog<T> extends StatefulWidget {
  const _SimpleFormDialog({
    required this.title,
    required this.submitLabel,
    required this.builder,
  });

  final String title;
  final String submitLabel;
  final _FormBody<T> Function(GlobalKey<FormState> formKey) builder;

  @override
  State<_SimpleFormDialog<T>> createState() => _SimpleFormDialogState<T>();
}

class _SimpleFormDialogState<T> extends State<_SimpleFormDialog<T>> {
  final _formKey = GlobalKey<FormState>();
  late final _FormBody<T> _body = widget.builder(_formKey);

  @override
  void dispose() {
    for (final controller in _body.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: _body.fields(setState),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, _body.result());
          }
        },
        child: Text(widget.submitLabel),
      ),
    ],
  );
}
