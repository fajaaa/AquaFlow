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
import 'package:aquaflow_desktop/shared/models/city_lookup.dart';
import 'package:aquaflow_desktop/shared/models/customer_profile.dart';
import 'package:aquaflow_desktop/shared/models/municipality_lookup.dart';
import 'package:aquaflow_desktop/shared/models/settlement_lookup.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/services/location_lookup_exception.dart';
import 'package:aquaflow_desktop/shared/services/location_lookup_service.dart';
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

/// Modal form for a new fault report: Naslov/Opis, the report's own location
/// (cascading Grad -> Općina -> Naselje via the shared `LocationLookupService`
/// plus optional Ulica/Broj, same template as `NewWaterMeterRequestDialog`),
/// an optional water meter (`CustomerWaterMeterService.fetchMine`), and up to
/// [_maxPhotos] photos (camera or gallery, `image_picker`).
///
/// The address is the caller's to pick - it is prefilled from their
/// `CustomerProfile` when one exists, and picking one of their water meters
/// prefills that meter's address, but neither is required: a customer without
/// a profile (or with an incomplete one) can still submit as long as a Naselje
/// is selected.
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
  final LocationLookupService _locationService = LocationLookupService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _houseNumberCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  String? _error;

  List<CustomerWaterMeter> _waterMeters = const [];
  int? _selectedWaterMeterId;
  final List<File> _selectedImages = [];

  List<CityLookup> _cities = const [];
  List<MunicipalityLookup> _municipalities = const [];
  List<SettlementLookup> _settlements = const [];
  int? _selectedCityId;
  int? _selectedMunicipalityId;
  int? _selectedSettlementId;

  CustomerFaultReport? _createdReport;
  int _uploadedPhotoCount = 0;

  int? get _userId => context.read<AuthProvider>().session?.id;

  List<MunicipalityLookup> get _municipalitiesForSelectedCity =>
      _municipalities.where((m) => m.cityId == _selectedCityId).toList();

  List<SettlementLookup> get _settlementsForSelectedMunicipality => _settlements
      .where((s) => s.municipalityId == _selectedMunicipalityId)
      .toList();

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
        _locationService.fetchCities(),
        _locationService.fetchMunicipalities(),
        _locationService.fetchSettlements(),
      ]);
      if (!mounted) return;

      final profile = results[1] as CustomerProfile?;
      _cities = results[2] as List<CityLookup>;
      _municipalities = results[3] as List<MunicipalityLookup>;
      _settlements = results[4] as List<SettlementLookup>;

      // Prefill only - the caller may pick any location for the report.
      _streetCtrl.text = profile?.street ?? '';
      _houseNumberCtrl.text = profile?.houseNumber ?? '';
      _applySettlement(profile?.settlementId);
      setState(() {
        _waterMeters = results[0] as List<CustomerWaterMeter>;
        _loading = false;
      });
    } on CustomerWaterMeterException catch (e) {
      _failLoad(e.message);
    } on ProfileException catch (e) {
      _failLoad(e.message);
    } on LocationLookupException catch (e) {
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
    _locationService.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _streetCtrl.dispose();
    _houseNumberCtrl.dispose();
    super.dispose();
  }

  /// Resolves the Grad -> Općina chain for a prefilled [settlementId], so the
  /// two parent dropdowns start selected too, not just the leaf Naselje.
  void _applySettlement(int? settlementId) {
    if (settlementId == null) return;
    SettlementLookup? settlement;
    for (final s in _settlements) {
      if (s.id == settlementId) {
        settlement = s;
        break;
      }
    }
    if (settlement == null) return;

    _selectedSettlementId = settlement.id;
    _selectedMunicipalityId = settlement.municipalityId;
    for (final m in _municipalities) {
      if (m.id == settlement.municipalityId) {
        _selectedCityId = m.cityId;
        break;
      }
    }
  }

  void _onCityChanged(int? cityId) {
    setState(() {
      _selectedCityId = cityId;
      if (_selectedMunicipalityId != null &&
          !_municipalitiesForSelectedCity
              .any((m) => m.id == _selectedMunicipalityId)) {
        _selectedMunicipalityId = null;
        _selectedSettlementId = null;
      }
    });
  }

  void _onMunicipalityChanged(int? municipalityId) {
    setState(() {
      _selectedMunicipalityId = municipalityId;
      if (_selectedSettlementId != null &&
          !_settlementsForSelectedMunicipality
              .any((s) => s.id == _selectedSettlementId)) {
        _selectedSettlementId = null;
      }
    });
  }

  void _onSettlementChanged(int? settlementId) {
    setState(() => _selectedSettlementId = settlementId);
  }

  /// Picking one of the caller's own meters prefills the fault location with
  /// that meter's address (a convenience, not a constraint - the fields stay
  /// editable and the meter's address may itself be incomplete).
  void _onWaterMeterChanged(int? waterMeterId) {
    setState(() {
      _selectedWaterMeterId = waterMeterId;
      if (waterMeterId == null) return;
      for (final meter in _waterMeters) {
        if (meter.id != waterMeterId) continue;
        if (meter.settlementId != 0) {
          _applySettlement(meter.settlementId);
        }
        if ((meter.street ?? '').trim().isNotEmpty) {
          _streetCtrl.text = meter.street!.trim();
        }
        if ((meter.houseNumber ?? '').trim().isNotEmpty) {
          _houseNumberCtrl.text = meter.houseNumber!.trim();
        }
        break;
      }
    });
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

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final settlementId = _selectedSettlementId;
    if (_createdReport == null && settlementId == null) return;

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
          street: _streetCtrl.text,
          houseNumber: _houseNumberCtrl.text,
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
    final locationEditable = enabled && _createdReport == null;

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
              onChanged: locationEditable
                  ? (value) => _onWaterMeterChanged(value == 0 ? null : value)
                  : null,
            ),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: 'Grad',
              icon: Icons.location_city_outlined,
              emptyLabel: 'Bez grada',
              value: _selectedCityId,
              items: [
                for (final city in _cities) (city.id, city.name),
              ],
              onChanged: locationEditable ? _onCityChanged : null,
            ),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: 'Općina',
              icon: Icons.map_outlined,
              emptyLabel: 'Bez općine',
              value: _selectedMunicipalityId,
              items: [
                for (final m in _municipalitiesForSelectedCity) (m.id, m.name),
              ],
              onChanged: locationEditable && _selectedCityId != null
                  ? _onMunicipalityChanged
                  : null,
            ),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: 'Naselje',
              icon: Icons.holiday_village_outlined,
              emptyLabel: 'Bez naselja',
              value: _selectedSettlementId,
              items: [
                for (final s in _settlementsForSelectedMunicipality)
                  (s.id, s.name),
              ],
              validator: _settlementValidator,
              onChanged: locationEditable && _selectedMunicipalityId != null
                  ? _onSettlementChanged
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetCtrl,
              enabled: locationEditable,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Ulica (opciono)',
                prefixIcon: Icon(Icons.signpost_outlined),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _houseNumberCtrl,
              enabled: locationEditable,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Broj (opciono)',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
                border: OutlineInputBorder(),
              ),
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

  String? _settlementValidator(int? value) {
    // Once the report row exists (photo-retry state) the location is already
    // stored server-side, so it no longer blocks resubmission.
    if (_createdReport != null) return null;
    if (value == null || value == 0) return 'Odaberite naselje.';
    return null;
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Obavezno polje.';
    return null;
  }
}

/// A single dropdown in the cascading Grad -> Općina -> Naselje picker. Uses a
/// `0` sentinel for "none selected" so the field can render an empty option and
/// still validate; a `null` [onChanged] disables the field until its parent is
/// picked. Same widget as `NewWaterMeterRequestDialog`'s (duplicated - widgets
/// stay per-feature in this codebase).
class _CascadingDropdown extends StatelessWidget {
  const _CascadingDropdown({
    required this.label,
    required this.icon,
    required this.emptyLabel,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final IconData icon;
  final String emptyLabel;
  final int? value;
  final List<(int, String)> items;
  final ValueChanged<int?>? onChanged;
  final String? Function(int?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value ?? 0,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: 0, child: Text(emptyLabel)),
        for (final (id, name) in items)
          DropdownMenuItem(value: id, child: Text(name)),
      ],
      validator: validator,
      onChanged: onChanged == null
          ? null
          : (value) => onChanged!(value == 0 ? null : value),
    );
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
