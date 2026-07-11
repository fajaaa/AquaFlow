import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/customer/models/customer_fault_report.dart';
import 'package:aquaflow_desktop/customer/models/customer_water_meter.dart';
import 'package:aquaflow_desktop/customer/services/customer_fault_report_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_fault_report_service.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_water_meter_service.dart';
import 'package:aquaflow_desktop/shared/models/customer_profile.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/services/profile_exception.dart';
import 'package:aquaflow_desktop/shared/services/profile_service.dart';

const int _maxPhotos = 3;

/// Opens the "Nova prijava kvara" dialog and resolves to `true` when a report
/// was successfully created. Reached from `CustomerFaultReportsScreen`.
Future<bool?> showNewFaultReportDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const NewFaultReportDialog(),
  );
}

/// Modal form for a new fault report: Naslov/Opis, an optional water meter
/// (`CustomerWaterMeterService.fetchMine`), and up to [_maxPhotos] photos
/// (camera or gallery, `image_picker`).
///
/// `FaultReportInsertRequest.SettlementId` is required by the backend (see
/// AGENTS.md - fault reports have no location-existence check layer, unlike
/// `WaterMeterRequest`), so this resolves one on submit: the selected water
/// meter's own settlement when one is picked, otherwise the caller's
/// `CustomerProfile.SettlementId` (prefetched on open, same template as
/// `NewWaterMeterRequestDialog`).
///
/// The report is created first, then photos are uploaded sequentially
/// (`CustomerFaultReportService.uploadPhoto`), showing a "n/total" progress
/// indicator. If a photo upload fails, the already-created report is kept
/// (never re-created on retry) and the dialog stays open so the remaining
/// photos can be resent.
class NewFaultReportDialog extends StatefulWidget {
  const NewFaultReportDialog({super.key});

  @override
  State<NewFaultReportDialog> createState() => _NewFaultReportDialogState();
}

class _NewFaultReportDialogState extends State<NewFaultReportDialog> {
  final CustomerFaultReportService _reportService = CustomerFaultReportService();
  final CustomerWaterMeterService _waterMeterService = CustomerWaterMeterService();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  String? _error;

  List<CustomerWaterMeter> _waterMeters = const [];
  CustomerProfile? _profile;
  int? _selectedWaterMeterId;
  final List<File> _selectedImages = [];

  CustomerFaultReport? _createdReport;
  int _uploadedPhotoCount = 0;

  int? get _userId => context.read<AuthProvider>().session?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final userId = _userId;
    try {
      final results = await Future.wait([
        _waterMeterService.fetchMine(),
        userId == null
            ? Future.value(null)
            : _profileService.fetchCustomerProfile(userId),
      ]);
      if (!mounted) return;
      setState(() {
        _waterMeters = results[0] as List<CustomerWaterMeter>;
        _profile = results[1] as CustomerProfile?;
        _loading = false;
      });
    } on CustomerWaterMeterException catch (e) {
      _failLoad(e.message);
    } on ProfileException catch (e) {
      _failLoad(e.message);
    }
  }

  void _failLoad(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadError = message;
    });
  }

  @override
  void dispose() {
    _reportService.dispose();
    _waterMeterService.dispose();
    _profileService.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Slikaj'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Iz galerije'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _selectedImages.add(File(picked.path)));
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  /// The selected water meter's own settlement when one is picked, otherwise
  /// the caller's profile settlement. `null` when neither is available - the
  /// caller has no way to satisfy the backend's required `SettlementId` then.
  int? get _resolvedSettlementId {
    final selectedId = _selectedWaterMeterId;
    if (selectedId != null) {
      for (final meter in _waterMeters) {
        if (meter.id == selectedId) return meter.settlementId;
      }
    }
    return _profile?.settlementId;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final settlementId = _resolvedSettlementId;
    if (_createdReport == null && settlementId == null) {
      setState(() {
        _error =
            'Adresa nije postavljena na vašem profilu. Ažurirajte profil prije prijave.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      var report = _createdReport;
      if (report == null) {
        report = await _reportService.create(
          title: _titleCtrl.text,
          description: _descriptionCtrl.text,
          settlementId: settlementId!,
          waterMeterId: _selectedWaterMeterId,
        );
        if (!mounted) return;
        setState(() => _createdReport = report);
      }

      for (var i = _uploadedPhotoCount; i < _selectedImages.length; i++) {
        await _reportService.uploadPhoto(report.id, _selectedImages[i]);
        if (!mounted) return;
        setState(() => _uploadedPhotoCount = i + 1);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CustomerFaultReportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova prijava kvara'),
      content: SizedBox(width: 420, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed:
              _submitting || _loading || _loadError != null ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pošalji prijavu'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);

    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final loadError = _loadError;
    if (loadError != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(loadError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    final atPhotoLimit = _selectedImages.length >= _maxPhotos;
    final enabled = !_submitting;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              enabled: enabled && _createdReport == null,
              maxLength: 150,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Naslov',
                prefixIcon: Icon(Icons.title_outlined),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              enabled: enabled && _createdReport == null,
              maxLines: 4,
              maxLength: 1000,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Opis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedWaterMeterId ?? 0,
              decoration: const InputDecoration(
                labelText: 'Vodomjer (opciono)',
                prefixIcon: Icon(Icons.water_drop_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Bez vodomjera')),
                for (final meter in _waterMeters)
                  DropdownMenuItem(
                    value: meter.id,
                    child: Text(
                      meter.serialNumber,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: enabled && _createdReport == null
                  ? (value) => setState(
                      () => _selectedWaterMeterId = value == 0 ? null : value,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fotografije (${_selectedImages.length}/$_maxPhotos)',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: enabled && !atPhotoLimit
                      ? _showImageSourceSheet
                      : null,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Dodaj sliku'),
                ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _PhotoThumbnail(
                    file: _selectedImages[index],
                    uploaded: index < _uploadedPhotoCount,
                    onRemove: enabled && _createdReport == null
                        ? () => _removeImage(index)
                        : null,
                  ),
                ),
              ),
            ],
            if (_submitting && _selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _selectedImages.isEmpty
                    ? null
                    : _uploadedPhotoCount / _selectedImages.length,
              ),
              const SizedBox(height: 6),
              Text(
                'Slanje fotografije ${_uploadedPhotoCount + 1}/${_selectedImages.length}...',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
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
    );
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Obavezno polje.';
    return null;
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.file,
    required this.uploaded,
    required this.onRemove,
  });

  final File file;
  final bool uploaded;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 76,
            height: 76,
            fit: BoxFit.cover,
          ),
        ),
        if (uploaded)
          Positioned(
            left: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        if (onRemove != null)
          Positioned(
            right: -4,
            top: -4,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
