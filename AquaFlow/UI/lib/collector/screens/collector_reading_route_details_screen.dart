import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/collector/models/collector_reading_route.dart';
import 'package:aquaflow_desktop/collector/models/collector_reading_route_item.dart';
import 'package:aquaflow_desktop/collector/services/collector_reading_route_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_reading_route_service.dart';

/// Pushed as its own `Scaffold`+`AppBar` route (same pattern as
/// `CustomerRequestsScreen`) to show the water meters on one reading route
/// assigned to the signed-in collector - purely informational, same
/// read-only card list style as `CustomerWaterMetersScreen`. No
/// reading-entry action here yet; that (and the InProgress/Completed
/// statuses) lands in a later phase.
class CollectorReadingRouteDetailsScreen extends StatefulWidget {
  const CollectorReadingRouteDetailsScreen({super.key, required this.route});

  final CollectorReadingRoute route;

  @override
  State<CollectorReadingRouteDetailsScreen> createState() =>
      _CollectorReadingRouteDetailsScreenState();
}

class _CollectorReadingRouteDetailsScreenState
    extends State<CollectorReadingRouteDetailsScreen> {
  final CollectorReadingRouteService _service = CollectorReadingRouteService();

  bool _loading = true;
  String? _error;
  List<CollectorReadingRouteItem> _items = const [];

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
      final items = await _service.fetchItems(widget.route.id);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.route.name)),
      body: _buildContent(),
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

    if (_items.isEmpty) {
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _ItemCard(item: _items[index]),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final CollectorReadingRouteItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerLabel = item.customerFullName;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.waterMeterSerialNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  item.status.isEmpty ? '-' : item.status,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.person_outline,
              label: customerLabel.isEmpty ? '-' : customerLabel,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: item.settlementName.isEmpty ? '-' : item.settlementName,
            ),
          ],
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
            Icons.water_drop_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Ruta još nema dodanih vodomjera.',
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
