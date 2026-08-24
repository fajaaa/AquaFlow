import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/models/admin_collector_profile.dart';
import 'package:aquaflow_desktop/models/admin_customer_profile.dart';
import 'package:aquaflow_desktop/screens/admin_user_activity_logs_screen.dart';
import 'package:aquaflow_desktop/services/admin_collector_exception.dart';
import 'package:aquaflow_desktop/services/admin_collector_service.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/screens/paged_list_controller.dart';
import 'package:aquaflow_desktop/shared/widgets/empty_state_view.dart';
import 'package:aquaflow_desktop/shared/widgets/error_retry.dart';
import 'package:aquaflow_desktop/shared/widgets/paged_table_pagination_bar.dart';
import 'package:aquaflow_desktop/shared/widgets/refresh_button.dart';
import 'package:aquaflow_desktop/shared/widgets/screen_header.dart';
import 'package:aquaflow_desktop/shared/widgets/table_row_actions.dart';

class AdminCollectorsScreen extends StatefulWidget {
  const AdminCollectorsScreen({super.key});

  @override
  State<AdminCollectorsScreen> createState() => _AdminCollectorsScreenState();
}

class _AdminCollectorsScreenState extends State<AdminCollectorsScreen>
    with PagedListController<AdminCollectorProfile, AdminCollectorsScreen> {
  final AdminCollectorService _service = AdminCollectorService();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Future<({List<AdminCollectorProfile> items, int totalCount})>
  fetchPage() async {
    final pageData = await _service.fetchCollectors(
      page: page,
      pageSize: pageSize,
    );
    return (items: pageData.items, totalCount: pageData.totalCount);
  }

  @override
  String describeError(Object error) {
    return error is AdminCollectorException
        ? error.message
        : 'Došlo je do neočekivane greške.';
  }

  void _openActivityLogs(AdminCollectorProfile profile) {
    context.pushScreen(
      AdminUserActivityLogsScreen(
        userId: profile.userId,
        displayName: profile.label,
      ),
    );
  }

  Future<void> _openCreate() async {
    final draft = await showDialog<_CollectorCreateDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CollectorCreateDialog(),
    );
    if (!mounted || draft == null) return;

    await _runMutation(
      () async {
        await _service.createCollectorUserWithProfile(
          email: draft.email,
          password: draft.password,
          phone: draft.phone,
          firstName: draft.firstName,
          lastName: draft.lastName,
        );
      },
      'Inkasant je dodan.',
      resetPageAfterSuccess: true,
    );
  }

  Future<void> _openEdit(AdminCollectorProfile collector) async {
    AdminCustomerProfile? existingProfile;
    try {
      existingProfile = await _service.fetchCustomerProfile(collector.userId);
    } on AdminCollectorException catch (e) {
      if (!mounted) return;
      showError(e.message);
    }
    if (!mounted) return;

    final draft = await showDialog<_CollectorEditDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CollectorEditorDialog(collector: collector),
    );
    if (!mounted || draft == null) return;

    await _runMutation(() async {
      await _service.updateCollectorUserAndProfile(
        collectorProfileId: collector.id,
        userId: collector.userId,
        email: draft.email,
        phone: draft.phone,
        isActive: draft.isActive,
        password: draft.password,
        firstName: draft.firstName,
        lastName: draft.lastName,
        existingProfileId: existingProfile?.id,
      );
    }, 'Profil inkasanta je sačuvan.');
  }

  // The shared `runMutation` doesn't support an optional page reset, which
  // this screen's create flow needs - so mutations keep this local wrapper,
  // reusing `mutating`/`load`/`showError`/`describeError` from the mixin.
  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage, {
    bool resetPageAfterSuccess = false,
  }) async {
    setState(() => mutating = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await load(resetPage: resetPageAfterSuccess);
    } catch (e) {
      if (!mounted) return;
      showError(describeError(e));
    } finally {
      if (mounted) setState(() => mutating = false);
    }
  }

  @override
  void dispose() {
    disposeController();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
            child: ScreenHeader(
              title: 'Inkasanti',
              subtitle: 'Pregled i uređivanje profila inkasanata za terenski rad.',
              actions: [
                RefreshButton(onRefresh: load, enabled: !mutating),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: loading || mutating ? null : _openCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj inkasanta'),
                ),
              ],
            ),
          ),
          if ((loading && !isInitialLoad) || mutating)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
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

  Widget _buildContent() {
    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = this.error;
    if (error != null) {
      return ErrorRetry(message: error, onRetry: () => load());
    }

    if (items.isEmpty) {
      return const EmptyStateView(
        icon: Icons.assignment_ind_outlined,
        message: 'Nema profila inkasanata.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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
                    columns: const [
                      DataColumn(label: Text('Ime i prezime')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Telefon')),
                      DataColumn(label: Text('Šifra inkasanta')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Akcije')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          onSelectChanged: (_) => _openEdit(item),
                          cells: [
                            DataCell(
                              Text(item.fullName.isEmpty ? '-' : item.fullName),
                            ),
                            DataCell(Text(_textOrDash(item.email))),
                            DataCell(Text(_textOrDash(item.phone))),
                            DataCell(Text(_textOrDash(item.employeeCode))),
                            DataCell(_StatusPill(isActive: item.isActive)),
                            DataCell(
                              TableRowActions(
                                disabled: mutating,
                                extraActions: [
                                  IconButton(
                                    tooltip: 'Uredi profil',
                                    onPressed: mutating
                                        ? null
                                        : () => _openEdit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Aktivnosti',
                                    onPressed: mutating
                                        ? null
                                        : () => _openActivityLogs(item),
                                    icon: const Icon(Icons.history_outlined),
                                  ),
                                ],
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2E7D32) : const Color(0xFF64748B);
    final label = isActive ? 'Aktivan' : 'Neaktivan';
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

class _CollectorCreateDraft {
  const _CollectorCreateDraft({
    required this.email,
    required this.password,
    required this.phone,
    required this.firstName,
    required this.lastName,
  });

  final String email;
  final String password;
  final String phone;
  final String firstName;
  final String lastName;
}

class _CollectorCreateDialog extends StatefulWidget {
  const _CollectorCreateDialog();

  @override
  State<_CollectorCreateDialog> createState() => _CollectorCreateDialogState();
}

class _CollectorCreateDialogState extends State<_CollectorCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _CollectorCreateDraft(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj inkasanta'),
      content: SizedBox(
        width: math.min(560, MediaQuery.sizeOf(context).width - 48),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _GeneratedCodeInfo(),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _firstNameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _firstNameValidator,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Ime',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lastNameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: _lastNameValidator,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Prezime',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: _passwordValidator,
                  decoration: const InputDecoration(
                    labelText: 'Lozinka',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
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
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) return 'Unesite ispravan email.';
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final phonePattern = RegExp(r'^[0-9+\-\s()]+$');
    if (!phonePattern.hasMatch(text) ||
        text.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      return 'Unesite ispravan broj telefona.';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    return null;
  }

  String? _firstNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _lastNameCtrl.text.trim().isNotEmpty) {
      return 'Obavezno ako unosite ime i prezime.';
    }
    return null;
  }

  String? _lastNameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && _firstNameCtrl.text.trim().isNotEmpty) {
      return 'Obavezno ako unosite ime i prezime.';
    }
    return null;
  }
}

/// Fields editable when saving an existing collector - mirrors the shape of
/// the Korisnici screen's `AdminUserDraft`, but scoped to what a collector
/// actually has (no address/language/theme).
class _CollectorEditDraft {
  const _CollectorEditDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.isActive,
    this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isActive;
  final String? password;
}

class _CollectorEditorDialog extends StatefulWidget {
  const _CollectorEditorDialog({required this.collector});

  final AdminCollectorProfile collector;

  @override
  State<_CollectorEditorDialog> createState() => _CollectorEditorDialogState();
}

class _CollectorEditorDialogState extends State<_CollectorEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  late bool _isActive;

  @override
  void initState() {
    super.initState();

    final collector = widget.collector;
    _emailCtrl.text = collector.email;
    _phoneCtrl.text = collector.phone;
    _firstNameCtrl.text = collector.firstName;
    _lastNameCtrl.text = collector.lastName;
    _isActive = collector.isActive;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final password = _passwordCtrl.text.trim();

    Navigator.of(context).pop(
      _CollectorEditDraft(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        isActive: _isActive,
        password: password.isEmpty ? null : password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collector = widget.collector;

    return AlertDialog(
      title: const Text('Uredi profil inkasanta'),
      content: SizedBox(
        width: math.min(560, MediaQuery.sizeOf(context).width - 48),
        height: math.min(560, MediaQuery.sizeOf(context).height - 120),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CollectorFormSectionHeader('Profil'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        decoration: const InputDecoration(labelText: 'Ime'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        decoration: const InputDecoration(labelText: 'Prezime'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: ValueKey(collector.employeeCode),
                  initialValue: collector.employeeCode,
                  enabled: false,
                  style: const TextStyle(letterSpacing: 0.6),
                  decoration: const InputDecoration(
                    labelText: 'Šifra inkasanta (automatski dodijeljena)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 22),

                const _CollectorFormSectionHeader('Kontakt'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.phone,
                        validator: _phoneValidator,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                const _CollectorFormSectionHeader('Nalog'),
                _CollectorStatusSwitchField(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Nova lozinka (ostavi prazno da zadržiš postojeću)',
                    prefixIcon: Icon(Icons.password_outlined),
                  ),
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
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Obavezno polje.';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(text)) return 'Unesite ispravan email.';
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final phonePattern = RegExp(r'^[0-9+\-\s()]+$');
    if (!phonePattern.hasMatch(text) ||
        text.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      return 'Unesite ispravan broj telefona.';
    }
    return null;
  }
}

/// Small uppercase label introducing a group of related fields - mirrors
/// `_FormSectionHeader` on the Korisnici screen's editor dialog.
class _CollectorFormSectionHeader extends StatelessWidget {
  const _CollectorFormSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

/// Mirrors `_StatusSwitchField` on the Korisnici screen's editor dialog.
class _CollectorStatusSwitchField extends StatelessWidget {
  const _CollectorStatusSwitchField({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6ED)),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: value ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ? 'Aktivan' : 'Neaktivan',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _GeneratedCodeInfo extends StatelessWidget {
  const _GeneratedCodeInfo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Šifra inkasanta se automatski kreira nakon spremanja, npr. COL-0002.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _textOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '-' : text;
}
