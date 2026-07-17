import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aquaflow_desktop/customer/models/customer_support_ticket.dart';
import 'package:aquaflow_desktop/customer/models/customer_support_ticket_message.dart';
import 'package:aquaflow_desktop/customer/models/customer_support_ticket_photo.dart';
import 'package:aquaflow_desktop/customer/services/customer_support_ticket_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_support_ticket_service.dart';
import 'package:aquaflow_desktop/customer/widgets/support_ticket_status_pill.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';
import 'package:aquaflow_desktop/shared/widgets/authenticated_image.dart';

const int _maxPhotosPerMessage = 5;

/// Chat-thread detail of a single support ticket belonging to the signed-in
/// customer, pushed from `CustomerSupportTicketsScreen` as its own
/// Scaffold+AppBar route (same push pattern as `CustomerFaultReportDetailScreen`).
///
/// Messages render as chat bubbles: staff replies on the left, the customer's
/// own messages on the right (driven by `SupportTicketMessage.isFromStaff`).
/// Attached photos show inline (`CustomerSupportTicketService.fetchPhotoBytes`
/// via `AuthenticatedImage`); tapping one opens a fullscreen preview. A reply
/// composer (text + photo attachments) sits at the bottom while the ticket is
/// Open; once it is Closed the composer is replaced with a "Tiket je zatvoren"
/// banner (the backend rejects a reply to a closed ticket anyway).
class CustomerSupportTicketDetailScreen extends StatefulWidget {
  const CustomerSupportTicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<CustomerSupportTicketDetailScreen> createState() =>
      _CustomerSupportTicketDetailScreenState();
}

class _CustomerSupportTicketDetailScreenState
    extends State<CustomerSupportTicketDetailScreen> {
  final CustomerSupportTicketService _service = CustomerSupportTicketService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _replyCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  CustomerSupportTicket? _ticket;

  final List<File> _selectedImages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _scrollController.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ticket = await _service.fetchById(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _loading = false;
      });
      _scrollToBottom();
    } on CustomerSupportTicketException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _selectedImages.add(File(picked.path)));
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _sendReply() async {
    final body = _replyCtrl.text.trim();
    if (body.isEmpty && _selectedImages.isEmpty) return;
    if (body.isEmpty) {
      // The backend requires a non-empty message body even with photos.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesite tekst poruke.')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final message = await _service.addMessage(
        widget.ticketId,
        body: body,
        images: _selectedImages,
      );
      if (!mounted) return;
      final ticket = _ticket;
      setState(() {
        if (ticket != null) {
          _ticket = CustomerSupportTicket(
            id: ticket.id,
            customerId: ticket.customerId,
            customerName: ticket.customerName,
            subject: ticket.subject,
            status: ticket.status,
            closedAt: ticket.closedAt,
            lastMessageAt: message.createdAt ?? ticket.lastMessageAt,
            messageCount: ticket.messageCount + 1,
            createdAt: ticket.createdAt,
            messages: [...ticket.messages, message],
          );
        }
        _replyCtrl.clear();
        _selectedImages.clear();
        _sending = false;
      });
      _scrollToBottom();
    } on CustomerSupportTicketException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  void _openFullscreen(int messageId, CustomerSupportTicketPhoto photo) {
    context.pushScreen(
      _FullscreenPhotoScreen(
        fileName: photo.fileName,
        fetcher: () =>
            _service.fetchPhotoBytes(widget.ticketId, messageId, photo.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ticket == null || ticket.subject.isEmpty ? 'Tiket' : ticket.subject,
        ),
        actions: [
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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

    final ticket = _ticket;
    if (ticket == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _StatusHeader(ticket: ticket),
        const Divider(height: 1),
        Expanded(child: _buildThread(ticket)),
        if (ticket.isClosed)
          const _ClosedBanner()
        else
          _buildComposer(),
      ],
    );
  }

  Widget _buildThread(CustomerSupportTicket ticket) {
    if (ticket.messages.isEmpty) {
      return Center(
        child: Text(
          'Nema poruka.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: ticket.messages.length,
      itemBuilder: (context, index) {
        final message = ticket.messages[index];
        return _MessageBubble(
          message: message,
          onPhotoTap: (photo) => _openFullscreen(message.id, photo),
          photoBytes: (photo) => _service.fetchPhotoBytes(
            widget.ticketId,
            message.id,
            photo.id,
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    final theme = Theme.of(context);
    final atPhotoLimit = _selectedImages.length >= _maxPhotosPerMessage;
    final enabled = !_sending;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.40)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _ComposerThumbnail(
                    file: _selectedImages[index],
                    onRemove: enabled ? () => _removeImage(index) : null,
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Dodaj sliku',
                onPressed: enabled && !atPhotoLimit
                    ? _showImageSourceSheet
                    : null,
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Napišite poruku...',
                    counterText: '',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton.filled(
                      tooltip: 'Pošalji',
                      onPressed: _sendReply,
                      icon: const Icon(Icons.send),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.ticket});

  final CustomerSupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          SupportTicketStatusPill(status: ticket.status),
          const Spacer(),
          Icon(
            Icons.event_outlined,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Otvoren: ${_formatDate(ticket.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onPhotoTap,
    required this.photoBytes,
  });

  final CustomerSupportTicketMessage message;
  final void Function(CustomerSupportTicketPhoto photo) onPhotoTap;
  final Future<Uint8List> Function(CustomerSupportTicketPhoto photo) photoBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Staff on the left, the customer's own messages on the right.
    final fromStaff = message.isFromStaff;
    final alignment = fromStaff ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor = fromStaff
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primaryContainer;
    final textColor = fromStaff
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimaryContainer;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(fromStaff ? 2 : 14),
      bottomRight: Radius.circular(fromStaff ? 14 : 2),
    );
    final senderLabel = fromStaff
        ? (message.senderName?.trim().isNotEmpty == true
            ? message.senderName!.trim()
            : 'Podrška')
        : 'Vi';

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    fromStaff
                        ? Icons.support_agent_outlined
                        : Icons.person_outline,
                    size: 13,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    senderLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (message.body.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              ],
              if (message.photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final photo in message.photos)
                      GestureDetector(
                        onTap: () => onPhotoTap(photo),
                        child: AuthenticatedImage(
                          fetcher: () => photoBytes(photo),
                          width: 108,
                          height: 108,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.40)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Tiket je zatvoren',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerThumbnail extends StatelessWidget {
  const _ComposerThumbnail({required this.file, required this.onRemove});

  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 60, height: 60, fit: BoxFit.cover),
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

class _FullscreenPhotoScreen extends StatelessWidget {
  const _FullscreenPhotoScreen({required this.fileName, required this.fetcher});

  final String fileName;
  final Future<Uint8List> Function() fetcher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(fileName),
      ),
      body: Center(
        child: InteractiveViewer(
          child: AuthenticatedImage(fetcher: fetcher, fit: BoxFit.contain),
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

String _formatTime(DateTime? date) {
  if (date == null) return '';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}. ${two(date.hour)}:${two(date.minute)}';
}
