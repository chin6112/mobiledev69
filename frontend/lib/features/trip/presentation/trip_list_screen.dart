import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_view_model.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/trip_models.dart';
import 'trip_list_view_model.dart';
import 'widgets/dialogs.dart';
import 'widgets/formatters.dart';

class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  Future<void> _createTrip(BuildContext context) async {
    final viewModel = context.read<TripListViewModel>();
    final router = GoRouter.of(context);
    final value = await showTripDialog(context);
    if (value == null || !context.mounted) return;
    final created = await viewModel.createTrip(
      title: value.title,
      destination: value.destination,
      start: value.start,
      end: value.end,
    );
    if (!context.mounted) return;
    if (created.error != null) {
      showMessage(context, 'บันทึกทริปไม่สำเร็จ: ${created.error}');
    } else {
      showMessage(context, 'สร้างทริป ${value.title} แล้ว');
      await router.push('/trips/${created.id}');
      if (context.mounted) await viewModel.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TripListViewModel>();
    final auth = context.watch<AuthViewModel>();
    final theme = context.watch<ThemeViewModel>();
    final trips = viewModel.visibleTrips;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TripMate',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: theme.isDark ? 'โหมดสว่าง' : 'โหมดมืด',
            onPressed: theme.toggle,
            icon: Icon(
              theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: auth.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              child: Text(
                (auth.user?.displayName ?? '?').characters.first.toUpperCase(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTrip(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('สร้างทริปใหม่'),
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Text('สวัสดี, ${auth.user?.displayName ?? 'ผู้ใช้'}'),
            const SizedBox(height: 4),
            Text(
              'ทริปของคุณ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: viewModel.setQuery,
                    decoration: const InputDecoration(
                      hintText: 'ค้นหาชื่อทริปหรือจุดหมาย',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                PopupMenuButton<TripSort>(
                  tooltip: 'เรียงลำดับ',
                  icon: const Icon(Icons.sort_rounded),
                  initialValue: viewModel.sort,
                  onSelected: viewModel.setSort,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: TripSort.newestFirst,
                      child: Text('วันเดินทางล่าสุดก่อน'),
                    ),
                    PopupMenuItem(
                      value: TripSort.oldestFirst,
                      child: Text('วันเดินทางเก่าสุดก่อน'),
                    ),
                    PopupMenuItem(
                      value: TripSort.titleAZ,
                      child: Text('ชื่อทริป ก-ฮ / A-Z'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viewModel.loading && !viewModel.hasTrips)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (viewModel.error != null)
              _ErrorCard(message: viewModel.error!, onRetry: viewModel.load),
            if (!viewModel.loading && viewModel.error == null && trips.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                    viewModel.hasTrips ? 'ไม่พบทริปที่ค้นหา' : 'ยังไม่มีทริป',
                  ),
                  subtitle: const Text('กด "สร้างทริปใหม่" เพื่อเริ่มวางแผน'),
                ),
              ),
            for (final trip in trips) ...[
              _TripCard(
                trip: trip,
                onTap: () async {
                  await context.push('/trips/${trip.id}');
                  if (context.mounted) await viewModel.load();
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primary,
          child: Icon(Icons.luggage_rounded, color: scheme.onPrimary),
        ),
        title: Text(
          trip.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${dateRange(trip.startDate, trip.endDate)}  •  ${trip.destination}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.cloud_off_rounded),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
    ),
  );
}
