import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/customer/models/customer_support_ticket.dart';
import 'package:aquaflow_desktop/customer/screens/customer_support_ticket_detail_screen.dart';
import 'package:aquaflow_desktop/customer/services/customer_support_ticket_exception.dart';
import 'package:aquaflow_desktop/customer/services/customer_support_ticket_service.dart';
import 'package:aquaflow_desktop/customer/widgets/new_support_ticket_dialog.dart';
import 'package:aquaflow_desktop/customer/widgets/support_ticket_status_pill.dart';
import 'package:aquaflow_desktop/shared/navigation/app_navigation.dart';

/// "Moji tiketi": full-screen list of ALL of the signed-in customer's support
/// tickets, every status. Pushed as its own Scaffold+AppBar route from the
/// "Podrška" entry on the shared account ("Nalog") screen. Open a new ticket
/// with the "+" action or tap a card to open its chat thread.
///
/// Uses real server-side pagination
/// (`GET /SupportTickets/mine?Page=&PageSize=20&IncludeTotalCount=true&SortBy=LastMessageAt&SortDescending=true`;
/// the backend pins `CustomerId` to the caller): infinite scroll loads the next
/// page near the bottom and stops when a short page arrives or the total count
/// is reached, and pull-to-refresh resets to page 1. Same template as
/// `CustomerFaultReportsScreen`.
class CustomerSupportTicketsScreen extends StatefulWidget {
  const CustomerSupportTicketsScreen({super.key});

  @override
  State<CustomerSupportTicketsScreen> createState() =>
      _CustomerSupportTicketsScreenState();
}

class _CustomerSupportTicketsScreenState
    extends State<CustomerSupportTicketsScreen> {
  static const int _pageSize = 20;

  final CustomerSupportTicketService _service = CustomerSupportTicketService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  int _nextPage = 1;
  List<CustomerSupportTicket> _items = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchMine(page: 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _nextPage = 2;
        _hasMore = result.items.length >= _pageSize &&
            _items.length < result.totalCount;
        _loading = false;
      });
    } on CustomerSupportTicketException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);

    try {
      final result = await _service.fetchMine(
        page: _nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _nextPage += 1;
        final reachedEnd = result.items.length < _pageSize ||
            _items.length >= result.totalCount;
        _hasMore = !reachedEnd;
        _loadingMore = false;
      });
    } on CustomerSupportTicketException catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _openNewTicketDialog() async {
    final created = await showNewSupportTicketDialog(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket je kreiran.')),
      );
      await _loadFirstPage();
    }
  }

  Future<void> _openDetail(CustomerSupportTicket ticket) async {
    await context.pushScreen(
      CustomerSupportTicketDetailScreen(ticketId: ticket.id),
    );
    // A reply or a staff close may have moved the ticket, so refresh on return.
    if (mounted) await _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podrška'),
        actions: [
          IconButton(
            tooltip: 'Novi tiket',
            onPressed: _loading ? null : _openNewTicketDialog,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _loading ? null : _loadFirstPage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorRetry(message: error, onRetry: _loadFirstPage);
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
            const _EmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final ticket = _items[index];
          return _TicketCard(
            ticket: ticket,
            onTap: () => _openDetail(ticket),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final CustomerSupportTicket ticket;
  final VoidCallback onTap;

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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.subject.isEmpty ? '-' : ticket.subject,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SupportTicketStatusPill(status: ticket.status),
                  const Spacer(),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.messageCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label:
                    'Zadnja poruka: ${_formatDate(ticket.lastMessageAt)}',
              ),
            ],
          ),
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
            Icons.support_agent_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Nemate otvorenih tiketa.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Otvorite novi tiket da kontaktirate podršku.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
