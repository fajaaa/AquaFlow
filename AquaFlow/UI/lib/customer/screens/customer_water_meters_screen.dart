import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/customer/models/customer_service_location.dart';
import 'package:aquaflow_desktop/customer/models/customer_water_meter.dart';
import 'package:aquaflow_desktop/customer/models/customer_water_meter_request.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_request_service.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_service.dart';

/// "Vodomjeri" tab body: lists the signed-in customer's own water meters plus
/// their open requests for a new meter, and lets them file / cancel a request.
/// Rendered inside [MobileShell], so it has no Scaffold/AppBar of its own.
class CustomerWaterMetersScreen extends StatefulWidget {
  const CustomerWaterMetersScreen({super.key});

  @override
  State<CustomerWaterMetersScreen> createState() =>
      _CustomerWaterMetersScreenState();
}

class _CustomerWaterMetersScreenState extends State<CustomerWaterMetersScreen> {
  final CustomerWaterMeterService _service = CustomerWaterMeterService();
  final CustomerWaterMeterRequestService _requestService =
      CustomerWaterMeterRequestService();

  bool _loading = true;
  String? _error;
  List<CustomerWaterMeter> _meters = const [];
  List<CustomerWaterMeterRequest> _requests = const [];

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
      final results = await Future.wait([
        _service.fetchMine(),
        _requestService.fetchMine(),
      ]);
      if (!mounted) return;
      setState(() {
        _meters = results[0] as List<CustomerWaterMeter>;
        // Cancelled requests are the customer's own retractions and Registered
        // ones already show up as a real meter above, so only requests still
        // worth the customer's attention (pending/assigned/rejected) stay
        // visible here.
        _requests = (results[1] as List<CustomerWaterMeterRequest>)
            .where((request) {
              final status = request.status.toLowerCase();
              return status == 'pending' ||
                  status == 'assigned' ||
                  status == 'rejected';
            })
            .toList();
        _loading = false;
      });
    } on CustomerWaterMeterException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on CustomerWaterMeterRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openNewRequestDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _NewRequestDialog(service: _requestService),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zahtjev za novi vodomjer je poslan.')),
      );
      await _load();
    }
  }

  Future<void> _cancelRequest(CustomerWaterMeterRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkazati zahtjev?'),
        content: Text(
          'Zahtjev za novi vodomjer na adresi '
          '"${request.serviceLocationAddress}" će biti otkazan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Otkaži zahtjev'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _requestService.cancel(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zahtjev je otkazan.')),
      );
      await _load();
    } on CustomerWaterMeterRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _requestService.dispose();
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
                    'Vodomjeri',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dodaj vodomjer',
                  onPressed: _loading ? null : _openNewRequestDialog,
                  icon: const Icon(Icons.add),
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

    if (_meters.isEmpty && _requests.isEmpty) {
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

    final children = <Widget>[];
    if (_requests.isNotEmpty) {
      children.add(const _SectionHeader(label: 'Zahtjevi za novi vodomjer'));
      for (final request in _requests) {
        children.add(
          _WaterMeterRequestCard(
            request: request,
            onCancel: request.isPending ? () => _cancelRequest(request) : null,
          ),
        );
        children.add(const SizedBox(height: 10));
      }
    }
    if (_meters.isNotEmpty) {
      if (_requests.isNotEmpty) {
        children.add(const SizedBox(height: 6));
        children.add(const _SectionHeader(label: 'Moji vodomjeri'));
      }
      for (final meter in _meters) {
        children.add(_WaterMeterCard(meter: meter));
        children.add(const SizedBox(height: 10));
      }
    }
    children.removeLast(); // trailing separator

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: children,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A meter *request* card: deliberately styled differently from a registered
/// meter (tinted background, request icon and caption) so it cannot be
/// mistaken for an installed meter.
class _WaterMeterRequestCard extends StatelessWidget {
  const _WaterMeterRequestCard({required this.request, this.onCancel});

  final CustomerWaterMeterRequest request;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = request.note;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pending_actions_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Zahtjev za novi vodomjer',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _RequestStatusPill(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: request.serviceLocationAddress.isEmpty
                  ? '-'
                  : request.serviceLocationAddress,
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.notes_outlined, label: note),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Otkaži zahtjev'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestStatusPill extends StatelessWidget {
  const _RequestStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status.toLowerCase()) {
      'pending' => (
        'Na čekanju',
        const Color(0xFFB45309),
        Icons.hourglass_top_outlined,
      ),
      'assigned' => (
        'Dodijeljen',
        const Color(0xFF1D4ED8),
        Icons.engineering_outlined,
      ),
      'registered' => (
        'Registrovan',
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
      ),
      'rejected' => ('Odbijen', const Color(0xFFB91C1C), Icons.block_outlined),
      'cancelled' => (
        'Otkazan',
        const Color(0xFF64748B),
        Icons.cancel_outlined,
      ),
      _ => (status, const Color(0xFF64748B), Icons.help_outline),
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

/// Modal form for a new water meter request: pick one of the customer's own
/// service locations (fetched on open) and optionally add a note.
class _NewRequestDialog extends StatefulWidget {
  const _NewRequestDialog({required this.service});

  final CustomerWaterMeterRequestService service;

  @override
  State<_NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends State<_NewRequestDialog> {
  final TextEditingController _noteController = TextEditingController();

  bool _loadingLocations = true;
  bool _submitting = false;
  String? _error;
  List<CustomerServiceLocation> _locations = const [];
  int? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loadingLocations = true;
      _error = null;
    });

    try {
      final locations = await widget.service.fetchMyLocations();
      if (!mounted) return;
      setState(() {
        _locations = locations;
        _selectedLocationId = locations.length == 1 ? locations.first.id : null;
        _loadingLocations = false;
      });
    } on CustomerWaterMeterRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingLocations = false;
      });
    }
  }

  Future<void> _submit() async {
    final locationId = _selectedLocationId;
    if (locationId == null) {
      setState(() => _error = 'Odaberite lokaciju.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.service.create(
        serviceLocationId: locationId,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CustomerWaterMeterRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Zahtjev za novi vodomjer'),
      content: SizedBox(
        width: 420,
        child: _loadingLocations
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_locations.isEmpty && _error == null)
                    const Text(
                      'Nemate evidentiranih lokacija, pa nije moguće '
                      'zatražiti vodomjer.',
                    )
                  else ...[
                    DropdownButtonFormField<int>(
                      initialValue: _selectedLocationId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lokacija',
                        border: OutlineInputBorder(),
                      ),
                      items: _locations
                          .map(
                            (location) => DropdownMenuItem(
                              value: location.id,
                              child: Text(
                                location.address,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (value) =>
                                setState(() => _selectedLocationId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      enabled: !_submitting,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Napomena (opciono)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _submitting || _loadingLocations || _locations.isEmpty
              ? null
              : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pošalji zahtjev'),
        ),
      ],
    );
  }
}

class _WaterMeterCard extends StatelessWidget {
  const _WaterMeterCard({required this.meter});

  final CustomerWaterMeter meter;

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
              label: meter.serviceLocationAddress.isEmpty
                  ? '-'
                  : meter.serviceLocationAddress,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.speed_outlined,
              label:
                  'Zadnje očitanje: ${meter.lastReading.toStringAsFixed(2)} m³',
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
            'Trenutno nemate evidentiranih vodomjera.',
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
