import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_user.dart';
import 'package:aquaflow_desktop/models/admin_water_meter.dart';
import 'package:aquaflow_desktop/screens/admin_meter_readings_screen.dart';
import 'package:aquaflow_desktop/services/admin_user_exception.dart';
import 'package:aquaflow_desktop/services/admin_user_service.dart';
import 'package:aquaflow_desktop/services/admin_water_meter_exception.dart';
import 'package:aquaflow_desktop/services/admin_water_meter_service.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';

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
  bool _hasLoadedOnce = false;
  String? _error;
  bool _hasProfile = true;
  List<AdminWaterMeter> _meters = const [];

  bool get _isInitialLoad => _loading && !_hasLoadedOnce;

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
          _hasLoadedOnce = true;
        });
        return;
      }

      final meters = await _waterMeterService.fetchForCustomer(profile.id);
      if (!mounted) return;
      setState(() {
        _hasProfile = true;
        _meters = meters;
        _loading = false;
        _hasLoadedOnce = true;
      });
    } on AdminUserException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _hasLoadedOnce = true;
      });
    } on AdminWaterMeterException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  @override
  void dispose() {
    _userService.dispose();
    _waterMeterService.dispose();
    super.dispose();
  }

  String _title(AppLocalizations loc) {
    final name = widget.user.fullName;
    return loc.waterMetersTitle(name.isEmpty ? widget.user.email : name);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(loc)),
        actions: [
          RefreshButton(onRefresh: _load),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading && !_isInitialLoad)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildBody(loc)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: _load);
    }

    if (!_hasProfile) {
      return EmptyStateView(
        icon: Icons.person_off_outlined,
        message: loc.userNoProfileMessage,
      );
    }

    if (_meters.isEmpty) {
      return EmptyStateView(
        icon: Icons.water_drop_outlined,
        message: loc.userNoWaterMetersMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _meters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final meter = _meters[index];
        return _WaterMeterCard(
          meter: meter,
          onTap: () => context.pushScreen(
            AdminMeterReadingsScreen(
              waterMeterId: meter.id,
              waterMeterSerialNumber: meter.serialNumber,
            ),
          ),
        );
      },
    );
  }
}

class _WaterMeterCard extends StatelessWidget {
  const _WaterMeterCard({required this.meter, required this.onTap});

  final AdminWaterMeter meter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final statusColor = _statusColor(meter.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.water_drop, size: 20, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      meter.serialNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusPill(status: meter.status),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.30),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 28,
                runSpacing: 12,
                children: [
                  _DetailChip(
                    icon: Icons.location_on_outlined,
                    label: loc.locationSettlementLabel,
                    value: meter.settlementName.isEmpty
                        ? '-'
                        : meter.settlementName,
                  ),
                  _DetailChip(
                    icon: Icons.event_outlined,
                    label: loc.installedLabel,
                    value: _formatDate(meter.installedAt),
                  ),
                  _DetailChip(
                    icon: Icons.speed_outlined,
                    label: loc.initialReadingLabel,
                    value: '${_formatReading(meter.initialReading)} m³',
                  ),
                  _DetailChip(
                    icon: Icons.speed,
                    label: loc.lastReadingLabel,
                    value: '${_formatReading(meter.lastReading)} m³',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            _statusLabel(status, loc),
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

// Backend literals are AquaFlow.Services.WaterMeterStatus (Active/Inactive/
// Removed); the "aktivan" fallback keeps this readable if that ever changes.
Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
    case 'aktivan':
      return const Color(0xFF2E7D32);
    case 'inactive':
      return const Color(0xFFF9A825);
    case 'removed':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF64748B);
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'active':
    case 'aktivan':
      return Icons.check_circle_outline;
    case 'inactive':
      return Icons.pause_circle_outline;
    case 'removed':
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}

String _statusLabel(String status, AppLocalizations loc) {
  switch (status.toLowerCase()) {
    case 'active':
      return loc.statusActive;
    case 'inactive':
      return loc.statusInactive;
    case 'removed':
      return loc.waterMeterStatusRemoved;
    default:
      return status.isEmpty ? '-' : status;
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
