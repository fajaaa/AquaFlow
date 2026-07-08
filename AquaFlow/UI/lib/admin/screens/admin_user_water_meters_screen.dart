import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/admin/models/admin_user.dart';
import 'package:aquaflow_desktop/admin/models/admin_water_meter.dart';
import 'package:aquaflow_desktop/admin/services/admin_user_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_user_service.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_exception.dart';
import 'package:aquaflow_desktop/admin/services/admin_water_meter_service.dart';

class AdminUserWaterMetersScreen extends StatefulWidget {
  const AdminUserWaterMetersScreen({super.key, required this.user});

  final AdminUser user;

  @override
  State<AdminUserWaterMetersScreen> createState() =>
      _AdminUserWaterMetersScreenState();
}

class _AdminUserWaterMetersScreenState
    extends State<AdminUserWaterMetersScreen> {
  final AdminUserService _userService = AdminUserService();
  final AdminWaterMeterService _waterMeterService = AdminWaterMeterService();

  bool _loading = true;
  String? _error;
  bool _hasProfile = true;
  List<AdminWaterMeter> _meters = const [];

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
      final profile = await _userService.fetchCustomerProfile(widget.user.id);
      if (profile == null) {
        if (!mounted) return;
        setState(() {
          _hasProfile = false;
          _meters = const [];
          _loading = false;
        });
        return;
      }

      final meters = await _waterMeterService.fetchForCustomer(profile.id);
      if (!mounted) return;
      setState(() {
        _hasProfile = true;
        _meters = meters;
        _loading = false;
      });
    } on AdminUserException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on AdminWaterMeterException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _userService.dispose();
    _waterMeterService.dispose();
    super.dispose();
  }

  String get _title {
    final name = widget.user.fullName;
    return 'Vodomjeri - ${name.isEmpty ? widget.user.email : name}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _load);
    }

    if (!_hasProfile) {
      return const _EmptyState(
        message: 'Korisnik nema kreiran profil pa ni vodomjere.',
      );
    }

    if (_meters.isEmpty) {
      return const _EmptyState(
        message: 'Korisnik trenutno nema evidentiranih vodomjera.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _meters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _WaterMeterCard(meter: _meters[index]),
    );
  }
}

class _WaterMeterCard extends StatelessWidget {
  const _WaterMeterCard({required this.meter});

  final AdminWaterMeter meter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
                    meter.serialNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(status: meter.status),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: meter.settlementName.isEmpty ? '-' : meter.settlementName,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Instaliran: ${_formatDate(meter.installedAt)}',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.speed_outlined,
              label:
                  'Početno očitanje: ${_formatReading(meter.initialReading)} m³ · '
                  'Zadnje očitanje: ${_formatReading(meter.lastReading)} m³',
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
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isActive = normalized == 'active' || normalized == 'aktivan';
    final color = isActive ? const Color(0xFF2E7D32) : const Color(0xFF64748B);
    final icon = isActive ? Icons.check_circle_outline : Icons.cancel_outlined;

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
            status.isEmpty ? '-' : status,
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
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
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

String _formatReading(double value) {
  return value.toStringAsFixed(2);
}
