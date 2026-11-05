import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aquaflow_collector/l10n/app_localizations.dart';
import 'package:aquaflow_collector/models/collector_water_meter.dart';
import 'package:aquaflow_collector/services/collector_fault_report_exception.dart';
import 'package:aquaflow_collector/services/collector_fault_report_service.dart';
import 'package:aquaflow_collector/services/collector_water_meter_exception.dart';
import 'package:aquaflow_collector/services/collector_water_meter_service.dart';
import 'package:aquaflow_collector/shared/models/city_lookup.dart';
import 'package:aquaflow_collector/shared/models/municipality_lookup.dart';
import 'package:aquaflow_collector/shared/models/settlement_lookup.dart';
import 'package:aquaflow_collector/shared/services/location_lookup_exception.dart';
import 'package:aquaflow_collector/shared/services/location_lookup_service.dart';

const int _maxPhotos = 5;

/// Opens the "Nova prijava kvara" dialog and resolves to `true` when a report
/// was filed. [initialMeter] pre-fills the water meter and its address (used
/// from the meter detail screen).
Future<bool?> showNewFaultReportDialog(
  BuildContext context, {
  CollectorWaterMeter? initialMeter,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => NewFaultReportDialog(initialMeter: initialMeter),
  );
}

/// Collector-side form for a NEW fault report: title/description, the
/// location (Grad -> Općina -> Naselje via the shared `LocationLookupService`,
/// optional street/house number), an optional water meter (any meter - a
/// collector is not tied to specific meters) and up to [_maxPhotos] photos.
/// Report and photos go out in one atomic multipart request
/// (`CollectorFaultReportService.createWithPhotos`). Client validation mirrors
/// the backend `FaultReportInsertValidator`.
class NewFaultReportDialog extends StatefulWidget {
  const NewFaultReportDialog({super.key, this.initialMeter});

  final CollectorWaterMeter? initialMeter;

  @override
  State<NewFaultReportDialog> createState() => _NewFaultReportDialogState();
}

class _NewFaultReportDialogState extends State<NewFaultReportDialog> {
  final CollectorFaultReportService _reportService =
      CollectorFaultReportService();
  final CollectorWaterMeterService _waterMeterService =
      CollectorWaterMeterService();
  final LocationLookupService _locationService = LocationLookupService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _houseNumberCtrl = TextEditingController();
  final TextEditingController _meterSearchCtrl = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  String? _error;

  CollectorWaterMeter? _selectedMeter;
  List<CollectorWaterMeter>? _meterResults;
  bool _searchingMeters = false;
  final List<File> _selectedImages = [];

  List<CityLookup> _cities = const [];
  List<MunicipalityLookup> _municipalities = const [];
  List<SettlementLookup> _settlements = const [];
  int? _selectedCityId;
  int? _selectedMunicipalityId;
  int? _selectedSettlementId;

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

    try {
      final results = await Future.wait([
        _locationService.fetchCities(),
        _locationService.fetchMunicipalities(),
        _locationService.fetchSettlements(),
      ]);
      if (!mounted) return;

      _cities = results[0] as List<CityLookup>;
      _municipalities = results[1] as List<MunicipalityLookup>;
      _settlements = results[2] as List<SettlementLookup>;

      final meter = widget.initialMeter;
      if (meter != null) _applyMeter(meter);
      setState(() => _loading = false);
    } on LocationLookupException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  @override
  void dispose() {
    _reportService.dispose();
    _waterMeterService.dispose();
    _locationService.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _streetCtrl.dispose();
    _houseNumberCtrl.dispose();
    _meterSearchCtrl.dispose();
    super.dispose();
  }

  /// Selects [meter] and prefills the fault location with its address (a
  /// convenience, not a constraint - the fields stay editable).
  void _applyMeter(CollectorWaterMeter meter) {
    _selectedMeter = meter;
    _meterResults = null;
    if (meter.settlementId != 0) _applySettlement(meter.settlementId);
    if ((meter.street ?? '').trim().isNotEmpty) {
      _streetCtrl.text = meter.street!.trim();
    }
    if ((meter.houseNumber ?? '').trim().isNotEmpty) {
      _houseNumberCtrl.text = meter.houseNumber!.trim();
    }
  }

