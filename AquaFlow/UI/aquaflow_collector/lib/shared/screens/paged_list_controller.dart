import 'dart:async';

import 'package:flutter/material.dart';

/// Shared paged-list state management for admin CRUD screens: paging,
/// debounced search, loading/mutating flags, and mutation error handling.
///
/// Screens implement [fetchPage] (the actual API call for the current
/// page/filters) and [describeError] (exception -> user-facing message);
/// the mixin owns everything else - page/pageSize, the search controller
/// and its debounce, the request-serial guard against out-of-order
/// responses, and [runMutation] for create/update/delete flows.
mixin PagedListController<T, W extends StatefulWidget> on State<W> {
  final TextEditingController searchController = TextEditingController();

  Timer? _searchDebounce;
  int _requestSerial = 0;
  bool _hasPageData = false;

  int page = 1;
  int pageSize = 10;
  bool loading = true;
  bool mutating = false;
  String? error;
  List<T> items = <T>[];
  int totalCount = 0;

  Future<({List<T> items, int totalCount})> fetchPage();

  String describeError(Object error);

  int get totalPages {
    if (totalCount <= 0) return 1;
    return (totalCount / pageSize).ceil();
  }

  bool get isInitialLoad => loading && !_hasPageData;

  Future<void> load({bool resetPage = false}) async {
    final requestId = ++_requestSerial;

    setState(() {
      if (resetPage) page = 1;
      loading = true;
      error = null;
    });

    try {
      final result = await fetchPage();
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        items = result.items;
        totalCount = result.totalCount;
        loading = false;
        _hasPageData = true;
      });
    } catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        items = <T>[];
        totalCount = 0;
        loading = false;
        _hasPageData = false;
        error = describeError(e);
      });
    }
  }

  void queueSearch(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => load(resetPage: true),
    );
  }

  void submitSearch(String _) {
    _searchDebounce?.cancel();
    load(resetPage: true);
  }

  void clearSearch() {
    if (searchController.text.isEmpty) return;
    _searchDebounce?.cancel();
    searchController.clear();
    setState(() {});
    load(resetPage: true);
  }

  void goToPage(int newPage) {
    if (newPage == page || loading) return;
    setState(() => page = newPage);
    load();
  }

  void setPageSize(int? value) {
    if (value == null || value == pageSize || loading) return;
    setState(() {
      pageSize = value;
      page = 1;
    });
    load();
  }

  Future<void> runMutation(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => mutating = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await load();
    } catch (e) {
      if (!mounted) return;
      showError(describeError(e));
    } finally {
      if (mounted) setState(() => mutating = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void disposeController() {
    _searchDebounce?.cancel();
    searchController.dispose();
  }
}
