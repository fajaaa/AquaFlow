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
  String get defaultLanguageHelper =>
      'Sprache neuer Benutzer bei der Registrierung';

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
  String get mobileShellThemeTooltip => 'Design ändern';

  @override
  String get mobileShellLogoutTooltip => 'Abmelden';

  @override
  String get tabNotifications => 'Benachrichtigungen';

  @override
  String get tabWaterMeters => 'Wasserzähler';

  @override
  String get tabWaterMeterRequests => 'Aufträge';

  @override
  String get tabAccount => 'Konto';

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
  String get commonConfirm => 'Bestätigen';

  @override
  String get commonClear => 'Leeren';

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
  String get locationNameRequiredError =>
      'Geben Sie Ihren Vor- und Nachnamen unter „Persönliche Daten“ ein, um die Adresse zu speichern.';

  @override
  String get locationSaveSuccess => 'Standort gespeichert.';

  @override
  String get settlementRequiredError => 'Wählen Sie eine Siedlung aus.';

  @override
  String requestCardTitle(int id) {
    return 'Anfrage #$id';
  }

  @override
  String get requestStatusAssigned => 'Zugewiesen';

  @override
  String get initialReadingLabel => 'Anfangsstand';

  @override
  String get consumptionLabel => 'Verbrauch';

  @override
  String get totalLabel => 'Gesamt';

  @override
  String get waterMeterStatusActive => 'Aktiv';

  @override
  String get waterMeterStatusInactive => 'Inaktiv';

  @override
  String get waterMeterStatusRemoved => 'Entfernt';

  @override
  String get meterInfoSectionHeading => 'Zählerinformationen';

  @override
  String get lastReadingStateLabel => 'Letzte Ablesung';

  @override
  String get faultReportsTooltip => 'Störungsmeldungen';

  @override
  String get readingHistoryTooltip => 'Ablesungsverlauf';

  @override
  String get readingHistoryTitle => 'Ablesungsverlauf';

  @override
  String get readingHistoryEmptyMessage =>
      'Für diesen Zähler wurden noch keine Ablesungen erfasst.';

  @override
  String get readingHistoryVoidedPill => 'Storniert';

  @override
  String readingHistoryConsumption(String value) {
    return 'Verbrauch: $value m³';
  }

  @override
  String readingHistoryPageIndicator(int page, int total) {
    return 'Seite $page / $total';
  }

  @override
  String get collectorMeterSearchHint =>
      'Name des Eigentümers, Siedlung, Seriennummer oder Adresse';

  @override
  String collectorMetersEmptyMessage(String term) {
    return 'Keine Wasserzähler für „$term“.';
  }

  @override
  String collectorLastReadingLabel(String value) {
    return 'Letzte Ablesung: $value m³';
  }

  @override
  String get collectorMetersPromptMessage =>
      'Geben Sie den Namen des Eigentümers, die Siedlung, die Seriennummer oder die Adresse ein.';

  @override
  String get waterMeterRequestsScreenTitle => 'Aufträge';

  @override
  String get waterMeterRequestsEmptyMessage =>
      'Derzeit sind keine Anfragen zugewiesen.';

  @override
  String get meterRegisteredSuccess => 'Wasserzähler registriert.';

  @override
  String customerFallbackLabel(int id) {
    return 'Kunde #$id';
  }

  @override
  String get phoneNotAvailableLabel => 'Telefonnummer nicht verfügbar';

  @override
  String createdAtInlineLabel(String date) {
    return 'Erstellt: $date';
  }

  @override
  String get callButton => 'Anrufen';

  @override
  String get actionNotSupportedError =>
      'Diese Aktion wird auf diesem Gerät nicht unterstützt.';

  @override
  String get registerWaterMeterTitle => 'Wasserzähler registrieren';

  @override
  String get registerButton => 'Registrieren';

  @override
  String get serialNumberLabel => 'Seriennummer';

  @override
  String get installedAtFieldLabel => 'Installationsdatum';

  @override
  String get pickDateTooltip => 'Datum auswählen';

  @override
  String get positiveNumberRequiredError => 'Geben Sie eine positive Zahl ein.';

  @override
  String get markBrokenTooltip => 'Als defekt markieren';

  @override
  String nextReadingAllowedLabel(String date) {
    return 'Nächste Ablesung möglich ab: $date';
  }

  @override
  String get newReadingSectionHeading => 'Neue Ablesung';

  @override
  String get newReadingFieldLabel => 'Neuer Zählerstand (m³)';

  @override
  String get tariffLabel => 'Tarif';

  @override
  String get tariffsLoadingHint => 'Tarife werden geladen...';

  @override
  String get tariffsEmptyHint => 'Keine aktiven Tarife';

  @override
  String get tariffSelectHint => 'Tarif auswählen';

  @override
  String get noteOptionalLabel => 'Notiz (optional)';

  @override
  String get photoUrlOptionalLabel => 'Foto (URL, optional)';

  @override
  String get submitReadingButton => 'Ablesung speichern';

  @override
  String readingSubmittedWithInvoiceSuccess(
    String consumption,
    String invoiceNumber,
    String total,
  ) {
    return 'Ablesung gespeichert. Verbrauch: $consumption m³. Rechnung $invoiceNumber: $total BAM.';
  }

  @override
  String readingSubmittedPaidInCashSuccess(String invoiceNumber, String total) {
    return 'Ablesung gespeichert. Rechnung $invoiceNumber ($total BAM) wurde bar bezahlt.';
  }

  @override
  String get paidInCashCheckboxLabel => 'Kunde zahlt bar';

  @override
  String get paidInCashCheckboxSubtitle =>
      'Die Rechnung wird sofort als bezahlt erfasst.';

  @override
  String get paidInCashConfirmTitle => 'Barzahlung bestätigen';

  @override
  String paidInCashConfirmMessage(String total) {
    return 'Bestätigen Sie, dass Sie $total BAM in bar vom Kunden erhalten haben? Die Rechnung wird als bezahlt erfasst.';
  }

  @override
  String readingSubmittedNoInvoiceSuccess(String consumption) {
    return 'Ablesung gespeichert. Verbrauch: $consumption m³. Keine Rechnung erstellt (Verbrauch ist 0).';
  }

  @override
  String get meterMarkedBrokenSuccess => 'Wasserzähler als defekt markiert.';

  @override
  String markBrokenDialogTitle(String serialNumber) {
    return 'Wasserzähler $serialNumber als defekt markieren';
  }

  @override
  String get reasonLabel => 'Grund';

  @override
  String get reasonRequiredError => 'Grund ist erforderlich.';

  @override
  String get priceSummaryHeading => 'Preisübersicht';

  @override
  String get pricePerM3Label => 'Preis pro m³';

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
  String get addressLabel => 'Adresse';

  @override
  String get customerLabel => 'Kunde';

  @override
  String get faultReportsScreenTitle => 'Störungsmeldungen';

  @override
  String get faultReportSearchHint => 'Titel oder Kundenname';

  @override
  String get collectorFaultReportsEmptyMessage => 'Keine Störungsmeldungen.';

  @override
  String reportedAtInlineLabel(String date) {
    return 'Gemeldet: $date';
  }

  @override
  String get allStatusesOption => 'Alle Status';

  @override
  String get statusChangeDialogTitle => 'Statusänderung';

  @override
  String statusChangeDialogContent(String status) {
    return 'Den Meldungsstatus auf „$status“ setzen?';
  }

  @override
  String get startActionButton => 'Starten';

  @override
  String get resolveActionButton => 'Beheben';

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

  @override
  String get newFaultReportTooltip => 'Neue Störungsmeldung';

  @override
  String get newFaultReportDialogTitle => 'Neue Störungsmeldung';

  @override
  String get newFaultReportSubmitButton => 'Meldung senden';

  @override
  String get newFaultReportCreatedMessage => 'Störungsmeldung gesendet.';

  @override
  String get faultReportTitleLabel => 'Titel';

  @override
  String get faultReportDescriptionLabel => 'Beschreibung';

  @override
  String get faultReportTitleTooLongError =>
      'Der Titel darf höchstens 150 Zeichen lang sein.';

  @override
  String get waterMeterOptionalLabel => 'Wasserzähler (optional)';

  @override
  String get waterMeterSearchHint =>
      'Wasserzähler suchen (Seriennummer, Eigentümer, Adresse)';

  @override
  String get waterMeterNoResults => 'Keine Wasserzähler gefunden.';

  @override
  String get waterMeterClearTooltip => 'Wasserzähler entfernen';

  @override
  String get streetOptionalLabel => 'Straße (optional)';

  @override
  String get houseNumberOptionalLabel => 'Hausnummer (optional)';

  @override
  String photoCountLabel(int count, int max) {
    return 'Fotos: $count/$max';
  }

  @override
  String get addPhotoButtonLabel => 'Foto hinzufügen';

  @override
  String get takePhotoOption => 'Foto aufnehmen';

  @override
  String get chooseFromGalleryOption => 'Aus der Galerie';
}
