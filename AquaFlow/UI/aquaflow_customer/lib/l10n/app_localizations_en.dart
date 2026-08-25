// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AquaFlow';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonRetry => 'Try again';

  @override
  String get stateLoading => 'Loading...';

  @override
  String get errorGeneric => 'Error';

  @override
  String get emptyGeneric => 'No data';

  @override
  String get emptyList => 'Empty list';

  @override
  String get paginationPrevious => 'Previous page';

  @override
  String get paginationNext => 'Next page';

  @override
  String paginationPageOf(int page, int totalPages) {
    return 'Page $page of $totalPages';
  }

  @override
  String paginationTotalCount(int count) {
    return '$count total';
  }
}
