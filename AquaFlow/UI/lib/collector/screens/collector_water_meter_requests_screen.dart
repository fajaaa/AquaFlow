import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aquaflow_desktop/collector/models/collector_water_meter_request.dart';
import 'package:aquaflow_desktop/collector/services/collector_water_meter_request_exception.dart';
import 'package:aquaflow_desktop/collector/services/collector_water_meter_request_service.dart';

class CollectorWaterMeterRequestsScreen extends StatefulWidget {
  const CollectorWaterMeterRequestsScreen({super.key});

  @override
  State<CollectorWaterMeterRequestsScreen> createState() =>
      _CollectorWaterMeterRequestsScreenState();
}

class _CollectorWaterMeterRequestsScreenState
    extends State<CollectorWaterMeterRequestsScreen> {
  final CollectorWaterMeterRequestService _service =
      CollectorWaterMeterRequestService();

  bool _loading = true;
  bool _mutating = false;
  String? _error;
  List<CollectorWaterMeterRequest> _requests = const [];

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
      final requests = await _service.fetchAssigned();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } on CollectorWaterMeterRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openRegisterDialog(CollectorWaterMeterRequest request) async {
    final draft = await showDialog<_WaterMeterRegistrationDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RegisterWaterMeterDialog(request: request),
    );
    if (!mounted || draft == null) return;

    setState(() => _mutating = true);
    try {
      await _service.register(
        requestId: request.id,
        serviceLocationId: request.serviceLocationId,
        serialNumber: draft.serialNumber,
        installedAt: draft.installedAt,
        initialReading: draft.initialReading,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vodomjer je registrovan.')));
      await _load();
    } on CollectorWaterMeterRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
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
                    'Radni nalozi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Osvježi',
                  onPressed: _loading || _mutating ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (_mutating) const LinearProgressIndicator(minHeight: 2),
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

    if (_requests.isEmpty) {
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
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _RequestCard(
          request: _requests[index],
          disabled: _mutating,
          onRegister: () => _openRegisterDialog(_requests[index]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.disabled,
    required this.onRegister,
  });

  final CollectorWaterMeterRequest request;
  final bool disabled;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = request.note?.trim();

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
                Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Zahtjev #${request.id}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const _AssignedPill(),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: request.serviceLocationAddress.isEmpty
                  ? 'Lokacija #${request.serviceLocationId}'
                  : request.serviceLocationAddress,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Korisnik #${request.customerId}',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Kreirano: ${_formatDate(request.createdAt)}',
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.notes_outlined, label: note),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: disabled ? null : onRegister,
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Registruj vodomjer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterWaterMeterDialog extends StatefulWidget {
  const _RegisterWaterMeterDialog({required this.request});

  final CollectorWaterMeterRequest request;

  @override
  State<_RegisterWaterMeterDialog> createState() =>
      _RegisterWaterMeterDialogState();
}

class _RegisterWaterMeterDialogState extends State<_RegisterWaterMeterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();
  final _readingCtrl = TextEditingController(text: '0');

  late DateTime _installedAt;

  @override
  void initState() {
    super.initState();
    _installedAt = DateTime.now();
  }

  @override
  void dispose() {
    _serialCtrl.dispose();
    _readingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickInstalledAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _installedAt,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_installedAt),
    );
    if (!mounted || time == null) return;

    setState(() {
      _installedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _WaterMeterRegistrationDraft(
        serialNumber: _serialCtrl.text.trim(),
        initialReading: double.parse(_readingCtrl.text.trim()),
        installedAt: _installedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registruj vodomjer'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: ValueKey(widget.request.serviceLocationAddress),
                  initialValue: widget.request.serviceLocationAddress.isEmpty
                      ? 'Lokacija #${widget.request.serviceLocationId}'
                      : widget.request.serviceLocationAddress,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Lokacija',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _serialCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Serijski broj',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _readingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _readingValidator,
                  decoration: const InputDecoration(
                    labelText: 'Početno očitanje',
                    prefixIcon: Icon(Icons.speed_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                _InstalledAtField(
                  value: _installedAt,
                  onPick: _pickInstalledAt,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Registruj'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Obavezno polje.' : null;
  }

  String? _readingValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return 'Unesite pozitivan broj.';
    return null;
  }
}

class _WaterMeterRegistrationDraft {
  const _WaterMeterRegistrationDraft({
    required this.serialNumber,
    required this.initialReading,
    required this.installedAt,
  });

  final String serialNumber;
  final double initialReading;
  final DateTime installedAt;
}

class _InstalledAtField extends StatelessWidget {
  const _InstalledAtField({required this.value, required this.onPick});

  final DateTime value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6ED)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datum instalacije',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_formatDate(value), style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Odaberi datum',
            onPressed: onPick,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }
}

class _AssignedPill extends StatelessWidget {
  const _AssignedPill();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.engineering_outlined, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            'Dodijeljen',
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
            Icons.assignment_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Trenutno nema dodijeljenih zahtjeva.',
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
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}
