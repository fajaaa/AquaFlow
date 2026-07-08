import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/collector/models/collector_reading_route.dart';
import 'package:aquaflow_desktop/collector/screens/collector_reading_route_details_screen.dart';
import 'package:aquaflow_desktop/collector/services/collector_reading_route_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_reading_route_service.dart';

/// "Očitanja" tab body: read-only list of reading routes assigned to the
/// signed-in collector. Tapping a card opens
/// [CollectorReadingRouteDetailsScreen] for that route's water meters.
///
/// Rendered inside [MobileShell], so it has no Scaffold/AppBar of its own.
class CollectorReadingRoutesScreen extends StatefulWidget {
  const CollectorReadingRoutesScreen({super.key});

  @override
  State<CollectorReadingRoutesScreen> createState() =>
      _CollectorReadingRoutesScreenState();
}

class _CollectorReadingRoutesScreenState
    extends State<CollectorReadingRoutesScreen> {
  final CollectorReadingRouteService _service = CollectorReadingRouteService();

  bool _loading = true;
  String? _error;
  List<CollectorReadingRoute> _routes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await _service.fetchMine();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _loading = false;
      });
    } on CollectorReadingRouteException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openDetails(CollectorReadingRoute route) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CollectorReadingRouteDetailsScreen(route: route),
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Rute očitanja',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Osvježi',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _load);
    }

    if (_routes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
            const _EmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _routes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _RouteCard(
          route: _routes[index],
          onTap: () => _openDetails(_routes[index]),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final CollectorReadingRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _RouteStatusPill(status: route.status),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.event_outlined,
                label: _formatDate(route.scheduledDate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Same 3-state visual style as the admin `ReadingRouteStatusPill`
/// (`lib/admin/widgets/reading_route_status_pill.dart`), with collector-facing
/// Croatian labels instead. Not shared with the admin widget directly: `admin`
/// and `collector` never depend on each other, only on `shared`.
class _RouteStatusPill extends StatelessWidget {
  const _RouteStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'Planned' => (
        'Planirano',
        const Color(0xFF64748B),
        Icons.schedule_outlined,
      ),
      'Assigned' => (
        'Dodijeljeno',
        const Color(0xFF1D4ED8),
        Icons.engineering_outlined,
      ),
      'Cancelled' => (
        'Otkazano',
        const Color(0xFFB91C1C),
        Icons.block_outlined,
      ),
      _ => (status.isEmpty ? '-' : status, const Color(0xFF64748B), Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Trenutno nemate dodijeljenih ruta.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}.';
}
