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
  String get commonLogout => 'Odjava';

  @override
  String get desktopUnavailableTitle => 'Nedostupno na računaru';

  @override
  String get desktopUnavailableMessage =>
      'Desktop aplikacija je namijenjena samo administratorima. Za vašu ulogu koristite mobilnu aplikaciju.';

  @override
  String get stateLoading => 'Učitavanje...';

  @override
  String get errorGeneric => 'Greška';

  @override
  String get emptyGeneric => 'Nema podataka';

  @override
  String sectionNotImplementedMessage(String label) {
    return 'Sekcija \"$label\" još nije implementirana.';
  }

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

  @override
  String get commonSaving => 'Spašavanje...';

  @override
  String get loginTitle => 'Prijava';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get emailRequiredError => 'Email je obavezan.';

  @override
  String get emailInvalidError => 'Unesite ispravan email.';

  @override
  String get fieldPasswordLabel => 'Lozinka';

  @override
  String get passwordRequiredError => 'Lozinka je obavezna.';

  @override
  String get loginRememberMe => 'Zapamti me';

  @override
  String get welcomeTagline => 'Svaka kap, evidentirana.';

  @override
  String get welcomeSubtitle =>
      'Mali koraci u štednji vode prave velike valove promjena.';

  @override
  String get authLoginButton => 'Prijavi se';

  @override
  String get loginFailedError => 'Prijava nije uspjela.';

  @override
  String get registerTitle => 'Registracija';

  @override
  String get fieldFirstNameLabel => 'Ime';

  @override
  String get firstNameRequiredError => 'Ime je obavezno.';

  @override
  String get fieldLastNameLabel => 'Prezime';

  @override
  String get lastNameRequiredError => 'Prezime je obavezno.';

  @override
  String get fieldPhoneLabel => 'Telefon';

  @override
  String get phoneInvalidError =>
      'Telefon smije sadržavati samo brojeve i simbole + - ( ).';

  @override
  String get passwordTooShortError => 'Lozinka mora imati najmanje 6 znakova.';

  @override
  String get fieldConfirmPasswordLabel => 'Potvrdi lozinku';

  @override
  String get passwordMismatchError => 'Lozinke se ne podudaraju.';

  @override
  String get registerThemeLabel => 'Tema';

  @override
  String get themeLightOption => 'Svijetla';

  @override
  String get themeDarkOption => 'Tamna';

  @override
  String get authRegisterButton => 'Registruj se';

  @override
  String get registrationFailedError => 'Registracija nije uspjela.';

  @override
  String get passwordResetTitle => 'Promjena lozinke';

  @override
  String get passwordResetDescription =>
      'Unesite trenutnu i novu lozinku da biste je promijenili.';

  @override
  String get passwordResetCurrentLabel => 'Trenutna lozinka';

  @override
  String get passwordResetNewLabel => 'Nova lozinka';

  @override
  String get passwordResetConfirmLabel => 'Potvrda nove lozinke';

  @override
  String get passwordResetSubmitButton => 'Promijeni lozinku';

  @override
  String get passwordResetSuccess => 'Lozinka je promijenjena.';

  @override
  String get passwordResetCurrentRequiredError => 'Unesite trenutnu lozinku.';

  @override
  String get passwordResetNewRequiredError => 'Unesite novu lozinku.';

  @override
  String get fieldRequiredError => 'Obavezno polje.';

  @override
  String get notLoggedInError => 'Niste prijavljeni.';

  @override
  String themeSaveFailedError(String message) {
    return 'Tema nije sačuvana: $message';
  }

  @override
  String languageSaveFailedError(String message) {
    return 'Jezik nije sačuvan: $message';
  }

  @override
  String get personalDetailsAppearanceSectionTitle => 'Izgled';

  @override
  String get nameRequiredTogetherError => 'Obavezno ako unosite ime i prezime.';

  @override
  String get dialogDismissButton => 'Odustani';

  @override
  String get addressLabel => 'Adresa';

  @override
  String get tabNotifications => 'Obavijesti';

  @override
  String get faultReportsScreenTitle => 'Prijave kvarova';

  @override
  String get logoutLabel => 'Odjava';

  @override
  String get companySettingsScreenTitle => 'Postavke firme';

  @override
  String get companyNameLabel => 'Naziv firme';

  @override
  String get taxNumberLabel => 'Porezni broj';

  @override
  String get bankAccountLabel => 'Bankovni račun';

  @override
  String get logoUrlOptionalLabel => 'URL logotipa (opcionalno)';

  @override
  String get defaultLanguageLabel => 'Jezik';

  @override
  String get defaultCurrencyLabel => 'Valuta';

  @override
  String get companySettingsSaveSuccess => 'Postavke firme su sačuvane.';

  @override
  String get myAccountTitle => 'Moj nalog';

  @override
  String get myAccountSubtitle =>
      'Uredite svoje podatke, izgled aplikacije i lozinku.';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get contactSectionLabel => 'Kontakt';

  @override
  String get passwordOptionalHint =>
      'Ostavite prazno ako ne mijenjate lozinku.';

  @override
  String get phoneInvalidNumberError => 'Unesite ispravan broj telefona.';

  @override
  String get accountDetailsSaveSuccess => 'Podaci naloga su sačuvani.';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get usersLabel => 'Korisnici';

  @override
  String get collectorsNavLabel => 'Inkasanti';

  @override
  String get administratorsLabel => 'Administratori';

  @override
  String get financeGroupLabel => 'Finansije';

  @override
  String get invoicesLabel => 'Računi';

  @override
  String get paymentsLabel => 'Plaćanja';

  @override
  String get tariffsNavLabel => 'Tarife';

  @override
  String get supportGroupLabel => 'Podrška';

  @override
  String get waterMeterRequestsNavLabel => 'Zahtjevi';

  @override
  String get systemGroupLabel => 'Sistem';

  @override
  String get codebookLabel => 'Šifarnik';

  @override
  String get dashboardOverviewSubtitle => 'Pregled ključnih pokazatelja';

  @override
  String get dashboardRevenueTrendChartTitle => 'Prihod od naplate';

  @override
  String get dashboardInvoiceStatusChartTitle => 'Status računa';

  @override
  String get dashboardConsumptionTrendChartTitle => 'Potrošnja vode';

  @override
  String get dashboardFaultReportStatusChartTitle =>
      'Prijave kvarova po statusu';

  @override
  String get dashboardUserGrowthChartTitle => 'Rast korisničke baze';

  @override
  String get dashboardWaterMeterRequestStatusChartTitle =>
      'Zahtjevi za vodomjere po statusu';

  @override
  String get dashboardFilterCityLabel => 'Grad';

  @override
  String get dashboardFilterAllCities => 'Svi gradovi';

  @override
  String get dashboardFilterDateRangeTooltip => 'Odaberi raspon datuma';

  @override
  String get dashboardFilterReset => 'Resetuj filtere';

  @override
  String get statusFieldLabel => 'Status';

  @override
  String get allOption => 'Svi';

  @override
  String get statusActive => 'Aktivan';

  @override
  String get statusInactive => 'Neaktivan';

  @override
  String get unexpectedError => 'Došlo je do neočekivane greške.';

  @override
  String get fullNameColumnLabel => 'Ime i prezime';

  @override
  String get createdColumnLabel => 'Kreiran';

  @override
  String get actionsColumnLabel => 'Akcije';

  @override
  String get activitiesTooltip => 'Aktivnosti';

  @override
  String get accountSectionLabel => 'Nalog';

  @override
  String get newPasswordOptionalLabel =>
      'Nova lozinka (ostavi prazno da zadržiš postojeću)';

  @override
  String get commonClose => 'Zatvori';

  @override
  String get waterMeterStatusRemoved => 'Uklonjen';

  @override
  String get initialReadingLabel => 'Početno očitanje';

  @override
  String get usersScreenSubtitle =>
      'Pregled, dodavanje, uređivanje i brisanje korisničkih naloga.';

  @override
  String get administratorsScreenSubtitle =>
      'Pregled, dodavanje, uređivanje i brisanje administratorskih naloga.';

  @override
  String get newUserButtonLabel => 'Novi korisnik';

  @override
  String get newAdministratorButtonLabel => 'Novi administrator';

  @override
  String get editUserDialogTitle => 'Uredi korisnika';

  @override
  String get editAdministratorDialogTitle => 'Uredi administratora';

  @override
  String get userCreatedSuccess => 'Korisnik je dodan.';

  @override
  String get administratorCreatedSuccess => 'Administrator je dodan.';

  @override
  String get userSavedSuccess => 'Korisnik je sačuvan.';

  @override
  String get administratorSavedSuccess => 'Administrator je sačuvan.';

  @override
  String get deleteUserDialogTitle => 'Obriši korisnika';

  @override
  String get deleteAdministratorDialogTitle => 'Obriši administratora';

  @override
  String deleteUserDialogContent(String email) {
    return 'Da li želite obrisati korisnika \"$email\"? Ova radnja se ne može poništiti.';
  }

  @override
  String deleteAdministratorDialogContent(String email) {
    return 'Da li želite obrisati administratora \"$email\"? Ova radnja se ne može poništiti.';
  }

  @override
  String get userDeletedSuccess => 'Korisnik je obrisan.';

  @override
  String get administratorDeletedSuccess => 'Administrator je obrisan.';

  @override
  String get usersEmptyMessage => 'Nema korisnika.';

  @override
  String get administratorsEmptyMessage => 'Nema administratora.';

  @override
  String get usersEmptyFilteredMessage => 'Nema korisnika za zadane filtere.';

  @override
  String get administratorsEmptyFilteredMessage =>
      'Nema administratora za zadane filtere.';

  @override
  String get nameSearchHint => 'Ime ili prezime';

  @override
  String get clearSearchTooltip => 'Očisti pretragu';

  @override
  String get applyFiltersTooltip => 'Primijeni filtere';

  @override
  String get rolesNotLoadedError => 'Uloge nisu učitane. Pokušajte ponovo.';

  @override
  String roleNotFoundError(String roleName) {
    return 'Rola \"$roleName\" nije pronađena.';
  }

  @override
  String get waterMetersTooltip => 'Vodomjeri';

  @override
  String get cannotDeleteOwnAccountError =>
      'Ne možete obrisati vlastiti korisnički nalog.';

  @override
  String get customerCodeFieldLabel =>
      'Šifra korisnika (automatski dodijeljena)';

  @override
  String get cannotDeactivateOwnAccountError =>
      'Ne možete deaktivirati vlastiti nalog.';

  @override
  String get nameRequiredForAddressError =>
      'Unesite ime i prezime da biste sačuvali adresu.';

  @override
  String get collectorsScreenSubtitle =>
      'Pregled i uređivanje profila inkasanata za terenski rad.';

  @override
  String get addCollectorButtonLabel => 'Dodaj inkasanta';

  @override
  String get collectorCreatedSuccess => 'Inkasant je dodan.';

  @override
  String get collectorProfileSavedSuccess => 'Profil inkasanta je sačuvan.';

  @override
  String get collectorsEmptyMessage => 'Nema profila inkasanata.';

  @override
  String get collectorCodeColumnLabel => 'Šifra inkasanta';

  @override
  String get editProfileTooltip => 'Uredi profil';

  @override
  String get collectorCodeGeneratedHint =>
      'Šifra inkasanta se automatski kreira nakon spremanja, npr. COL-0002.';

  @override
  String get editCollectorProfileDialogTitle => 'Uredi profil inkasanta';

  @override
  String get collectorCodeFieldLabel =>
      'Šifra inkasanta (automatski dodijeljena)';

  @override
  String activityLogTitle(String displayName) {
    return 'Aktivnosti - $displayName';
  }

  @override
  String get eventTypeFieldLabel => 'Događaj';

  @override
  String get activityTypeLoginSuccess => 'Uspješna prijava';

  @override
  String get activityTypeLoginFailed => 'Neuspješna prijava';

  @override
  String get activityTypeTokenRefreshed => 'Obnova sesije';

  @override
  String get activityTypePasswordChanged => 'Promjena lozinke';

  @override
  String get activityTypeAccountUpdated => 'Izmjena naloga';

  @override
  String get activityTypeUserRoleChanged => 'Promjena role';

  @override
  String get activityTypeUserActivated => 'Korisnik aktiviran';

  @override
  String get activityTypeUserDeactivated => 'Korisnik deaktiviran';

  @override
  String get activityTypeUserDeleted => 'Korisnik obrisan';

  @override
  String get activityTypeGenericLabel => 'Aktivnost';

  @override
  String get userNoActivityMessage => 'Korisnik nema zabilježenih aktivnosti.';

  @override
  String get activitiesEmptyFilteredMessage =>
      'Nema aktivnosti za zadane filtere.';

  @override
  String get descriptionColumnLabel => 'Opis';

  @override
  String get ipAddressColumnLabel => 'IP adresa';

  @override
  String get timeColumnLabel => 'Vrijeme';

  @override
  String waterMetersTitle(String displayName) {
    return 'Vodomjeri - $displayName';
  }

  @override
  String get userNoProfileMessage =>
      'Korisnik nema kreiran profil pa ni vodomjere.';

  @override
  String get userNoWaterMetersMessage =>
      'Korisnik trenutno nema evidentiranih vodomjera.';

  @override
  String get installedLabel => 'Instaliran';

  @override
  String get lastReadingLabel => 'Zadnje očitanje';

  @override
  String get locationCityLabel => 'Grad';

  @override
  String get locationNoCityOption => 'Bez grada';

  @override
  String get locationMunicipalityLabel => 'Općina';

  @override
  String get locationNoMunicipalityOption => 'Bez općine';

  @override
  String get locationSettlementLabel => 'Naselje';

  @override
  String get locationNoSettlementOption => 'Bez naselja';

  @override
  String get locationStreetLabel => 'Ulica';

  @override
  String get locationHouseNumberLabel => 'Broj';

  @override
  String get codebookSubtitle =>
      'Administrativni šifarnik lokacija: gradovi, općine i naselja.';

  @override
  String get backTooltip => 'Nazad';

  @override
  String get citiesLabel => 'Gradovi';

  @override
  String get openTooltip => 'Otvori';

  @override
  String get citiesScreenSubtitle =>
      'Pregled, dodavanje, uređivanje i brisanje gradova.';

  @override
  String get newCityButtonLabel => 'Novi grad';

  @override
  String get cityCreatedSuccess => 'Grad je dodan.';

  @override
  String get citySavedSuccess => 'Grad je sačuvan.';

  @override
  String get deleteCityDialogTitle => 'Obriši grad';

  @override
  String deleteCityDialogContent(String name) {
    return 'Da li želite obrisati grad \"$name\"? Ova radnja se ne može poništiti.';
  }

  @override
  String get cityDeletedSuccess => 'Grad je obrisan.';

  @override
  String get citySearchHint => 'Naziv grada';

  @override
  String get citiesEmptyMessage => 'Nema gradova.';

  @override
  String get citiesEmptyFilteredMessage => 'Nema gradova za zadanu pretragu.';

  @override
  String get nameColumnLabel => 'Naziv';

  @override
  String get codeColumnLabel => 'Kod';

  @override
  String get editCityDialogTitle => 'Uredi grad';

  @override
  String municipalitiesTitle(String cityName) {
    return 'Općine · $cityName';
  }

  @override
  String get municipalitiesScreenSubtitle =>
      'Pregled, dodavanje, uređivanje i brisanje općina.';

  @override
  String get newMunicipalityButtonLabel => 'Nova općina';

  @override
  String get municipalityCreatedSuccess => 'Općina je dodana.';

  @override
  String get municipalitySavedSuccess => 'Općina je sačuvana.';

  @override
  String get deleteMunicipalityDialogTitle => 'Obriši općinu';

  @override
  String deleteMunicipalityDialogContent(String name) {
    return 'Da li želite obrisati općinu \"$name\"? Ova radnja se ne može poništiti.';
  }

  @override
  String get municipalityDeletedSuccess => 'Općina je obrisana.';

  @override
  String get municipalitySearchHint => 'Naziv općine';

  @override
  String cityHasNoMunicipalitiesMessage(String cityName) {
    return 'Grad \'$cityName\' još nema općina.';
  }

  @override
  String get municipalitiesEmptyFilteredMessage =>
      'Nema općina za zadanu pretragu.';

  @override
  String get editMunicipalityDialogTitle => 'Uredi općinu';

  @override
  String settlementsTitle(String municipalityName) {
    return 'Naselja · $municipalityName';
  }

  @override
  String get settlementsScreenSubtitle =>
      'Pregled, dodavanje, uređivanje i brisanje naselja.';

  @override
  String get newSettlementButtonLabel => 'Novo naselje';

  @override
  String get settlementCreatedSuccess => 'Naselje je dodano.';

  @override
  String get settlementSavedSuccess => 'Naselje je sačuvano.';

  @override
  String get deleteSettlementDialogTitle => 'Obriši naselje';

  @override
  String deleteSettlementDialogContent(String name) {
    return 'Da li želite obrisati naselje \"$name\"? Ova radnja se ne može poništiti.';
  }

  @override
  String get settlementDeletedSuccess => 'Naselje je obrisano.';

  @override
  String get settlementSearchHint => 'Naziv naselja';

  @override
  String municipalityHasNoSettlementsMessage(String municipalityName) {
    return 'Općina \'$municipalityName\' još nema naselja.';
  }

  @override
  String get settlementsEmptyFilteredMessage =>
      'Nema naselja za zadanu pretragu.';

  @override
  String get postalCodeColumnLabel => 'Poštanski broj';

  @override
  String get editSettlementDialogTitle => 'Uredi naselje';

  @override
  String get noCollectorsAvailableError => 'Nema dostupnih inkasanata.';

  @override
  String get waterMeterRequestsPageTitle => 'Zahtjevi za vodomjer';

  @override
  String get waterMeterRequestsPageSubtitle =>
      'Pregled, dodjela collectoru i odbijanje zahtjeva za novi vodomjer.';

  @override
  String get allStatusesOption => 'Svi statusi';

  @override
  String get requestStatusPending => 'Na čekanju';

  @override
  String get requestStatusAwaitingRegistration => 'Čeka registraciju';

  @override
  String get requestStatusRegistered => 'Registrovan';

  @override
  String get requestStatusRejected => 'Odbijen';

  @override
  String get requestStatusCancelled => 'Otkazan';

  @override
  String get applyFilterTooltip => 'Primijeni filter';

  @override
  String get noWaterMeterRequestsMessage => 'Nema zahtjeva za novi vodomjer.';

  @override
  String get waterMeterRequestsEmptyFilteredMessage =>
      'Nema zahtjeva za odabrani status.';

  @override
  String get customerColumnLabel => 'Korisnik';

  @override
  String get collectorColumnLabel => 'Collector';

  @override
  String collectorFallbackLabel(int id) {
    return 'Collector #$id';
  }

  @override
  String get unknownSettlementLabel => 'Naselje nepoznato';

  @override
  String get noStreetAddressLabel => 'Bez ulice i broja';

  @override
  String requestCustomerFallbackLabel(int id) {
    return 'Korisnik #$id';
  }

  @override
  String get noPhoneLabel => 'Bez telefona';

  @override
  String get assignToCollectorTooltip => 'Dodijeli inkasantu';

  @override
  String get rejectTooltip => 'Odbij';

  @override
  String get selectionColumnLabel => 'Izbor';

  @override
  String get assignButtonLabel => 'Dodijeli';

  @override
  String collectorProfileFallbackLabel(int id) {
    return 'Profil #$id';
  }

  @override
  String get rejectRequestDialogTitle => 'Odbij zahtjev';

  @override
  String get reasonOptionalLabel => 'Razlog (opciono)';

  @override
  String get requestAssignedSuccess => 'Zahtjev je dodijeljen inkasantu.';

  @override
  String get requestRejectedSuccess => 'Zahtjev je odbijen.';

  @override
  String get faultReportStatusNew => 'Nova';

  @override
  String get faultReportStatusAssigned => 'Dodijeljena';

  @override
  String get faultReportStatusInProgress => 'U toku';

  @override
  String get faultReportStatusResolved => 'Riješena';

  @override
  String get changeStatusDialogTitle => 'Promijeni status';

  @override
  String changeStatusDialogContent(String title, String status) {
    return 'Da li želite promijeniti status prijave \"$title\" u \"$status\"?';
  }

  @override
  String get changeButtonLabel => 'Promijeni';

  @override
  String get statusChangedSuccess => 'Status prijave je promijenjen.';

  @override
  String get faultReportAssignedSuccess => 'Prijava je dodijeljena inkasantu.';

  @override
  String get faultReportsPageSubtitle =>
      'Pregled prijava kvarova i upravljanje statusom.';

  @override
  String get faultReportSearchLabel => 'Naslov, kupac ili naselje';

  @override
  String get noFaultReportsMessage => 'Nema prijava kvarova.';

  @override
  String get faultReportsEmptyFilteredMessage =>
      'Nema prijava kvarova za zadane filtere.';

  @override
  String get titleColumnLabel => 'Naslov';

  @override
  String get customerLabel => 'Kupac';

  @override
  String get collectorNameColumnLabel => 'Inkasant';

  @override
  String get dateColumnLabel => 'Datum';

  @override
  String collectorNumberFallbackLabel(int id) {
    return 'Inkasant #$id';
  }

  @override
  String get reassignTooltip => 'Preraspodijeli drugom inkasantu';

  @override
  String get assignmentNoLongerPossibleTooltip => 'Dodjela više nije moguća';

  @override
  String get reportResolvedTooltip => 'Prijava je riješena';

  @override
  String changeStatusToTooltip(String status) {
    return 'Promijeni status u \"$status\"';
  }

  @override
  String get noteOptionalFieldLabel => 'Napomena (opcionalno)';

  @override
  String get assignmentNoteHint => 'Razlog dodjele ili uputa inkasantu';

  @override
  String get reportedAtLabel => 'Prijavljeno';

  @override
  String get resolvedAtLabel => 'Riješeno';

  @override
  String get photosSectionHeading => 'Fotografije';

  @override
  String get noPhotosMessage => 'Nema priloženih fotografija.';

  @override
  String meterReadingsTitle(String serialNumber) {
    return 'Očitanja - $serialNumber';
  }

  @override
  String get noReadingsForMeterMessage =>
      'Za ovaj vodomjer još nema evidentiranih očitanja.';

  @override
  String get readingDateColumnLabel => 'Datum očitanja';

  @override
  String get previousReadingColumnLabel => 'Prethodno (m³)';

  @override
  String get newReadingColumnLabel => 'Novo (m³)';

  @override
  String get consumptionColumnLabel => 'Potrošnja (m³)';

  @override
  String get syncColumnLabel => 'Sinhronizacija';

  @override
  String get syncStatusSynced => 'Sinhronizovano';

  @override
  String get syncStatusFailed => 'Neuspješno';

  @override
  String get tariffCreatedSuccess => 'Tarifa je dodana.';

  @override
  String get tariffSavedSuccess => 'Tarifa je sačuvana.';

  @override
  String get tariffDeletedSuccess => 'Tarifa je obrisana.';

  @override
  String get deleteTariffDialogTitle => 'Obriši tarifu';

  @override
  String deleteTariffDialogContent(String name) {
    return 'Da li želite obrisati tarifu \"$name\"? Brisanje neće biti moguće ako je tarifa referencirana stavkama računa.';
  }

  @override
  String get tariffsScreenSubtitle =>
      'Pregled, dodavanje, uređivanje i brisanje tarifa.';

  @override
  String get newTariffButtonLabel => 'Nova tarifa';

  @override
  String get allOptionFeminine => 'Sve';

  @override
  String get activeFilterOption => 'Aktivne';

  @override
  String get inactiveFilterOption => 'Neaktivne';

  @override
  String get noTariffsMessage => 'Nema tarifa.';

  @override
  String get tariffsEmptyFilteredMessage => 'Nema tarifa za zadane filtere.';

  @override
  String get pricePerM3Label => 'Cijena po m³';

  @override
  String get tariffStatusInactive => 'Neaktivna';

  @override
  String get tariffStatusActive => 'Aktivna';

  @override
  String get editTariffDialogTitle => 'Uredi tarifu';

  @override
  String get invalidNumberError => 'Unesite ispravan broj.';

  @override
  String get negativeValueError => 'Vrijednost ne smije biti negativna.';

  @override
  String get invoiceStatusIssued => 'Izdat';

  @override
  String get invoiceStatusPaid => 'Plaćen';

  @override
  String get invoiceStatusCancelled => 'Storniran';

  @override
  String get markAsPaidLabel => 'Označi kao plaćeno';

  @override
  String markAsPaidDialogContent(String invoiceNumber, String amount) {
    return 'Da li želite označiti račun \"$invoiceNumber\" kao plaćen ($amount)?';
  }

  @override
  String get invoiceMarkedPaidSuccess => 'Račun je označen kao plaćen.';

  @override
  String get cancelInvoiceDialogTitle => 'Storniraj račun';

  @override
  String cancelInvoiceDialogContent(String invoiceNumber) {
    return 'Da li želite stornirati račun \"$invoiceNumber\"?';
  }

  @override
  String get cancelInvoiceButtonLabel => 'Storniraj';

  @override
  String get invoiceCancelledSuccess => 'Račun je storniran.';

  @override
  String get invoicesScreenSubtitle =>
      'Pregled računa i upravljanje njihovim statusom.';

  @override
  String get invoiceNumberFieldLabel => 'Broj računa';

  @override
  String get monthFilterLabel => 'Mjesec';

  @override
  String get noInvoicesMessage => 'Nema računa.';

  @override
  String get invoicesEmptyFilteredMessage => 'Nema računa za zadane filtere.';

  @override
  String get waterMeterColumnLabel => 'Vodomjer';

  @override
  String get periodColumnLabel => 'Period';

  @override
  String get consumptionM3ColumnLabel => 'Potrošnja m³';

  @override
  String get amountColumnLabel => 'Iznos';

  @override
  String get paymentStatusCompleted => 'Završena';

  @override
  String get paymentsScreenSubtitle =>
      'Pregled evidentiranih uplata. Uplate se evidentiraju isključivo putem akcije \"Evidentiraj uplatu\" na ekranu Računi.';

  @override
  String get invoiceIdFieldLabel => 'ID računa';

  @override
  String get noPaymentsMessage => 'Nema uplata.';

  @override
  String get paymentsEmptyFilteredMessage => 'Nema uplata za zadane filtere.';

  @override
  String get paymentDateColumnLabel => 'Datum uplate';

  @override
  String get invoiceColumnLabel => 'Račun';

  @override
  String get methodColumnLabel => 'Način';

  @override
  String get manualPaymentMethodLabel => 'Ručno';

  @override
  String get cannotDetermineAdminUserError =>
      'Nije moguće odrediti admin korisnika.';

  @override
  String get notificationCreatedSuccess => 'Obavijest je dodana.';

  @override
  String get cannotDetermineNotificationAuthorError =>
      'Nije moguće odrediti autora obavijesti.';

  @override
  String get notificationSavedSuccess => 'Obavijest je sačuvana.';

  @override
  String get deleteNotificationDialogTitle => 'Obriši obavijest';

  @override
  String deleteNotificationDialogContent(String title) {
    return 'Da li želite obrisati obavijest \"$title\"? Povezani zapisi korisničkih obavijesti će također biti uklonjeni.';
  }

  @override
  String get notificationDeletedSuccess => 'Obavijest je obrisana.';

  @override
  String get notificationsScreenSubtitle =>
      'Pregled, dodavanje, uređivanje i brisanje sistemskih obavijesti.';

  @override
  String get newNotificationButtonLabel => 'Nova obavijest';

  @override
  String get notificationSearchHint => 'Naslov, sadržaj, tip ili publika';

  @override
  String get typeFieldLabel => 'Tip';

  @override
  String get notificationsAllTypesOption => 'Svi tipovi';

  @override
  String get audienceFieldLabel => 'Publika';

  @override
  String get allAudiencesOption => 'Sve publike';

  @override
  String get notificationsEmptyMessage => 'Nema obavijesti.';

  @override
  String get notificationsFilteredEmptyMessage =>
      'Nema obavijesti za zadane filtere.';

  @override
  String get notificationColumnLabel => 'Obavijest';

  @override
  String get createdAtColumnLabel => 'Kreirano';

  @override
  String notificationFallbackTitle(int id) {
    return 'Obavijest #$id';
  }

  @override
  String get editNotificationDialogTitle => 'Uredi obavijest';

  @override
  String get contentFieldLabel => 'Sadržaj';

  @override
  String imagesCountLabel(int count, int max) {
    return 'Slike ($count/$max)';
  }

  @override
  String get addImageButtonLabel => 'Dodaj sliku';

  @override
  String uploadingImageLabel(int current, int total) {
    return 'Slanje slike $current/$total...';
  }

  @override
  String get notificationTypeInfoLabel => 'Info';

  @override
  String get notificationTypePlannedWorksLabel => 'Planirani radovi';

  @override
  String get notificationTypeWarningLabel => 'Upozorenje';

  @override
  String get notificationTypeGenericLabel => 'Obavijest';

  @override
  String get allUsersAudienceLabel => 'Svi korisnici';

  @override
  String get customersAudienceLabel => 'Korisnici';

  @override
  String get settlementAudienceLabel => 'Naselje';

  @override
  String get supportTicketFilterOpen => 'Otvoreni';

  @override
  String get supportTicketFilterClosed => 'Zatvoreni';

  @override
  String get ticketSubjectSearchHint => 'Predmet tiketa';

  @override
  String get supportTicketsScreenSubtitle =>
      'Svi korisnički tiketi podrške. Tiketi označeni narandžastom čekaju odgovor - zadnja poruka u niti nije od podrške.';

  @override
  String get subjectColumnLabel => 'Predmet';

  @override
  String get messagesColumnLabel => 'Poruke';

  @override
  String get lastMessageColumnLabel => 'Zadnja poruka';

  @override
  String ticketFallbackTitle(int id) {
    return 'Tiket #$id';
  }

  @override
  String get noTicketsFilteredMessage => 'Nema tiketa za zadane filtere.';

  @override
  String get noTicketsMessage => 'Nema tiketa.';

  @override
  String get enterMessageTextError => 'Unesite tekst poruke.';

  @override
  String get ticketClosedSuccess => 'Tiket je zatvoren.';

  @override
  String get ticketReopenedSuccess => 'Tiket je ponovo otvoren.';

  @override
  String get ticketFallbackLabel => 'Tiket';

  @override
  String get reopenTicketButtonLabel => 'Ponovo otvori';

  @override
  String get noMessagesMessage => 'Nema poruka.';

  @override
  String get sendButtonLabel => 'Pošalji';

  @override
  String get writeReplyHint => 'Napišite odgovor...';

  @override
  String openedAtLabel(String date) {
    return 'Otvoren: $date';
  }

  @override
  String get genericCustomerLabel => 'Korisnik';

  @override
  String get ticketClosedBannerMessage =>
      'Tiket je zatvoren. Ponovo ga otvorite da odgovorite.';

  @override
  String get supportTicketStatusOpen => 'Otvoren';

  @override
  String get supportTicketStatusClosed => 'Zatvoren';

  @override
  String get messageColumnLabel => 'Poruka';

  @override
  String get consumptionAlertsNavLabel => 'Upozorenja o potrošnji';

  @override
  String get consumptionAlertsScreenSubtitle =>
      'Pregled upozorenja o neuobičajenoj potrošnji vode i njihovo rješavanje.';

  @override
  String get checkAnomaliesButtonLabel => 'Provjeri anomalije';

  @override
  String get consumptionAlertsRecomputedSuccess =>
      'Anomalije potrošnje su provjerene.';

  @override
  String get consumptionAlertsEmptyMessage => 'Nema upozorenja o potrošnji.';

  @override
  String get markAsResolvedTooltip => 'Označi kao riješeno';

  @override
  String get alertMarkedResolvedSuccess =>
      'Upozorenje je označeno kao riješeno.';

  @override
  String get measuredValueColumnLabel => 'Izmjerena vrijednost';

  @override
  String get thresholdValueColumnLabel => 'Granična vrijednost';

  @override
  String get resolvedStatusLabel => 'Riješeno';

  @override
  String get unresolvedStatusLabel => 'Neriješeno';
}