  /// Resolves the Grad -> Općina chain for [settlementId] so the two parent
  /// dropdowns start selected too, not just the leaf Naselje.
  void _applySettlement(int settlementId) {
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
          !_municipalitiesForSelectedCity.any(
            (m) => m.id == _selectedMunicipalityId,
          )) {
        _selectedMunicipalityId = null;
        _selectedSettlementId = null;
      }
    });
  }

  void _onMunicipalityChanged(int? municipalityId) {
    setState(() {
      _selectedMunicipalityId = municipalityId;
      if (_selectedSettlementId != null &&
          !_settlementsForSelectedMunicipality.any(
            (s) => s.id == _selectedSettlementId,
          )) {
        _selectedSettlementId = null;
      }
    });
  }

  Future<void> _searchMeters() async {
    final term = _meterSearchCtrl.text.trim();
    if (term.isEmpty) return;
    setState(() {
      _searchingMeters = true;
      _error = null;
    });
    try {
      final results = await _waterMeterService.search(term);
      if (!mounted) return;
      setState(() {
        _meterResults = results;
        _searchingMeters = false;
      });
    } on CollectorWaterMeterException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _searchingMeters = false;
      });
    }
  }

  Future<void> _showImageSourceSheet() async {
    final loc = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(loc.takePhotoOption),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(loc.chooseFromGalleryOption),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _selectedImages.add(File(picked.path)));
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final settlementId = _selectedSettlementId;
    if (settlementId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _reportService.createWithPhotos(
        title: _titleCtrl.text,
        description: _descriptionCtrl.text,
        settlementId: settlementId,
        street: _streetCtrl.text,
        houseNumber: _houseNumberCtrl.text,
        waterMeterId: _selectedMeter?.id,
        photos: _selectedImages,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CollectorFaultReportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.newFaultReportDialogTitle),
      content: SizedBox(width: 420, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(loc.dialogDismissButton),
        ),
        FilledButton(
          onPressed: _submitting || _loading || _loadError != null
              ? null
              : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.newFaultReportSubmitButton),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

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
              Icon(
                Icons.error_outline,
                size: 40,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(loadError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(loc.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    final enabled = !_submitting;
    final atPhotoLimit = _selectedImages.length >= _maxPhotos;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              enabled: enabled,
              maxLength: 150,
              validator: (value) => _titleValidator(context, value),
              decoration: InputDecoration(
                labelText: loc.faultReportTitleLabel,
                prefixIcon: const Icon(Icons.title_outlined),
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              enabled: enabled,
              maxLines: 4,
              validator: (value) => _requiredValidator(context, value),
              decoration: InputDecoration(
                labelText: loc.faultReportDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildMeterSection(theme, loc, enabled),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: loc.locationCityLabel,
              icon: Icons.location_city_outlined,
              emptyLabel: loc.locationNoCityOption,
              value: _selectedCityId,
              items: [for (final city in _cities) (city.id, city.name)],
              onChanged: enabled ? _onCityChanged : null,
            ),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: loc.locationMunicipalityLabel,
              icon: Icons.map_outlined,
              emptyLabel: loc.locationNoMunicipalityOption,
              value: _selectedMunicipalityId,
              items: [
                for (final m in _municipalitiesForSelectedCity) (m.id, m.name),
              ],
              onChanged: enabled && _selectedCityId != null
                  ? _onMunicipalityChanged
                  : null,
            ),
            const SizedBox(height: 16),
            _CascadingDropdown(
              label: loc.locationSettlementLabel,
              icon: Icons.holiday_village_outlined,
              emptyLabel: loc.locationNoSettlementOption,
              value: _selectedSettlementId,
              items: [
                for (final s in _settlementsForSelectedMunicipality)
                  (s.id, s.name),
              ],
              validator: (value) => (value == null || value == 0)
                  ? loc.settlementRequiredError
                  : null,
              onChanged: enabled && _selectedMunicipalityId != null
                  ? (id) => setState(() => _selectedSettlementId = id)
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetCtrl,
              enabled: enabled,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: loc.streetOptionalLabel,
                prefixIcon: const Icon(Icons.signpost_outlined),
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _houseNumberCtrl,
              enabled: enabled,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: loc.houseNumberOptionalLabel,
                prefixIcon: const Icon(Icons.pin_outlined),
                counterText: '',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.photoCountLabel(_selectedImages.length, _maxPhotos),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: enabled && !atPhotoLimit
                      ? _showImageSourceSheet
                      : null,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(loc.addPhotoButtonLabel),
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
                    onRemove: enabled
                        ? () => setState(() => _selectedImages.removeAt(index))
                        : null,
                  ),
                ),
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

  Widget _buildMeterSection(
    ThemeData theme,
    AppLocalizations loc,
    bool enabled,
  ) {
    final meter = _selectedMeter;
    if (meter != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: loc.waterMeterOptionalLabel,
          prefixIcon: const Icon(Icons.water_drop_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                meter.address.isEmpty
                    ? meter.serialNumber
                    : '${meter.serialNumber} - ${meter.address}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: loc.waterMeterClearTooltip,
              icon: const Icon(Icons.close),
              onPressed: enabled
                  ? () => setState(() => _selectedMeter = null)
                  : null,
            ),
          ],
        ),
      );
    }

    final results = _meterResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _meterSearchCtrl,
          enabled: enabled,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _searchMeters(),
          decoration: InputDecoration(
            labelText: loc.waterMeterOptionalLabel,
            hintText: loc.waterMeterSearchHint,
            prefixIcon: const Icon(Icons.water_drop_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: _searchingMeters
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: enabled ? _searchMeters : null,
                  ),
          ),
        ),
        if (results != null && results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              loc.waterMeterNoResults,
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (results != null)
          for (final result in results.take(5))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(result.serialNumber),
              subtitle: Text(
                [
                  result.customerFullName,
                  result.address,
                ].where((p) => p.isNotEmpty).join(' - '),
                overflow: TextOverflow.ellipsis,
              ),
              onTap: enabled ? () => setState(() => _applyMeter(result)) : null,
            ),
      ],
    );
  }

  String? _titleValidator(BuildContext context, String? value) {
    final loc = AppLocalizations.of(context);
    final text = (value ?? '').trim();
    if (text.isEmpty) return loc.fieldRequiredError;
    if (text.length > 150) return loc.faultReportTitleTooLongError;
    return null;
  }

  String? _requiredValidator(BuildContext context, String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).fieldRequiredError;
    }
    return null;
  }
}

/// A single dropdown in the cascading Grad -> Općina -> Naselje picker; `0`
/// is the "none selected" sentinel, a `null` [onChanged] disables the field.
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
  const _PhotoThumbnail({required this.file, required this.onRemove});

  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 76, height: 76, fit: BoxFit.cover),
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
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
