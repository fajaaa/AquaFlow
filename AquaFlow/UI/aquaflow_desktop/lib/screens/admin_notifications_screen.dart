import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';
import 'package:aquaflow_desktop/models/admin_notification_draft.dart';
import 'package:aquaflow_desktop/models/admin_notification_image.dart';
import 'package:aquaflow_desktop/services/admin_notification_service.dart';
import 'package:aquaflow_desktop/shared/models/app_notification.dart';
import 'package:aquaflow_desktop/shared/providers/auth_provider.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/services/notification_exception.dart';
import 'package:aquaflow_desktop/shared/widgets/authenticated_image.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

const int _maxNotificationImages = 5;

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with PagedListController<AppNotification, AdminNotificationsScreen> {
  final AdminNotificationService _service = AdminNotificationService();

  String? _typeFilter;
  String? _audienceFilter;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AppNotification> items, int totalCount})> fetchPage() async {
    final pageData = await _service.fetch(
      page: page,
      pageSize: pageSize,
      search: searchController.text,
      type: _typeFilter,
      audience: _audienceFilter,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is NotificationException
        ? error.message
        : AppLocalizations.of(context).unexpectedError;
  }

  void _setTypeFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _typeFilter) return;
    setState(() => _typeFilter = selected);
    load(resetPage: true);
  }

  void _setAudienceFilter(String value) {
    final selected = value.isEmpty ? null : value;
    if (selected == _audienceFilter) return;
    setState(() => _audienceFilter = selected);
    load(resetPage: true);
  }

  // The dialog now owns the full save flow itself (create/update the notification, then
  // upload any picked images against its id - see _NotificationEditorDialogState._save),
  // since uploading images requires the notification to already exist. It resolves to
  // `true` on success rather than a draft, so this just reloads the list; runMutation is
  // still reused (with a no-op action) purely for its snackbar + mutating-flag plumbing.
  Future<void> _openCreate() async {
    final createdById = context.read<AuthProvider>().session?.id;
    if (createdById == null || createdById <= 0) {
      showError(AppLocalizations.of(context).cannotDetermineAdminUserError);
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NotificationEditorDialog(createdById: createdById),
    );
    if (!mounted || saved != true) return;

    await runMutation(
      () async {},
      AppLocalizations.of(context).notificationCreatedSuccess,
    );
  }

  Future<void> _openEdit(AppNotification notification) async {
    final sessionUserId = context.read<AuthProvider>().session?.id;
    final createdById = notification.createdById > 0
        ? notification.createdById
        : sessionUserId;
    if (createdById == null || createdById <= 0) {
      showError(
        AppLocalizations.of(context).cannotDetermineNotificationAuthorError,
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NotificationEditorDialog(
        notification: notification,
        createdById: createdById,
      ),
    );
    if (!mounted || saved != true) return;

    await runMutation(
      () async {},
      AppLocalizations.of(context).notificationSavedSuccess,
    );
  }

  Future<void> _confirmDelete(AppNotification notification) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteNotificationDialogTitle),
        content: Text(loc.deleteNotificationDialogContent(notification.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.dialogDismissButton),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(loc.commonDelete),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await runMutation(() async {
      await _service.delete(notification.id);
      if (items.length == 1 && page > 1) {
        page -= 1;
      }
    }, AppLocalizations.of(context).notificationDeletedSuccess);
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  title: loc.tabNotifications,
                  subtitle: loc.notificationsScreenSubtitle,
                  actions: [
                    RefreshButton(onRefresh: () => load(), enabled: !mutating),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: loading || mutating ? null : _openCreate,
                      icon: const Icon(Icons.add),
                      label: Text(loc.newNotificationButtonLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildFilters(loc),
              ],
            ),
          ),
          if ((loading && !isInitialLoad) || mutating)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent(loc)),
          if (!isInitialLoad && error == null)
            PagedTablePaginationBar(
              page: page,
              totalPages: totalPages,
              totalCount: totalCount,
              pageSize: pageSize,
              loading: loading || mutating,
              onPageChanged: goToPage,
              onPageSizeChanged: setPageSize,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations loc) {
    final hasSearch = searchController.text.trim().isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: queueSearch,
            onSubmitted: submitSearch,
            decoration: InputDecoration(
              labelText: loc.commonSearch,
              hintText: loc.notificationSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearch
                  ? IconButton(
                      tooltip: loc.clearSearchTooltip,
                      onPressed: clearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<String>(
            initialValue: _typeFilter ?? '',
            decoration: InputDecoration(
              labelText: loc.typeFieldLabel,
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(loc.notificationsAllTypesOption),
              ),
              for (final option in _notificationTypeOptions(loc))
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: loading || mutating
                ? null
                : (value) => _setTypeFilter(value ?? ''),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _audienceFilter ?? '',
            decoration: InputDecoration(
              labelText: loc.audienceFieldLabel,
              prefixIcon: const Icon(Icons.group_outlined),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(loc.allAudiencesOption)),
              for (final option in _audienceOptions(loc))
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: loading || mutating
                ? null
                : (value) => _setAudienceFilter(value ?? ''),
          ),
        ),
        IconButton.filledTonal(
          tooltip: loc.applyFiltersTooltip,
          onPressed: loading || mutating ? null : () => load(resetPage: true),
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations loc) {
    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = this.error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => load());
    }

    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.notifications_none,
        message: loc.notificationsEmptyMessage,
        hasFilters: _hasFilters,
        filteredIcon: Icons.search_off,
        filteredMessage: loc.notificationsFilteredEmptyMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 900;

        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 56),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.30),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 72,
                    columns: [
                      DataColumn(label: Text(loc.notificationColumnLabel)),
                      DataColumn(label: Text(loc.typeFieldLabel)),
                      if (!isSmallScreen)
                        DataColumn(label: Text(loc.audienceFieldLabel)),
                      if (!isSmallScreen)
                        DataColumn(label: Text(loc.createdAtColumnLabel)),
                      DataColumn(label: Text(loc.actionsColumnLabel)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(_NotificationTitleCell(item: item)),
                            DataCell(
                              _InfoPill(
                                icon: _typeIcon(item.type),
                                label: _typeLabel(item.type, loc),
                                color: _typeColor(
                                  item.type,
                                  Theme.of(context).colorScheme,
                                ),
                              ),
                            ),
                            if (!isSmallScreen)
                              DataCell(
                                Text(_audienceLabel(item.audience, loc)),
                              ),
                            if (!isSmallScreen)
                              DataCell(Text(_formatDate(item.createdAt))),
                            DataCell(
                              TableRowActions(
                                disabled: mutating,
                                onEdit: () => _openEdit(item),
                                onDelete: () => _confirmDelete(item),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _hasFilters =>
      searchController.text.trim().isNotEmpty ||
      _typeFilter != null ||
      _audienceFilter != null;
}

class _NotificationTitleCell extends StatelessWidget {
  const _NotificationTitleCell({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item.title.trim().isEmpty
        ? AppLocalizations.of(context).notificationFallbackTitle(item.id)
        : item.title.trim();
    final body = _truncate(item.body.trim(), 50);

    return SizedBox(
      width: 340,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create/edit dialog for a notification. Unlike the old draft-returning version, this
/// dialog now owns the full save flow itself - it calls create/update directly (needs the
/// notification's own id to upload images against) and resolves to a plain `bool` (success)
/// instead of a draft. Mirrors `NewFaultReportDialog`'s "save entity, then upload picked
/// images sequentially with progress, dialog stays open on error to retry" pattern - see
/// that widget for the precedent. Unlike fault reports, a Notification supports Update as
/// well as Create, so (deliberately, unlike NewFaultReportDialog) the Title/Body/Type/
/// Audience fields are never locked after the first save: re-pressing "Sačuvaj" after a
/// failed image upload just re-runs Update (harmless/idempotent) and resumes uploading.
class _NotificationEditorDialog extends StatefulWidget {
  const _NotificationEditorDialog({
    required this.createdById,
    this.notification,
  });

  final int createdById;
  final AppNotification? notification;

  @override
  State<_NotificationEditorDialog> createState() =>
      _NotificationEditorDialogState();
}

class _NotificationEditorDialogState extends State<_NotificationEditorDialog> {
  final AdminNotificationService _service = AdminNotificationService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  late String _type;
  late String _audience;

  bool get _isEdit => widget.notification != null;

  AppNotification? _savedNotification;
  bool _submitting = false;
  String? _error;

  bool _loadingImages = false;
  String? _imagesError;
  List<AdminNotificationImage> _existingImages = const [];
  final List<File> _selectedImages = [];
  int _uploadedImageCount = 0;

  int get _totalImageCount => _existingImages.length + _selectedImages.length;

  @override
  void initState() {
    super.initState();
    final notification = widget.notification;
    _titleCtrl.text = notification?.title ?? '';
    _bodyCtrl.text = notification?.body ?? '';
    _type = notification?.type.trim().isNotEmpty == true
        ? notification!.type
        : 'Info';
    _audience = notification?.audience.trim().isNotEmpty == true
        ? notification!.audience
        : 'All';
    _savedNotification = notification;
    if (notification != null) {
      _loadImages(notification.id);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadImages(int notificationId) async {
    setState(() {
      _loadingImages = true;
      _imagesError = null;
    });

    try {
      final images = await _service.fetchImages(notificationId);
      if (!mounted) return;
      setState(() {
        _existingImages = images;
        _loadingImages = false;
      });
    } on NotificationException catch (e) {
      if (!mounted) return;
      setState(() {
        _imagesError = e.message;
        _loadingImages = false;
      });
    }
  }

  // This screen is desktop-only (see PlatformGate), where image_picker has no camera
  // source - only ImageSource.gallery, which itself opens the native OS file picker.
  // So there's no real choice to offer here; go straight to the file picker instead of
  // showing a bottom sheet with a "Slikaj" (camera) option that can't work on desktop.
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedImages.add(File(picked.path)));
  }

  void _removeSelectedImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // Deletes an already-persisted image immediately (independent of "Sačuvaj") - images are
  // addable/removable after the notification exists, not just at creation time.
  Future<void> _removeExistingImage(AdminNotificationImage image) async {
    final notificationId = _savedNotification?.id;
    if (notificationId == null) return;

    try {
      await _service.deleteImage(notificationId, image.id);
      if (!mounted) return;
      setState(() {
        _existingImages = _existingImages
            .where((existing) => existing.id != image.id)
            .toList();
      });
    } on NotificationException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final draft = AdminNotificationDraft(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      type: _type,
      audience: _audience,
      createdById: widget.createdById,
    );

    try {
      var saved = _savedNotification;
      saved = saved == null
          ? await _service.create(draft)
          : await _service.update(saved.id, draft);
      if (!mounted) return;
      setState(() => _savedNotification = saved);

      for (var i = _uploadedImageCount; i < _selectedImages.length; i++) {
        await _service.uploadImage(saved.id, _selectedImages[i]);
        if (!mounted) return;
        setState(() => _uploadedImageCount = i + 1);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on NotificationException catch (e) {
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
    final typeOptions = _optionsWithCurrent(
      _notificationTypeOptions(loc),
      _type,
    );
    final audienceOptions = _optionsWithCurrent(
      _audienceOptions(loc),
      _audience,
    );
    final theme = Theme.of(context);
    final enabled = !_submitting;
    final atImageLimit = _totalImageCount >= _maxNotificationImages;

    return AlertDialog(
      title: Text(
        _isEdit
            ? loc.editNotificationDialogTitle
            : loc.newNotificationButtonLabel,
      ),
      content: SizedBox(
        width: math.min(640, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  enabled: enabled,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  validator: (value) => _required(context, value),
                  decoration: InputDecoration(
                    labelText: loc.titleColumnLabel,
                    prefixIcon: const Icon(Icons.title),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bodyCtrl,
                  enabled: enabled,
                  minLines: 4,
                  maxLines: 7,
                  validator: (value) => _required(context, value),
                  decoration: InputDecoration(
                    labelText: loc.contentFieldLabel,
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: InputDecoration(
                          labelText: loc.typeFieldLabel,
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: [
                          for (final option in typeOptions)
                            DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: enabled
                            ? (value) {
                                if (value == null) return;
                                setState(() => _type = value);
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _audience,
                        decoration: InputDecoration(
                          labelText: loc.audienceFieldLabel,
                          prefixIcon: const Icon(Icons.group_outlined),
                        ),
                        items: [
                          for (final option in audienceOptions)
                            DropdownMenuItem(
                              value: option.value,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: enabled
                            ? (value) {
                                if (value == null) return;
                                setState(() => _audience = value);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.imagesCountLabel(
                          _totalImageCount,
                          _maxNotificationImages,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: enabled && !atImageLimit ? _pickImage : null,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(loc.addImageButtonLabel),
                    ),
                  ],
                ),
                if (_loadingImages)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (_imagesError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _imagesError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                if (_existingImages.isNotEmpty ||
                    _selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 84,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final image in _existingImages)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ExistingImageThumbnail(
                              image: image,
                              fetcher: () => _service.fetchImageBytes(
                                _savedNotification!.id,
                                image.id,
                              ),
                              onRemove: enabled
                                  ? () => _removeExistingImage(image)
                                  : null,
                            ),
                          ),
                        for (var i = 0; i < _selectedImages.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _NewImageThumbnail(
                              file: _selectedImages[i],
                              uploaded: i < _uploadedImageCount,
                              onRemove: enabled
                                  ? () => _removeSelectedImage(i)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (_submitting &&
                    _uploadedImageCount < _selectedImages.length) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _uploadedImageCount / _selectedImages.length,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.uploadingImageLabel(
                      _uploadedImageCount + 1,
                      _selectedImages.length,
                    ),
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(loc.dialogDismissButton),
        ),
        FilledButton.icon(
          onPressed: enabled ? _save : null,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(loc.commonSave),
        ),
      ],
    );
  }

  String? _required(BuildContext context, String? value) {
    return value == null || value.trim().isEmpty
        ? AppLocalizations.of(context).fieldRequiredError
        : null;
  }
}

class _ExistingImageThumbnail extends StatelessWidget {
  const _ExistingImageThumbnail({
    required this.image,
    required this.fetcher,
    required this.onRemove,
  });

  final AdminNotificationImage image;
  final Future<Uint8List> Function() fetcher;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthenticatedImage(
          fetcher: fetcher,
          width: 76,
          height: 76,
          borderRadius: BorderRadius.circular(8),
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

class _NewImageThumbnail extends StatelessWidget {
  const _NewImageThumbnail({
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
          child: Image.file(file, width: 76, height: 76, fit: BoxFit.cover),
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
              child: const Icon(Icons.check, size: 14, color: Colors.white),
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
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _SelectOption {
  const _SelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

List<_SelectOption> _notificationTypeOptions(AppLocalizations loc) => [
  _SelectOption(value: 'Info', label: loc.notificationTypeInfoLabel),
  _SelectOption(
    value: 'PlannedWorks',
    label: loc.notificationTypePlannedWorksLabel,
  ),
  _SelectOption(value: 'Warning', label: loc.notificationTypeWarningLabel),
];

List<_SelectOption> _audienceOptions(AppLocalizations loc) => [
  _SelectOption(value: 'All', label: loc.allUsersAudienceLabel),
  _SelectOption(value: 'Customers', label: loc.customersAudienceLabel),
  _SelectOption(value: 'Collectors', label: loc.collectorsNavLabel),
];

List<_SelectOption> _optionsWithCurrent(
  List<_SelectOption> options,
  String current,
) {
  final value = current.trim();
  if (value.isEmpty ||
      options.any(
        (option) => option.value.toLowerCase() == value.toLowerCase(),
      )) {
    return options;
  }
  return [...options, _SelectOption(value: value, label: value)];
}

IconData _typeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'plannedworks':
      return Icons.construction_outlined;
    case 'warning':
      return Icons.warning_amber_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _typeColor(String type, ColorScheme colorScheme) {
  switch (type.toLowerCase()) {
    case 'plannedworks':
      return const Color(0xFF0277BD);
    case 'warning':
      return const Color(0xFFF9A825);
    default:
      return colorScheme.primary;
  }
}

String _typeLabel(String type, AppLocalizations loc) {
  switch (type.toLowerCase()) {
    case 'plannedworks':
      return loc.notificationTypePlannedWorksLabel;
    case 'warning':
      return loc.notificationTypeWarningLabel;
    default:
      return type.isEmpty ? loc.notificationTypeGenericLabel : type;
  }
}

String _audienceLabel(String audience, AppLocalizations loc) {
  switch (audience.toLowerCase()) {
    case 'all':
      return loc.allUsersAudienceLabel;
    case 'settlement':
      return loc.settlementAudienceLabel;
    case 'customer':
    case 'customers':
      return loc.customersAudienceLabel;
    case 'collector':
    case 'collectors':
      return loc.collectorsNavLabel;
    default:
      return audience.isEmpty ? loc.audienceFieldLabel : audience;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}. '
      '${two(date.hour)}:${two(date.minute)}';
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength).trimRight()}...';
}
