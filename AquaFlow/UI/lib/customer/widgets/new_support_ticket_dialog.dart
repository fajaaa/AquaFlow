import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aquaflow_desktop/customer/services/customer_support_ticket_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_support_ticket_service.dart';

const int _maxPhotos = 5;

/// Opens the "Novi tiket" dialog and resolves to `true` when a ticket was
/// successfully created. Reached from `CustomerSupportTicketsScreen`.
Future<bool?> showNewSupportTicketDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const NewSupportTicketDialog(),
  );
}

/// Modal form for a new support ticket: Naslov (subject), Poruka (first
/// message), and up to [_maxPhotos] photos (camera or gallery, `image_picker`).
/// Same template as `NewFaultReportDialog`, but the ticket and its photos are
/// created in a single multipart request (`CustomerSupportTicketService.createTicket`)
/// - the backend attaches the photos to the opening message - so there is no
/// separate per-photo upload loop.
class NewSupportTicketDialog extends StatefulWidget {
  const NewSupportTicketDialog({super.key});

  @override
  State<NewSupportTicketDialog> createState() => _NewSupportTicketDialogState();
}

class _NewSupportTicketDialogState extends State<NewSupportTicketDialog> {
  final CustomerSupportTicketService _service = CustomerSupportTicketService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();

  final List<File> _selectedImages = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _service.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
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

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _service.createTicket(
        subject: _subjectCtrl.text,
        body: _bodyCtrl.text,
        images: _selectedImages,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CustomerSupportTicketException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atPhotoLimit = _selectedImages.length >= _maxPhotos;
    final enabled = !_submitting;

    return AlertDialog(
      title: const Text('Novi tiket'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _subjectCtrl,
                  enabled: enabled,
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
                  controller: _bodyCtrl,
                  enabled: enabled,
                  maxLines: 5,
                  maxLength: 2000,
                  validator: _requiredValidator,
                  decoration: const InputDecoration(
                    labelText: 'Poruka',
                    alignLabelWithHint: true,
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
                        onRemove: enabled ? () => _removeImage(index) : null,
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pošalji'),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Obavezno polje.';
    return null;
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
