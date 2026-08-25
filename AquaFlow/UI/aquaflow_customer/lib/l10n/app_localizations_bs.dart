// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bosnian (`bs`).
class AppLocalizationsBs extends AppLocalizations {
  AppLocalizationsBs([String locale = 'bs']) : super(locale);

  @override
  String get appTitle => 'AquaFlow';

  @override
  String get commonSave => 'Sačuvaj';

  @override
  String get commonCancel => 'Otkaži';

  @override
  String get commonDelete => 'Obriši';

  @override
  String get commonEdit => 'Uredi';

  @override
  String get commonRefresh => 'Osvježi';

  @override
  String get commonSearch => 'Pretraga';

  @override
  String get commonRetry => 'Pokušaj ponovo';

  @override
  String get stateLoading => 'Učitavanje...';

  @override
  String get errorGeneric => 'Greška';

  @override
  String get emptyGeneric => 'Nema podataka';

  @override
  String get emptyList => 'Prazna lista';

  @override
  String get paginationPrevious => 'Prethodna stranica';

  @override
  String get paginationNext => 'Sljedeća stranica';

  @override
  String paginationPageOf(int page, int totalPages) {
    return 'Stranica $page od $totalPages';
  }

  @override
  String paginationTotalCount(int count) {
    return '$count ukupno';
  }
}
