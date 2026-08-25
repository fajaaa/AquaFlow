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
  String get unknownRoleTitle => 'Nepoznata uloga';

  @override
  String get unknownRoleMessage =>
      'Vaš nalog nema podržanu ulogu za ovu aplikaciju. Obratite se administratoru.';

  @override
  String get commonSend => 'Pošalji';

  @override
  String get commonAddPhoto => 'Dodaj sliku';

  @override
  String get commonTakePhoto => 'Slikaj';

  @override
  String get commonChooseFromGallery => 'Iz galerije';

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

  @override
  String get commonSaving => 'Spašavanje...';

  @override
  String get welcomeTagline => 'Svaka kap, evidentirana.';

  @override
  String get welcomeSubtitle =>
      'Mali koraci u štednji vode prave velike valove promjena.';

  @override
  String get authLoginButton => 'Prijavi se';

  @override
  String get authRegisterButton => 'Registruj se';

  @override
  String get loginTitle => 'Prijava';

  @override
  String get loginWelcomeBack => 'Dobrodošli nazad';

  @override
  String get loginRememberMe => 'Zapamti me';

  @override
  String get loginFailedError => 'Prijava nije uspjela.';

  @override
  String get registerTitle => 'Registracija';

  @override
  String get firstNameRequiredError => 'Ime je obavezno.';

  @override
  String get lastNameRequiredError => 'Prezime je obavezno.';

  @override
  String get phoneInvalidError =>
      'Telefon smije sadržavati samo brojeve i simbole + - ( ).';

  @override
  String get fieldConfirmPasswordLabel => 'Potvrdi lozinku';

  @override
  String get registerThemeLabel => 'Tema';

  @override
  String get registrationFailedError => 'Registracija nije uspjela.';

  @override
  String get fieldEmailLabel => 'Email';

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
  String get fieldPhoneLabel => 'Telefon';

  @override
  String get fieldFirstNameLabel => 'Ime';

  @override
  String get fieldLastNameLabel => 'Prezime';

  @override
  String get fieldPasswordLabel => 'Lozinka';

  @override
  String get emailRequiredError => 'Email je obavezan.';

  @override
  String get emailInvalidError => 'Unesite ispravan email.';

  @override
  String get passwordRequiredError => 'Lozinka je obavezna.';

  @override
  String get passwordTooShortError => 'Lozinka mora imati najmanje 6 znakova.';

  @override
  String get passwordMismatchError => 'Lozinke se ne podudaraju.';

  @override
  String get fieldRequiredError => 'Obavezno polje.';

  @override
  String get themeLightOption => 'Svijetla';

  @override
  String get themeDarkOption => 'Tamna';

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
  String get personalDetailsTitle => 'Lični podaci';

  @override
  String themeSaveFailedError(String message) {
    return 'Tema nije sačuvana: $message';
  }

  @override
  String languageSaveFailedError(String message) {
    return 'Jezik nije sačuvan: $message';
  }

  @override
  String get personalDetailsSaveSuccess => 'Lični podaci su sačuvani.';

  @override
  String get personalDetailsNameSectionTitle => 'Ime i prezime';

  @override
  String get personalDetailsAppearanceSectionTitle => 'Izgled';

  @override
  String get nameRequiredTogetherError => 'Obavezno ako unosite ime i prezime.';

  @override
  String get accountDataSectionTitle => 'Podaci o nalogu';

  @override
  String get accountPersonalDetailsSubtitle =>
      'Ime, prezime, email, telefon i tema';

  @override
  String get locationTitle => 'Lokacija';

  @override
  String get accountLocationSubtitle => 'Adresa prebivališta';

  @override
  String get accountPasswordSubtitle => 'Ažuriranje lozinke naloga';

  @override
  String get accountActivityLogTitle => 'Moje aktivnosti';

  @override
  String get accountActivityLogSubtitle => 'Historija prijava i izmjena naloga';

  @override
  String get accountCompanySettingsTitle => 'Postavke firme';

  @override
  String get accountCompanySettingsSubtitle => 'Upravljanje podacima firme';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCollector => 'Inkasant';

  @override
  String get roleCustomer => 'Korisnik';

  @override
  String get locationNameRequiredError =>
      'Unesite ime i prezime u \"Lični podaci\" da biste sačuvali adresu.';

  @override
  String get locationSaveSuccess => 'Lokacija je sačuvana.';

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
  String get mobileShellThemeTooltip => 'Promijeni temu';

  @override
  String get mobileShellLogoutTooltip => 'Odjava';

  @override
  String get tabNotifications => 'Obavijesti';

  @override
  String get tabWaterMeters => 'Vodomjeri';

  @override
  String get tabFaultReports => 'Prijave kvarova';

  @override
  String get tabAccount => 'Nalog';

  @override
  String get supportTitle => 'Podrška';

  @override
  String get supportSubtitle => 'Vaši tiketi i poruke podršci';

  @override
  String get notLoggedInError => 'Niste prijavljeni.';

  @override
  String get notificationsMarkAllReadTooltip => 'Označi sve kao pročitano';

  @override
  String get notificationTypeFieldLabel => 'Tip obavijesti';

  @override
  String get notificationsAllTypesOption => 'Svi tipovi';

  @override
  String get notificationTypeInfoLabel => 'Info';

  @override
  String get notificationTypePlannedWorksLabel => 'Planirani radovi';

  @override
  String get notificationTypeWarningLabel => 'Upozorenje';

  @override
  String get notificationTypeGenericLabel => 'Obavijest';

  @override
  String notificationFallbackTitle(int id) {
    return 'Obavijest #$id';
  }

  @override
  String get notificationsEmptyMessage => 'Nema obavijesti.';

  @override
  String get notificationsEmptyFilteredMessage =>
      'Nema obavijesti za odabrani tip.';

  @override
  String get notificationDetailTitle => 'Detalji obavijesti';

  @override
  String get notificationDetailDescriptionHeading => 'Opis';

  @override
  String get notificationDetailEmptyBody => 'Nema dodatnog sadržaja.';

  @override
  String get notificationDetailDetailsHeading => 'Detalji';

  @override
  String get notificationDetailCreatedAtLabel => 'Datum kreiranja';

  @override
  String notificationDetailImagesHeading(int count) {
    return 'Slike ($count)';
  }

  @override
  String get notificationStatusRead => 'Pročitano';

  @override
  String get notificationStatusUnread => 'Novo';

  @override
  String get activityLogEmptyMessage => 'Nema zabilježenih aktivnosti.';

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
  String get dialogDismissButton => 'Odustani';

  @override
  String get addWaterMeterTooltip => 'Dodaj vodomjer';

  @override
  String get waterMetersEmptyMessage =>
      'Trenutno nemate evidentiranih vodomjera.';

  @override
  String lastReadingLabel(String value) {
    return 'Zadnje očitanje: $value m³';
  }

  @override
  String get newWaterMeterRequestSuccess =>
      'Zahtjev za novi vodomjer je poslan.';

  @override
  String get requestsTitle => 'Zahtjevi';

  @override
  String get newRequestTooltip => 'Novi zahtjev';

  @override
  String get cancelRequestConfirmTitle => 'Otkazati zahtjev?';

  @override
  String cancelRequestConfirmMessage(int id) {
    return 'Zahtjev za novi vodomjer #$id će biti otkazan.';
  }

  @override
  String get cancelRequestButton => 'Otkaži zahtjev';

  @override
  String get cancelRequestSuccess => 'Zahtjev je otkazan.';

  @override
  String requestCardTitle(int id) {
    return 'Zahtjev #$id';
  }

  @override
  String get requestsEmptyMessage => 'Nemate poslanih zahtjeva za vodomjer.';

  @override
  String get newWaterMeterRequestTitle => 'Zahtjev za novi vodomjer';

  @override
  String get newWaterMeterRequestSubmitButton => 'Pošalji zahtjev';

  @override
  String get newWaterMeterRequestNoteLabel => 'Napomena (opciono)';

  @override
  String get settlementRequiredError => 'Odaberite naselje.';

  @override
  String get showInvoicesButton => 'Prikaži račune';

  @override
  String get meterInfoSectionHeading => 'Podaci o vodomjeru';

  @override
  String get addressLabel => 'Adresa';

  @override
  String get installedAtLabel => 'Datum ugradnje';

  @override
  String get initialReadingLabel => 'Početno očitanje';

  @override
  String get lastReadingFieldLabel => 'Zadnje očitanje';

  @override
  String get lastReadingM3Label => 'Zadnje očitanje (m³)';

  @override
  String get statisticsSectionHeading => 'Statistika';

  @override
  String get averageConsumptionLabel =>
      'Prosječna potrošnja po obračunskom periodu (m³)';

  @override
  String get totalConsumptionLabel => 'Ukupno potrošeno (m³)';

  @override
  String totalConsumptionValue(String m3, int invoiceCount) {
    return '$m3 m³ ($invoiceCount računa)';
  }

  @override
  String get unpaidLabel => 'Neplaćeno';

  @override
  String unpaidValue(int count, String amount) {
    return '$count računa / $amount KM';
  }

  @override
  String get lastBillingPeriodLabel => 'Zadnji obračunski period';

  @override
  String get consumptionByPeriodHeading => 'Potrošnja po periodima';

  @override
  String get noConsumptionDataMessage => 'Nema podataka o potrošnji.';

  @override
  String get waterMeterStatusActive => 'Aktivan';

  @override
  String get waterMeterStatusInactive => 'Neaktivan';

  @override
  String get waterMeterStatusRemoved => 'Uklonjen';

  @override
  String get requestStatusPending => 'Na čekanju';

  @override
  String get requestStatusAssigned => 'Dodijeljen';

  @override
  String get requestStatusRegistered => 'Registrovan';

  @override
  String get requestStatusRejected => 'Odbijen';

  @override
  String get requestStatusCancelled => 'Otkazan';

  @override
  String get invoicesTitle => 'Računi';

  @override
  String invoicesTitleForMeter(String serial) {
    return 'Računi - $serial';
  }

  @override
  String get invoicesEmptyMessage => 'Nemate izdatih računa.';

  @override
  String get invoicesEmptyForMeterMessage =>
      'Za ovaj vodomjer još nema izdatih računa.';

  @override
  String invoiceRemainingAmountLabel(String amount) {
    return 'Preostalo: $amount KM';
  }

  @override
  String get invoiceStatusIssued => 'Izdat';

  @override
  String get invoiceStatusPaid => 'Plaćen';

  @override
  String get invoiceStatusCancelled => 'Storniran';

  @override
  String get allInvoicesTooltip => 'Svi računi';

  @override
  String get invoiceStatusFieldLabel => 'Status računa';

  @override
  String get payButton => 'Plati';

  @override
  String get paymentConfirmTitle => 'Potvrda plaćanja';

  @override
  String paymentConfirmMessage(String amount) {
    return 'Da li ste sigurni da želite platiti $amount BAM?';
  }

  @override
  String paymentStartedMessage(
    String amount,
    String currency,
    String statusLabel,
  ) {
    return 'Plaćanje pokrenuto: $amount $currency (status: $statusLabel).';
  }

  @override
  String get paymentProcessingMessage => 'Plaćanje u obradi.';

  @override
  String get paymentCancelledMessage => 'Plaćanje je otkazano.';

  @override
  String get paymentFailedMessage => 'Plaćanje nije uspjelo.';

  @override
  String get paymentStatusCompleted => 'Završeno';

  @override
  String get paymentStatusFailed => 'Neuspješno';

  @override
  String get readingsSectionHeading => 'Očitanja';

  @override
  String get periodLabel => 'Period';

  @override
  String get previousReadingLabel => 'Prethodno očitanje';

  @override
  String get currentReadingLabel => 'Novo očitanje';

  @override
  String get consumptionLabel => 'Potrošnja';

  @override
  String get amountSectionHeading => 'Iznos';

  @override
  String get subtotalLabel => 'Osnovica';

  @override
  String get totalLabel => 'Ukupno';

  @override
  String get paymentsSectionHeading => 'Uplate';

  @override
  String get paymentsEmptyMessage => 'Nema evidentiranih uplata.';

  @override
  String get totalPaidLabel => 'Plaćeno ukupno';

  @override
  String get remainingToPayLabel => 'Preostalo za platiti';

  @override
  String get downloadInvoicePdfButton => 'Preuzmi PDF';

  @override
  String get invoicePdfDownloadFailedMessage =>
      'Preuzimanje racuna nije uspjelo. Pokusajte ponovo.';

  @override
  String get faultReportSubmitSuccess => 'Prijava kvara je poslana.';

  @override
  String get newFaultReportTooltip => 'Nova prijava';

  @override
  String get newFaultReportDialogTitle => 'Nova prijava kvara';

  @override
  String get titleFieldLabel => 'Naslov';

  @override
  String get descriptionFieldLabel => 'Opis';

  @override
  String get waterMeterOptionalLabel => 'Vodomjer (opciono)';

  @override
  String get noWaterMeterOption => 'Bez vodomjera';

  @override
  String get streetOptionalLabel => 'Ulica (opciono)';

  @override
  String get houseNumberOptionalLabel => 'Broj (opciono)';

  @override
  String photoCountLabel(int current, int max) {
    return 'Fotografije ($current/$max)';
  }

  @override
  String get addImageButtonLabel => 'Dodaj sliku';

  @override
  String sendingPhotoLabel(int current, int total) {
    return 'Slanje fotografije $current/$total...';
  }

  @override
  String get newFaultReportSubmitButton => 'Pošalji prijavu';

  @override
  String get faultReportsEmptyMessage => 'Nemate poslanih prijava kvarova.';

  @override
  String get faultReportStatusNew => 'Nova';

  @override
  String get faultReportStatusAssigned => 'Dodijeljena';

  @override
  String get faultReportStatusInProgress => 'U toku';

  @override
  String get faultReportStatusResolved => 'Riješena';

  @override
  String get faultReportStatusFieldLabel => 'Status prijave';

  @override
  String get photosSectionHeading => 'Fotografije';

  @override
  String get noPhotosMessage => 'Nema priloženih fotografija.';

  @override
  String get faultReportInfoSectionHeading => 'Podaci o prijavi';

  @override
  String get reportedAtLabel => 'Prijavljeno';

  @override
  String get resolvedAtLabel => 'Riješeno';

  @override
  String get supportTicketStatusOpen => 'Otvoren';

  @override
  String get supportTicketStatusClosed => 'Zatvoren';

  @override
  String get newSupportTicketTooltip => 'Novi tiket';

  @override
  String get newSupportTicketDialogTitle => 'Novi tiket';

  @override
  String get messageFieldLabel => 'Poruka';

  @override
  String get supportTicketCreateSuccess => 'Tiket je kreiran.';

  @override
  String get supportTicketsEmptyTitle => 'Nemate otvorenih tiketa.';

  @override
  String get supportTicketsEmptySubtitle =>
      'Otvorite novi tiket da kontaktirate podršku.';

  @override
  String supportTicketLastMessageLabel(String date) {
    return 'Zadnja poruka: $date';
  }

  @override
  String get supportTicketReplyHint => 'Napišite poruku...';

  @override
  String get supportTicketReplyRequiredError => 'Unesite tekst poruke.';

  @override
  String get supportTicketDefaultTitle => 'Tiket';

  @override
  String get supportTicketNoMessages => 'Nema poruka.';

  @override
  String supportTicketOpenedAtLabel(String date) {
    return 'Otvoren: $date';
  }

  @override
  String get supportTicketYouLabel => 'Vi';

  @override
  String get supportTicketClosedBanner => 'Tiket je zatvoren';
}
