import 'package:flutter/material.dart';

import 'api_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.startAuthenticated = false});

  final bool startAuthenticated;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B87)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      ),
      home: AuthGate(startAuthenticated: startAuthenticated),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.startAuthenticated = false});

  final bool startAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final TripMateApi _api = TripMateApi();
  bool? _authenticated;

  @override
  void initState() {
    super.initState();
    _authenticated = widget.startAuthenticated ? true : null;
    if (!widget.startAuthenticated) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    final authenticated = await _api.isAuthenticated;
    if (mounted) setState(() => _authenticated = authenticated);
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authenticated == false) {
      return LoginScreen(
        api: _api,
        onAuthenticated: () => setState(() => _authenticated = true),
      );
    }
    return TripMateHome(api: _api);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onAuthenticated,
  });

  final TripMateApi api;
  final VoidCallback onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registerMode = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'กรุณากรอก username และ password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_registerMode) {
        await widget.api.register(username, password);
      }
      await widget.api.login(username, password);
      if (mounted) widget.onAuthenticated();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 52,
                      color: Color(0xFF176B87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _registerMode
                          ? 'สร้างบัญชี TripMate'
                          : 'เข้าสู่ TripMate',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_registerMode ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ'),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                              _registerMode = !_registerMode;
                              _error = null;
                            }),
                      child: Text(
                        _registerMode
                            ? 'มีบัญชีแล้ว? เข้าสู่ระบบ'
                            : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TripMateHome extends StatefulWidget {
  const TripMateHome({super.key, required this.api});

  final TripMateApi api;

  @override
  State<TripMateHome> createState() => _TripMateHomeState();
}

class _TripMateHomeState extends State<TripMateHome> {
  int _tabIndex = 0;
  int? _tripId;
  String _tripTitle = 'เชียงใหม่หน้าฝน';
  String _tripDestination = 'เชียงใหม่';
  DateTime _tripStart = DateTime(2026, 10, 12);
  DateTime _tripEnd = DateTime(2026, 10, 15);
  bool _syncing = false;
  final List<String> _expenses = ['ที่พัก 4,800 บาท', 'ค่าเช่ารถ 2,400 บาท'];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _syncing = true);
    try {
      final trips = await widget.api.getTrips();
      if (trips.isNotEmpty && mounted) {
        final trip = trips.first;
        setState(() {
          _tripId = int.tryParse(trip['id']?.toString() ?? '');
          _tripTitle = trip['title']?.toString() ?? _tripTitle;
          _tripDestination =
              trip['destination']?.toString() ?? _tripDestination;
          _tripStart =
              DateTime.tryParse(trip['start_date']?.toString() ?? '') ??
              _tripStart;
          _tripEnd =
              DateTime.tryParse(trip['end_date']?.toString() ?? '') ?? _tripEnd;
        });
      }
    } on ApiException {
      // Keep the local demo trip visible when the API has no data yet.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _addExpense(String description, String amount) async {
    final parsedAmount = double.tryParse(amount.replaceAll(',', ''));
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนเงินที่ถูกต้อง')),
      );
      return;
    }
    if (_tripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีทริปสำหรับบันทึกค่าใช้จ่าย')),
      );
      return;
    }
    try {
      await widget.api.createExpense(
        tripId: _tripId!,
        description: description,
        amount: parsedAmount,
      );
      if (!mounted) return;
      setState(() => _expenses.add('$description $amount บาท'));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('เพิ่มค่าใช้จ่ายแล้ว')));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกค่าใช้จ่ายไม่สำเร็จ: ${error.message}'),
          ),
        );
      }
    }
  }

  Future<void> _createTrip() async {
    final titleController = TextEditingController();
    final destinationController = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สร้างทริปใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'ชื่อทริป'),
            ),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(labelText: 'จุดหมาย'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final destination = destinationController.text.trim();
              if (title.isNotEmpty && destination.isNotEmpty) {
                Navigator.pop(context, [title, destination]);
              }
            },
            child: const Text('สร้างทริป'),
          ),
        ],
      ),
    );
    titleController.dispose();
    destinationController.dispose();
    if (result != null && mounted) {
      final startDate = await showDatePicker(
        context: context,
        initialDate: _tripStart,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)),
      );
      if (startDate == null || !mounted) return;
      final endDate = await showDatePicker(
        context: context,
        initialDate: startDate.add(const Duration(days: 1)),
        firstDate: startDate,
        lastDate: DateTime.now().add(const Duration(days: 730)),
      );
      if (endDate == null || !mounted) return;
      final title = result[0];
      final destination = result[1];
      setState(() {
        _tripTitle = title;
        _tripDestination = destination;
        _tripStart = startDate;
        _tripEnd = endDate;
      });
      try {
        final createdTrip = await widget.api.createTrip(
          title: title,
          destination: destination,
          startDate: _dateValue(startDate),
          endDate: _dateValue(endDate),
        );
        _tripId = int.tryParse(createdTrip['id']?.toString() ?? '');
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('สร้างทริป $title แล้ว')));
        }
      } on ApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกทริปไม่สำเร็จ: ${error.message}')),
          );
        }
      }
    }
  }

  String _dateValue(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _showExpenseDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มค่าใช้จ่าย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'รายการ'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final amount = amountController.text.trim();
              if (description.isNotEmpty && amount.isNotEmpty) {
                Navigator.pop(context, [description, amount]);
              }
            },
            child: const Text('เพิ่มรายการ'),
          ),
        ],
      ),
    );
    descriptionController.dispose();
    amountController.dispose();
    if (result != null && mounted) {
      _addExpense(result[0], result[1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
        tripTitle: _tripTitle,
        destination: _tripDestination,
        startDate: _tripStart,
        endDate: _tripEnd,
        syncing: _syncing,
        onOpenPlanner: () => setState(() => _tabIndex = 1),
        onCreateTrip: _createTrip,
      ),
      _Planner(api: widget.api, tripId: _tripId),
      _Expenses(expenses: _expenses, onAdd: _showExpenseDialog),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TripMate',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await widget.api.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthGate()),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(radius: 16, child: Text('P')),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Expenses',
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.tripTitle,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.syncing,
    required this.onOpenPlanner,
    required this.onCreateTrip,
  });
  final String tripTitle;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final bool syncing;
  final VoidCallback onOpenPlanner;
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('สวัสดี, พีท'),
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
                tripTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_dateLabel(startDate)} - ${_dateLabel(endDate)}  •  $destination',
                style: TextStyle(color: Colors.white70),
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
        if (syncing)
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
        const _ActionTile(
          icon: Icons.hotel_rounded,
          title: 'เลือกที่พัก',
          subtitle: 'ยังไม่มีใครจองที่พักสำหรับคืนแรก',
          badge: 'ด่วน',
        ),
        const SizedBox(height: 10),
        const _ActionTile(
          icon: Icons.confirmation_number_rounded,
          title: 'ตั๋วรถไฟ',
          subtitle: 'มินท์รับผิดชอบ • ครบกำหนดพรุ่งนี้',
          badge: 'งาน',
        ),
        const SizedBox(height: 10),
        const _ActionTile(
          icon: Icons.backpack_rounded,
          title: 'เตรียมของใช้ส่วนกลาง',
          subtitle: 'เช็กลิสต์ 6 จาก 8 รายการ',
          badge: 'ทีม',
        ),
      ],
    );
  }

  String _dateLabel(DateTime date) => '${date.day} ${_monthName(date.month)}';

  String _monthName(int month) => const [
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
  ][month];
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
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

