// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'AquaFlow';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonRefresh => 'Aktualisieren';

  @override
  String get commonSearch => 'Suchen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonLogout => 'Abmelden';

  @override
  String get unknownRoleTitle => 'Unbekannte Rolle';

  @override
  String get unknownRoleMessage =>
      'Ihr Konto hat keine für diese App unterstützte Rolle. Wenden Sie sich an Ihren Administrator.';

  @override
  String get commonSend => 'Senden';

  @override
  String get commonAddPhoto => 'Foto hinzufügen';

  @override
  String get commonTakePhoto => 'Foto aufnehmen';

  @override
  String get commonChooseFromGallery => 'Aus der Galerie';

  @override
  String get stateLoading => 'Wird geladen...';

  @override
  String get errorGeneric => 'Fehler';

  @override
  String get emptyGeneric => 'Keine Daten';

  @override
  String get emptyList => 'Leere Liste';

  @override
  String get paginationPrevious => 'Vorherige Seite';

  @override
  String get paginationNext => 'Nächste Seite';

  @override
  String paginationPageOf(int page, int totalPages) {
    return 'Seite $page von $totalPages';
  }

  @override
  String paginationTotalCount(int count) {
    return '$count insgesamt';
  }

  @override
  String get commonSaving => 'Wird gespeichert...';

  @override
  String get welcomeTagline => 'Jeder Tropfen erfasst.';

  @override
  String get welcomeSubtitle =>
      'Kleine Schritte beim Wassersparen bewirken große Veränderungen.';

  @override
  String get authLoginButton => 'Anmelden';

  @override
  String get authRegisterButton => 'Registrieren';

  @override
  String get loginTitle => 'Anmeldung';

  @override
  String get loginWelcomeBack => 'Willkommen zurück';

  @override
  String get loginRememberMe => 'Angemeldet bleiben';

  @override
  String get loginFailedError => 'Anmeldung fehlgeschlagen.';

  @override
  String get registerTitle => 'Registrierung';

  @override
  String get firstNameRequiredError => 'Vorname ist erforderlich.';

  @override
  String get lastNameRequiredError => 'Nachname ist erforderlich.';

  @override
  String get phoneInvalidError =>
      'Das Telefon darf nur Ziffern und die Zeichen + - ( ) enthalten.';

  @override
  String get fieldConfirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get registerThemeLabel => 'Design';

  @override
  String get registrationFailedError => 'Registrierung fehlgeschlagen.';

  @override
  String get fieldEmailLabel => 'E-Mail';

  @override
  String get companySettingsScreenTitle => 'Unternehmenseinstellungen';

  @override
  String get companyNameLabel => 'Firmenname';

  @override
  String get taxNumberLabel => 'Steuernummer';

  @override
  String get bankAccountLabel => 'Bankkonto';

  @override
  String get logoUrlOptionalLabel => 'Logo-URL (optional)';

  @override
  String get defaultLanguageLabel => 'Sprache';

  @override
  String get defaultCurrencyLabel => 'Währung';

  @override
  String get companySettingsSaveSuccess =>
      'Unternehmenseinstellungen gespeichert.';

  @override
  String get fieldPhoneLabel => 'Telefon';

  @override
  String get fieldFirstNameLabel => 'Vorname';

  @override
  String get fieldLastNameLabel => 'Nachname';

  @override
  String get fieldPasswordLabel => 'Passwort';

  @override
  String get emailRequiredError => 'E-Mail ist erforderlich.';

  @override
  String get emailInvalidError => 'Geben Sie eine gültige E-Mail-Adresse ein.';

  @override
  String get passwordRequiredError => 'Passwort ist erforderlich.';

  @override
  String get passwordTooShortError =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get passwordMismatchError => 'Die Passwörter stimmen nicht überein.';

  @override
  String get fieldRequiredError => 'Pflichtfeld.';

  @override
  String get themeLightOption => 'Hell';

  @override
  String get themeDarkOption => 'Dunkel';

  @override
  String get passwordResetTitle => 'Passwort ändern';

  @override
  String get passwordResetDescription =>
      'Geben Sie Ihr aktuelles und Ihr neues Passwort ein, um es zu ändern.';

  @override
  String get passwordResetCurrentLabel => 'Aktuelles Passwort';

  @override
  String get passwordResetNewLabel => 'Neues Passwort';

  @override
  String get passwordResetConfirmLabel => 'Neues Passwort bestätigen';

  @override
  String get passwordResetSubmitButton => 'Passwort ändern';

  @override
  String get passwordResetSuccess => 'Passwort geändert.';

  @override
  String get passwordResetCurrentRequiredError =>
      'Geben Sie Ihr aktuelles Passwort ein.';

  @override
  String get passwordResetNewRequiredError =>
      'Geben Sie Ihr neues Passwort ein.';

  @override
  String get personalDetailsTitle => 'Persönliche Daten';

  @override
  String themeSaveFailedError(String message) {
    return 'Design nicht gespeichert: $message';
  }

  @override
  String languageSaveFailedError(String message) {
    return 'Sprache nicht gespeichert: $message';
  }

  @override
  String get personalDetailsSaveSuccess => 'Persönliche Daten gespeichert.';

  @override
  String get personalDetailsNameSectionTitle => 'Vor- und Nachname';

  @override
  String get personalDetailsAppearanceSectionTitle => 'Darstellung';

  @override
  String get nameRequiredTogetherError =>
      'Erforderlich, wenn Vor- und Nachname eingegeben werden.';

  @override
  String get accountDataSectionTitle => 'Kontodaten';

  @override
  String get accountPersonalDetailsSubtitle =>
      'Vorname, Nachname, E-Mail, Telefon und Design';

  @override
  String get locationTitle => 'Standort';

  @override
  String get accountLocationSubtitle => 'Wohnadresse';

  @override
  String get accountPasswordSubtitle => 'Kontopasswort aktualisieren';

  @override
  String get accountActivityLogTitle => 'Meine Aktivitäten';

  @override
  String get accountActivityLogSubtitle =>
      'Verlauf der Anmeldungen und Kontoänderungen';

  @override
  String get accountCompanySettingsTitle => 'Unternehmenseinstellungen';

  @override
  String get accountCompanySettingsSubtitle => 'Unternehmensdaten verwalten';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCollector => 'Ableser';

  @override
  String get roleCustomer => 'Kunde';

  @override
  String get locationNameRequiredError =>
      'Geben Sie Ihren Vor- und Nachnamen unter „Persönliche Daten“ ein, um die Adresse zu speichern.';

  @override
  String get locationSaveSuccess => 'Standort gespeichert.';

  @override
  String get locationCityLabel => 'Stadt';

  @override
  String get locationNoCityOption => 'Keine Stadt';

  @override
  String get locationMunicipalityLabel => 'Gemeinde';

  @override
  String get locationNoMunicipalityOption => 'Keine Gemeinde';

  @override
  String get locationSettlementLabel => 'Siedlung';

  @override
  String get locationNoSettlementOption => 'Keine Siedlung';

  @override
  String get locationStreetLabel => 'Straße';

  @override
  String get locationHouseNumberLabel => 'Hausnummer';

  @override
  String get mobileShellThemeTooltip => 'Design ändern';

  @override
  String get mobileShellLogoutTooltip => 'Abmelden';

  @override
  String get tabNotifications => 'Benachrichtigungen';

  @override
  String get tabWaterMeters => 'Wasserzähler';

  @override
  String get tabFaultReports => 'Störungsmeldungen';

  @override
  String get tabAccount => 'Konto';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportSubtitle => 'Ihre Support-Tickets und Nachrichten';

  @override
  String get notLoggedInError => 'Nicht angemeldet.';

  @override
  String get notificationsMarkAllReadTooltip => 'Alle als gelesen markieren';

  @override
  String get notificationTypeFieldLabel => 'Benachrichtigungstyp';

  @override
  String get notificationsAllTypesOption => 'Alle Typen';

  @override
  String get notificationTypeInfoLabel => 'Info';

  @override
  String get notificationTypePlannedWorksLabel => 'Geplante Arbeiten';

  @override
  String get notificationTypeWarningLabel => 'Warnung';

  @override
  String get notificationTypeGenericLabel => 'Benachrichtigung';

  @override
  String notificationFallbackTitle(int id) {
    return 'Benachrichtigung #$id';
  }

  @override
  String get notificationsEmptyMessage => 'Keine Benachrichtigungen.';

  @override
  String get notificationsEmptyFilteredMessage =>
      'Keine Benachrichtigungen für den gewählten Typ.';

  @override
  String get notificationDetailTitle => 'Benachrichtigungsdetails';

  @override
  String get notificationDetailDescriptionHeading => 'Beschreibung';

  @override
  String get notificationDetailEmptyBody => 'Kein weiterer Inhalt.';

  @override
  String get notificationDetailDetailsHeading => 'Details';

  @override
  String get notificationDetailCreatedAtLabel => 'Erstellungsdatum';

  @override
  String notificationDetailImagesHeading(int count) {
    return 'Bilder ($count)';
  }

  @override
  String get notificationStatusRead => 'Gelesen';

  @override
  String get notificationStatusUnread => 'Neu';

  @override
  String get activityLogEmptyMessage => 'Keine erfassten Aktivitäten.';

  @override
  String get activityTypeLoginSuccess => 'Erfolgreiche Anmeldung';

  @override
  String get activityTypeLoginFailed => 'Fehlgeschlagene Anmeldung';

  @override
  String get activityTypeTokenRefreshed => 'Sitzung erneuert';

  @override
  String get activityTypePasswordChanged => 'Passwort geändert';

  @override
  String get activityTypeAccountUpdated => 'Konto aktualisiert';

  @override
  String get activityTypeUserRoleChanged => 'Rolle geändert';

  @override
  String get activityTypeUserActivated => 'Benutzer aktiviert';

  @override
  String get activityTypeUserDeactivated => 'Benutzer deaktiviert';

  @override
  String get activityTypeUserDeleted => 'Benutzer gelöscht';

  @override
  String get activityTypeGenericLabel => 'Aktivität';

  @override
  String get dialogDismissButton => 'Abbrechen';

  @override
  String get addWaterMeterTooltip => 'Wasserzähler hinzufügen';

  @override
  String get waterMetersEmptyMessage =>
      'Sie haben derzeit keine registrierten Wasserzähler.';

  @override
  String lastReadingLabel(String value) {
    return 'Letzte Ablesung: $value m³';
  }

  @override
  String get newWaterMeterRequestSuccess =>
      'Neue Wasserzähleranfrage gesendet.';

  @override
  String get requestsTitle => 'Anfragen';

  @override
  String get newRequestTooltip => 'Neue Anfrage';

  @override
  String get cancelRequestConfirmTitle => 'Anfrage stornieren?';

  @override
  String cancelRequestConfirmMessage(int id) {
    return 'Die neue Wasserzähleranfrage #$id wird storniert.';
  }

  @override
  String get cancelRequestButton => 'Anfrage stornieren';

  @override
  String get cancelRequestSuccess => 'Anfrage storniert.';

  @override
  String requestCardTitle(int id) {
    return 'Anfrage #$id';
  }

  @override
  String get requestsEmptyMessage =>
      'Sie haben keine gesendeten Wasserzähleranfragen.';

  @override
  String get newWaterMeterRequestTitle => 'Neue Wasserzähleranfrage';

  @override
  String get newWaterMeterRequestSubmitButton => 'Anfrage senden';

  @override
  String get newWaterMeterRequestNoteLabel => 'Notiz (optional)';

  @override
  String get settlementRequiredError => 'Wählen Sie eine Siedlung aus.';

  @override
  String get showInvoicesButton => 'Rechnungen anzeigen';

  @override
  String get meterInfoSectionHeading => 'Zählerinformationen';

  @override
  String get addressLabel => 'Adresse';

  @override
  String get installedAtLabel => 'Installationsdatum';

  @override
  String get initialReadingLabel => 'Anfangsstand';

  @override
  String get lastReadingFieldLabel => 'Letzte Ablesung';

  @override
  String get lastReadingM3Label => 'Letzte Ablesung (m³)';

  @override
  String get statisticsSectionHeading => 'Statistik';

  @override
  String get averageConsumptionLabel =>
      'Durchschnittsverbrauch pro Abrechnungszeitraum (m³)';

  @override
  String get totalConsumptionLabel => 'Gesamtverbrauch (m³)';

  @override
  String totalConsumptionValue(String m3, int invoiceCount) {
    return '$m3 m³ ($invoiceCount Rechnungen)';
  }

  @override
  String get unpaidLabel => 'Unbezahlt';

  @override
  String unpaidValue(int count, String amount) {
    return '$count Rechnungen / $amount KM';
  }

  @override
  String get lastBillingPeriodLabel => 'Letzter Abrechnungszeitraum';

  @override
  String get consumptionByPeriodHeading => 'Verbrauch nach Zeitraum';

  @override
  String get noConsumptionDataMessage => 'Keine Verbrauchsdaten.';

  @override
  String get waterMeterStatusActive => 'Aktiv';

  @override
  String get waterMeterStatusInactive => 'Inaktiv';

  @override
  String get waterMeterStatusRemoved => 'Entfernt';

  @override
  String get requestStatusPending => 'Ausstehend';

  @override
  String get requestStatusAssigned => 'Zugewiesen';

  @override
  String get requestStatusRegistered => 'Registriert';

  @override
  String get requestStatusRejected => 'Abgelehnt';

  @override
  String get requestStatusCancelled => 'Storniert';

  @override
  String get invoicesTitle => 'Rechnungen';

  @override
  String invoicesTitleForMeter(String serial) {
    return 'Rechnungen – $serial';
  }

  @override
  String get invoicesEmptyMessage =>
      'Sie haben keine ausgestellten Rechnungen.';

  @override
  String get invoicesEmptyForMeterMessage =>
      'Für diesen Zähler wurden noch keine Rechnungen ausgestellt.';

  @override
  String invoiceRemainingAmountLabel(String amount) {
    return 'Offen: $amount KM';
  }

  @override
  String get invoiceStatusIssued => 'Ausgestellt';

  @override
  String get invoiceStatusPaid => 'Bezahlt';

  @override
  String get invoiceStatusCancelled => 'Storniert';

  @override
  String get allInvoicesTooltip => 'Alle Rechnungen';

  @override
  String get invoiceStatusFieldLabel => 'Rechnungsstatus';

  @override
  String get payButton => 'Bezahlen';

  @override
  String get paymentConfirmTitle => 'Zahlungsbestätigung';

  @override
  String paymentConfirmMessage(String amount) {
    return 'Möchten Sie $amount BAM wirklich bezahlen?';
  }

  @override
  String paymentStartedMessage(
    String amount,
    String currency,
    String statusLabel,
  ) {
    return 'Zahlung gestartet: $amount $currency (Status: $statusLabel).';
  }

  @override
  String get paymentProcessingMessage => 'Zahlung wird verarbeitet.';

  @override
  String get paymentAlreadySucceededMessage =>
      'Zahlung wird verarbeitet. Die Zahlung wurde bereits geleistet und wartet auf Bestätigung.';

  @override
  String get paymentCancelledMessage => 'Zahlung abgebrochen.';

  @override
  String get paymentFailedMessage => 'Zahlung fehlgeschlagen.';

  @override
  String get paymentStatusCompleted => 'Abgeschlossen';

  @override
  String get paymentStatusFailed => 'Fehlgeschlagen';

  @override
  String get readingsSectionHeading => 'Zählerablesungen';

  @override
  String get periodLabel => 'Zeitraum';

  @override
  String get previousReadingLabel => 'Vorheriger Stand';

  @override
  String get currentReadingLabel => 'Aktueller Stand';

  @override
  String get consumptionLabel => 'Verbrauch';

  @override
  String get amountSectionHeading => 'Betrag';

  @override
  String get subtotalLabel => 'Zwischensumme';

  @override
  String get totalLabel => 'Gesamt';

  @override
  String get paymentsSectionHeading => 'Zahlungen';

  @override
  String get paymentsEmptyMessage => 'Keine erfassten Zahlungen.';

  @override
  String get totalPaidLabel => 'Insgesamt bezahlt';

  @override
  String get remainingToPayLabel => 'Noch zu zahlen';

  @override
  String get downloadInvoicePdfButton => 'PDF herunterladen';

  @override
  String get invoicePdfDownloadFailedMessage =>
      'Die Rechnung konnte nicht heruntergeladen werden. Bitte versuchen Sie es erneut.';

  @override
  String get faultReportSubmitSuccess => 'Störungsmeldung gesendet.';

  @override
  String get newFaultReportTooltip => 'Neue Meldung';

  @override
  String get newFaultReportDialogTitle => 'Neue Störungsmeldung';

  @override
  String get titleFieldLabel => 'Titel';

  @override
  String get descriptionFieldLabel => 'Beschreibung';

  @override
  String get waterMeterOptionalLabel => 'Wasserzähler (optional)';

  @override
  String get noWaterMeterOption => 'Kein Wasserzähler';

  @override
  String get streetOptionalLabel => 'Straße (optional)';

  @override
  String get houseNumberOptionalLabel => 'Hausnummer (optional)';

  @override
  String photoCountLabel(int current, int max) {
    return 'Fotos ($current/$max)';
  }

  @override
  String get addImageButtonLabel => 'Bild hinzufügen';

  @override
  String sendingPhotoLabel(int current, int total) {
    return 'Foto $current/$total wird gesendet...';
  }

  @override
  String get newFaultReportSubmitButton => 'Meldung senden';

  @override
  String get faultReportsEmptyMessage =>
      'Sie haben keine gesendeten Störungsmeldungen.';

  @override
  String get faultReportStatusNew => 'Neu';

  @override
  String get faultReportStatusAssigned => 'Zugewiesen';

  @override
  String get faultReportStatusInProgress => 'In Bearbeitung';

  @override
  String get faultReportStatusResolved => 'Behoben';

  @override
  String get faultReportStatusFieldLabel => 'Meldungsstatus';

  @override
  String get photosSectionHeading => 'Fotos';

  @override
  String get noPhotosMessage => 'Keine Fotos angehängt.';

  @override
  String get faultReportInfoSectionHeading => 'Informationen zur Meldung';

  @override
  String get reportedAtLabel => 'Gemeldet';

  @override
  String get resolvedAtLabel => 'Behoben';

  @override
  String get supportTicketStatusOpen => 'Öffnen';

  @override
  String get supportTicketStatusClosed => 'Geschlossen';

  @override
  String get newSupportTicketTooltip => 'Neues Ticket';

  @override
  String get newSupportTicketDialogTitle => 'Neues Ticket';

  @override
  String get messageFieldLabel => 'Nachricht';

  @override
  String get supportTicketCreateSuccess => 'Ticket erstellt.';

  @override
  String get supportTicketsEmptyTitle => 'Sie haben keine offenen Tickets.';

  @override
  String get supportTicketsEmptySubtitle =>
      'Eröffnen Sie ein neues Ticket, um den Support zu kontaktieren.';

  @override
  String supportTicketLastMessageLabel(String date) {
    return 'Letzte Nachricht: $date';
  }

  @override
  String get supportTicketReplyHint => 'Nachricht schreiben...';

  @override
  String get supportTicketReplyRequiredError => 'Geben Sie eine Nachricht ein.';

  @override
  String get supportTicketDefaultTitle => 'Ticket';

  @override
  String get supportTicketNoMessages => 'Keine Nachrichten.';

  @override
  String supportTicketOpenedAtLabel(String date) {
    return 'Geöffnet: $date';
  }

  @override
  String get supportTicketYouLabel => 'Sie';

  @override
  String get supportTicketClosedBanner => 'Dieses Ticket ist geschlossen';

  @override
  String get sessionExpiredMessage =>
      'Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an.';

  @override
  String get passwordChangedSignInAgain =>
      'Ihr Passwort wurde geändert. Bitte melden Sie sich erneut an.';

  @override
  String get notificationsNewBanner => 'Sie haben neue Benachrichtigungen';

  @override
  String get notificationOpenAction => 'Öffnen';

  @override
  String get notificationOpenRelatedFailed =>
      'Das zugehörige Element konnte nicht geöffnet werden. Möglicherweise ist es nicht mehr verfügbar.';
}