class _Planner extends StatefulWidget {
  const _Planner({required this.api, required this.tripId});

  final TripMateApi api;
  final int? tripId;

  @override
  State<_Planner> createState() => _PlannerState();
}

class _PlannerState extends State<_Planner> {
  bool _loading = false;
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadPlanner();
  }

  @override
  void didUpdateWidget(covariant _Planner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId != widget.tripId) _loadPlanner();
  }

  Future<void> _loadPlanner() async {
    if (widget.tripId == null) return;
    setState(() => _loading = true);
    try {
      final slots = await widget.api.getSlots(widget.tripId!);
      final tasks = await widget.api.getTasks(widget.tripId!);
      if (mounted) setState(() { _slots = slots; _tasks = tasks; });
    } on ApiException {
      // Keep the planner useful while the trip has no server data yet.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleTask(Map<String, dynamic> task, bool value) async {
    final taskId = int.tryParse(task['id']?.toString() ?? '');
    if (taskId == null) return;
    try {
      final updated = await widget.api.updateTask(taskId: taskId, isDone: value);
      if (mounted) {
        setState(() {
          final index = _tasks.indexWhere((item) => item['id'] == task['id']);
          if (index >= 0) _tasks[index] = updated;
        });
      }
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _bookSlot(Map<String, dynamic> slot) async {
    final slotId = int.tryParse(slot['id']?.toString() ?? '');
    if (slotId == null) return;
    try {
      final updated = await widget.api.bookSlot(slotId);
      if (mounted) {
        setState(() {
          final index = _slots.indexWhere((item) => item['id'] == slot['id']);
          if (index >= 0) _slots[index] = updated;
        });
      }
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'แผนทริป',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      const Text('วางแผนร่วมกัน แล้วให้ทุกคนเห็นภาพเดียวกัน'),
      const SizedBox(height: 22),
      const Text(
        '12 ต.ค. • วันเดินทาง',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      if (_loading) const LinearProgressIndicator(),
      if (_slots.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ยังไม่มีสล็อตจอง'),
            subtitle: Text('เพิ่มที่พักหรือกิจกรรมผ่านระบบจัดการทริป'),
          ),
        ),
      ..._slots.map((slot) => Card(child: ListTile(
        leading: Icon(slot['slot_type'] == 'stay' ? Icons.cabin_rounded : Icons.event_available_rounded, color: const Color(0xFF176B87)),
        title: Text(slot['title']?.toString() ?? 'สล็อตจอง', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${slot['booked_count'] ?? 0}/${slot['capacity'] ?? 0} ที่ • ฿${slot['price'] ?? 0}'),
        trailing: (slot['booked_count'] ?? 0) >= (slot['capacity'] ?? 0) ? const Icon(Icons.check_circle, color: Colors.green) : OutlinedButton(onPressed: () => _bookSlot(slot), child: const Text('จอง')),
      ))),
      const SizedBox(height: 24),
      const Text(
        'เช็กลิสต์ทีม',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      if (_tasks.isEmpty)
        const Text('ยังไม่มีงานเตรียมทริป', style: TextStyle(color: Colors.grey)),
      ..._tasks.map((task) => CheckboxListTile(
        value: task['is_done'] == true,
        onChanged: (value) => _toggleTask(task, value ?? false),
        contentPadding: EdgeInsets.zero,
        title: Text(task['title']?.toString() ?? 'งานเตรียมทริป'),
        subtitle: Text(task['assigned_to_name']?.toString() ?? 'ยังไม่ได้มอบหมาย'),
        controlAffinity: ListTileControlAffinity.leading,
      )),
    ],
  );
}

class _Expenses extends StatelessWidget {
  const _Expenses({required this.expenses, required this.onAdd});
  final List<String> expenses;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ค่าใช้จ่าย',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onAdd,
            tooltip: 'เพิ่มค่าใช้จ่าย',
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      const Text('ระบบคำนวณยอดที่แต่ละคนต้องคืนให้โดยอัตโนมัติ'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F2E6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ยอดที่คุณต้องจ่ายคืน',
              style: TextStyle(color: Color(0xFF386641)),
            ),
            SizedBox(height: 5),
            Text(
              '฿1,600',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF386641),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'รายการล่าสุด',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      ...expenses.map(
        (expense) => Card(
          child: ListTile(
            leading: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF176B87),
            ),
            title: Text(expense),
            subtitle: const Text('หารเท่ากัน 4 คน'),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.payments_outlined),
        label: const Text('ดูรายการที่ต้องโอนทั้งหมด'),
      ),
    ],
  );
}
