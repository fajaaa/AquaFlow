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
  String get desktopUnavailableTitle => 'Auf dem Desktop nicht verfügbar';

  @override
  String get desktopUnavailableMessage =>
      'Die Desktop-App ist nur für Administratoren gedacht. Verwenden Sie für Ihre Rolle die mobile App.';

  @override
  String get stateLoading => 'Wird geladen...';

  @override
  String get errorGeneric => 'Fehler';

  @override
  String get emptyGeneric => 'Keine Daten';

  @override
  String sectionNotImplementedMessage(String label) {
    return 'Der Bereich „$label“ ist noch nicht implementiert.';
  }

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
  String get loginTitle => 'Anmeldung';

  @override
  String get fieldEmailLabel => 'E-Mail';

  @override
  String get emailRequiredError => 'E-Mail ist erforderlich.';

  @override
  String get emailInvalidError => 'Geben Sie eine gültige E-Mail-Adresse ein.';

  @override
  String get fieldPasswordLabel => 'Passwort';

  @override
  String get passwordRequiredError => 'Passwort ist erforderlich.';

  @override
  String get loginRememberMe => 'Angemeldet bleiben';

  @override
  String get welcomeTagline => 'Jeder Tropfen erfasst.';

  @override
  String get welcomeSubtitle =>
      'Kleine Schritte beim Wassersparen bewirken große Veränderungen.';

  @override
  String get authLoginButton => 'Anmelden';

  @override
  String get loginFailedError => 'Anmeldung fehlgeschlagen.';

  @override
  String get registerTitle => 'Registrierung';

  @override
  String get fieldFirstNameLabel => 'Vorname';

  @override
  String get firstNameRequiredError => 'Vorname ist erforderlich.';

  @override
  String get fieldLastNameLabel => 'Nachname';

  @override
  String get lastNameRequiredError => 'Nachname ist erforderlich.';

  @override
  String get fieldPhoneLabel => 'Telefon';

  @override
  String get phoneInvalidError =>
      'Das Telefon darf nur Ziffern und die Zeichen + - ( ) enthalten.';

  @override
  String get passwordTooShortError =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get fieldConfirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get passwordMismatchError => 'Die Passwörter stimmen nicht überein.';

  @override
  String get registerThemeLabel => 'Design';

  @override
  String get themeLightOption => 'Hell';

  @override
  String get themeDarkOption => 'Dunkel';

  @override
  String get authRegisterButton => 'Registrieren';

  @override
  String get registrationFailedError => 'Registrierung fehlgeschlagen.';

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
  String get fieldRequiredError => 'Pflichtfeld.';

  @override
  String get notLoggedInError => 'Nicht angemeldet.';

  @override
  String themeSaveFailedError(String message) {
    return 'Design nicht gespeichert: $message';
  }

  @override
  String languageSaveFailedError(String message) {
    return 'Sprache nicht gespeichert: $message';
  }

  @override
  String get personalDetailsAppearanceSectionTitle => 'Darstellung';

  @override
  String get nameRequiredTogetherError =>
      'Erforderlich, wenn Vor- und Nachname eingegeben werden.';

  @override
  String get dialogDismissButton => 'Abbrechen';

  @override
  String get addressLabel => 'Adresse';

  @override
  String get tabNotifications => 'Benachrichtigungen';

  @override
  String get faultReportsScreenTitle => 'Störungsmeldungen';

  @override
  String get logoutLabel => 'Abmelden';

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
  String get myAccountTitle => 'Mein Konto';

  @override
  String get myAccountSubtitle =>
      'Bearbeiten Sie Ihre Daten, die Darstellung der App und Ihr Passwort.';

  @override
  String get profileSectionLabel => 'Profil';

  @override
  String get contactSectionLabel => 'Kontakt';

  @override
  String get passwordOptionalHint =>
      'Leer lassen, wenn Sie Ihr Passwort nicht ändern.';

  @override
  String get phoneInvalidNumberError =>
      'Geben Sie eine gültige Telefonnummer ein.';

  @override
  String get accountDetailsSaveSuccess => 'Kontodaten gespeichert.';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get usersLabel => 'Benutzer';

  @override
  String get collectorsNavLabel => 'Ableser';

  @override
  String get administratorsLabel => 'Administratoren';

  @override
  String get financeGroupLabel => 'Finanzen';

  @override
  String get invoicesLabel => 'Rechnungen';

  @override
  String get paymentsLabel => 'Zahlungen';

  @override
  String get tariffsNavLabel => 'Tarife';

  @override
  String get supportGroupLabel => 'Support';

  @override
  String get waterMeterRequestsNavLabel => 'Anfragen';

  @override
  String get systemGroupLabel => 'System';

  @override
  String get codebookLabel => 'Codebuch';

  @override
  String get dashboardOverviewSubtitle =>
      'Übersicht der wichtigsten Kennzahlen';

  @override
  String get dashboardNoAccessMessage =>
      'Sie haben keinen Zugriff auf das Dashboard. Melden Sie sich ab und erneut an.';

  @override
  String get dashboardRevenueTrendChartTitle => 'Einnahmen';

  @override
  String get dashboardInvoiceStatusChartTitle => 'Rechnungsstatus';

  @override
  String get dashboardConsumptionTrendChartTitle => 'Wasserverbrauch';

  @override
  String get dashboardFaultReportStatusChartTitle =>
      'Störungsmeldungen nach Status';

  @override
  String get dashboardUserGrowthChartTitle => 'Wachstum des Kundenstamms';

  @override
  String get dashboardWaterMeterRequestStatusChartTitle =>
      'Wasserzähleranfragen nach Status';

  @override
  String get dashboardFilterCityLabel => 'Stadt';

  @override
  String get dashboardFilterAllCities => 'Alle Städte';

  @override
  String get dashboardFilterDateRangeTooltip => 'Zeitraum wählen';

  @override
  String get dashboardFilterReset => 'Filter zurücksetzen';

  @override
  String get statusFieldLabel => 'Status';

  @override
  String get allOption => 'Alle';

  @override
  String get statusActive => 'Aktiv';

  @override
  String get statusInactive => 'Inaktiv';

  @override
  String get unexpectedError => 'Ein unerwarteter Fehler ist aufgetreten.';

  @override
  String get fullNameColumnLabel => 'Vollständiger Name';

  @override
  String get createdColumnLabel => 'Erstellt';

  @override
  String get actionsColumnLabel => 'Aktionen';

  @override
  String get activitiesTooltip => 'Aktivitäten';

  @override
  String get accountSectionLabel => 'Konto';

  @override
  String get newPasswordOptionalLabel =>
      'Neues Passwort (leer lassen, um das aktuelle zu behalten)';

  @override
  String get commonClose => 'Schließen';

  @override
  String get waterMeterStatusRemoved => 'Entfernt';

  @override
  String get initialReadingLabel => 'Anfangsstand';

  @override
  String get usersScreenSubtitle =>
      'Kundenkonten anzeigen, hinzufügen, bearbeiten und löschen.';

  @override
  String get administratorsScreenSubtitle =>
      'Administratorkonten anzeigen, hinzufügen, bearbeiten und löschen.';

  @override
  String get newUserButtonLabel => 'Neuer Kunde';

  @override
  String get newAdministratorButtonLabel => 'Neuer Administrator';

  @override
  String get editUserDialogTitle => 'Kunde bearbeiten';

  @override
  String get editAdministratorDialogTitle => 'Administrator bearbeiten';

  @override
  String get userCreatedSuccess => 'Kunde hinzugefügt.';

  @override
  String get administratorCreatedSuccess => 'Administrator hinzugefügt.';

  @override
  String get userSavedSuccess => 'Kunde gespeichert.';

  @override
  String get administratorSavedSuccess => 'Administrator gespeichert.';

  @override
  String get deleteUserDialogTitle => 'Kunde löschen';

  @override
  String get deleteAdministratorDialogTitle => 'Administrator löschen';

  @override
  String deleteUserDialogContent(String email) {
    return 'Möchten Sie den Kunden „$email“ wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String deleteAdministratorDialogContent(String email) {
    return 'Möchten Sie den Administrator „$email“ wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get userDeletedSuccess => 'Kunde gelöscht.';

  @override
  String get administratorDeletedSuccess => 'Administrator gelöscht.';

  @override
  String get usersEmptyMessage => 'Keine Kunden.';

  @override
  String get administratorsEmptyMessage => 'Keine Administratoren.';

  @override
  String get usersEmptyFilteredMessage =>
      'Keine Kunden entsprechen den gewählten Filtern.';

  @override
  String get administratorsEmptyFilteredMessage =>
      'Keine Administratoren entsprechen den gewählten Filtern.';

  @override
  String get nameSearchHint => 'Vor- oder Nachname';

  @override
  String get clearSearchTooltip => 'Suche löschen';

  @override
  String get applyFiltersTooltip => 'Filter anwenden';

  @override
  String get rolesNotLoadedError =>
      'Die Rollen konnten nicht geladen werden. Bitte versuchen Sie es erneut.';

  @override
  String roleNotFoundError(String roleName) {
    return 'Rolle „$roleName“ wurde nicht gefunden.';
  }

  @override
  String get waterMetersTooltip => 'Wasserzähler';

  @override
  String get cannotDeleteOwnAccountError =>
      'Sie können Ihr eigenes Konto nicht löschen.';

  @override
  String get customerCodeFieldLabel => 'Kundennummer (automatisch vergeben)';

  @override
  String get cannotDeactivateOwnAccountError =>
      'Sie können Ihr eigenes Konto nicht deaktivieren.';

  @override
  String get nameRequiredForAddressError =>
      'Geben Sie Vor- und Nachname ein, um die Adresse zu speichern.';

  @override
  String get collectorsScreenSubtitle =>
      'Profile der Ableser im Außendienst anzeigen und bearbeiten.';

  @override
  String get addCollectorButtonLabel => 'Ableser hinzufügen';

  @override
  String get collectorCreatedSuccess => 'Ableser hinzugefügt.';

  @override
  String get collectorProfileSavedSuccess => 'Ableserprofil gespeichert.';

  @override
  String get collectorsEmptyMessage => 'Keine Ableserprofile.';

  @override
  String get collectorsSearchHint => 'Name, E-Mail oder Mitarbeiternummer';

  @override
  String get collectorsEmptyFilteredMessage =>
      'Keine Ableser entsprechen den aktuellen Filtern.';

  @override
  String get collectorCodeColumnLabel => 'Ablesernummer';

  @override
  String get editProfileTooltip => 'Profil bearbeiten';

  @override
  String get collectorCodeGeneratedHint =>
      'Die Ablesernummer wird nach dem Speichern automatisch vergeben, z. B. COL-0002.';

  @override
  String get editCollectorProfileDialogTitle => 'Ableserprofil bearbeiten';

  @override
  String get collectorCodeFieldLabel => 'Ablesernummer (automatisch vergeben)';

  @override
  String activityLogTitle(String displayName) {
    return 'Aktivitäten – $displayName';
  }

  @override
  String get eventTypeFieldLabel => 'Ereignis';

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
  String get userNoActivityMessage =>
      'Für diesen Benutzer sind keine Aktivitäten erfasst.';

  @override
  String get activitiesEmptyFilteredMessage =>
      'Keine Aktivitäten entsprechen den gewählten Filtern.';

  @override
  String get descriptionColumnLabel => 'Beschreibung';

  @override
  String get ipAddressColumnLabel => 'IP-Adresse';

  @override
  String get timeColumnLabel => 'Zeit';

  @override
  String waterMetersTitle(String displayName) {
    return 'Wasserzähler – $displayName';
  }

  @override
  String get userNoProfileMessage =>
      'Dieser Benutzer hat kein Profil und daher auch keine Wasserzähler.';

  @override
  String get userNoWaterMetersMessage =>
      'Für diesen Benutzer sind derzeit keine Wasserzähler erfasst.';

  @override
  String get installedLabel => 'Installiert';

  @override
  String get lastReadingLabel => 'Letzte Ablesung';

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
  String get codebookSubtitle =>
      'Verwaltungsverzeichnis der Orte: Städte, Gemeinden und Siedlungen.';

  @override
  String get backTooltip => 'Zurück';

  @override
  String get citiesLabel => 'Städte';

  @override
  String get openTooltip => 'Öffnen';

  @override
  String get citiesScreenSubtitle =>
      'Städte anzeigen, hinzufügen, bearbeiten und löschen.';

  @override
  String get newCityButtonLabel => 'Neue Stadt';

  @override
  String get cityCreatedSuccess => 'Stadt hinzugefügt.';

  @override
  String get citySavedSuccess => 'Stadt gespeichert.';

  @override
  String get deleteCityDialogTitle => 'Stadt löschen';

  @override
  String deleteCityDialogContent(String name) {
    return 'Möchten Sie die Stadt „$name“ wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get cityDeletedSuccess => 'Stadt gelöscht.';

  @override
  String get citySearchHint => 'Stadtname';

  @override
  String get citiesEmptyMessage => 'Keine Städte.';

  @override
  String get citiesEmptyFilteredMessage =>
      'Keine Städte entsprechen der Suche.';

  @override
  String get nameColumnLabel => 'Name';

  @override
  String get codeColumnLabel => 'Code';

  @override
  String get editCityDialogTitle => 'Stadt bearbeiten';

  @override
  String municipalitiesTitle(String cityName) {
    return 'Gemeinden · $cityName';
  }

  @override
  String get municipalitiesScreenSubtitle =>
      'Gemeinden anzeigen, hinzufügen, bearbeiten und löschen.';

  @override
  String get newMunicipalityButtonLabel => 'Neue Gemeinde';

  @override
  String get municipalityCreatedSuccess => 'Gemeinde hinzugefügt.';

  @override
  String get municipalitySavedSuccess => 'Gemeinde gespeichert.';

  @override
  String get deleteMunicipalityDialogTitle => 'Gemeinde löschen';

  @override
  String deleteMunicipalityDialogContent(String name) {
    return 'Möchten Sie die Gemeinde „$name“ wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get municipalityDeletedSuccess => 'Gemeinde gelöscht.';

  @override
  String get municipalitySearchHint => 'Gemeindename';

  @override
  String cityHasNoMunicipalitiesMessage(String cityName) {
    return 'Die Stadt „$cityName“ hat noch keine Gemeinden.';
  }

  @override
  String get municipalitiesEmptyFilteredMessage =>
      'Keine Gemeinden entsprechen der Suche.';

  @override
  String get editMunicipalityDialogTitle => 'Gemeinde bearbeiten';

  @override
  String settlementsTitle(String municipalityName) {
    return 'Siedlungen · $municipalityName';
  }

  @override
  String get settlementsScreenSubtitle =>
      'Siedlungen anzeigen, hinzufügen, bearbeiten und löschen.';

  @override
  String get newSettlementButtonLabel => 'Neue Siedlung';

  @override
  String get settlementCreatedSuccess => 'Siedlung hinzugefügt.';

  @override
  String get settlementSavedSuccess => 'Siedlung gespeichert.';

  @override
  String get deleteSettlementDialogTitle => 'Siedlung löschen';

  @override
  String deleteSettlementDialogContent(String name) {
    return 'Möchten Sie die Siedlung „$name“ wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get settlementDeletedSuccess => 'Siedlung gelöscht.';

  @override
  String get settlementSearchHint => 'Siedlungsname';

  @override
  String municipalityHasNoSettlementsMessage(String municipalityName) {
    return 'Die Gemeinde „$municipalityName“ hat noch keine Siedlungen.';
  }

  @override
  String get settlementsEmptyFilteredMessage =>
      'Keine Siedlungen entsprechen der Suche.';

  @override
  String get postalCodeColumnLabel => 'Postleitzahl';

  @override
  String get editSettlementDialogTitle => 'Siedlung bearbeiten';

  @override
  String get noCollectorsAvailableError => 'Keine Ableser verfügbar.';

  @override
  String get waterMeterRequestsPageTitle => 'Wasserzähleranfragen';

  @override
  String get waterMeterRequestsPageSubtitle =>
      'Anfragen für einen neuen Wasserzähler anzeigen, einem Ableser zuweisen und ablehnen.';

  @override
  String get allStatusesOption => 'Alle Status';

  @override
  String get requestStatusPending => 'Ausstehend';

  @override
  String get requestStatusAwaitingRegistration => 'Wartet auf Registrierung';

  @override
  String get requestStatusRegistered => 'Registriert';

  @override
  String get requestStatusRejected => 'Abgelehnt';

  @override
  String get requestStatusCancelled => 'Storniert';

  @override
  String get applyFilterTooltip => 'Filter anwenden';

  @override
  String get noWaterMeterRequestsMessage => 'Keine Wasserzähleranfragen.';

  @override
  String get waterMeterRequestsEmptyFilteredMessage =>
      'Keine Anfragen entsprechen dem gewählten Status.';

  @override
  String get customerColumnLabel => 'Kunde';

  @override
  String get collectorColumnLabel => 'Ableser';

  @override
  String collectorFallbackLabel(int id) {
    return 'Ableser #$id';
  }

  @override
  String get unknownSettlementLabel => 'Unbekannte Siedlung';

  @override
  String get noStreetAddressLabel => 'Keine Straßenadresse';

  @override
  String requestCustomerFallbackLabel(int id) {
    return 'Kunde #$id';
  }

  @override
  String get noPhoneLabel => 'Kein Telefon';

  @override
  String get assignToCollectorTooltip => 'Einem Ableser zuweisen';

  @override
  String get rejectTooltip => 'Ablehnen';

  @override
  String get selectionColumnLabel => 'Auswahl';

  @override
  String get assignButtonLabel => 'Zuweisen';

  @override
  String collectorProfileFallbackLabel(int id) {
    return 'Profil #$id';
  }

  @override
  String get rejectRequestDialogTitle => 'Anfrage ablehnen';

  @override
  String get reasonOptionalLabel => 'Grund (optional)';

  @override
  String get requestAssignedSuccess => 'Anfrage dem Ableser zugewiesen.';

  @override
  String get requestRejectedSuccess => 'Anfrage abgelehnt.';

  @override
  String get faultReportStatusNew => 'Neu';

  @override
  String get faultReportStatusAssigned => 'Zugewiesen';

  @override
  String get faultReportStatusInProgress => 'In Bearbeitung';

  @override
  String get faultReportStatusResolved => 'Behoben';

  @override
  String get changeStatusDialogTitle => 'Status ändern';

  @override
  String changeStatusDialogContent(String title, String status) {
    return 'Möchten Sie den Status der Meldung „$title“ wirklich auf „$status“ ändern?';
  }

  @override
  String get changeButtonLabel => 'Ändern';

  @override
  String get statusChangedSuccess => 'Meldungsstatus geändert.';

  @override
  String get faultReportAssignedSuccess =>
      'Störungsmeldung dem Ableser zugewiesen.';

  @override
  String get faultReportsPageSubtitle =>
      'Störungsmeldungen anzeigen und ihren Status verwalten.';

  @override
  String get faultReportSearchLabel => 'Titel, Kunde oder Siedlung';

  @override
  String get noFaultReportsMessage => 'Keine Störungsmeldungen.';

  @override
  String get faultReportsEmptyFilteredMessage =>
      'Keine Störungsmeldungen entsprechen den gewählten Filtern.';

  @override
  String get titleColumnLabel => 'Titel';

  @override
  String get customerLabel => 'Kunde';

  @override
  String get collectorNameColumnLabel => 'Ableser';

  @override
  String get dateColumnLabel => 'Datum';

  @override
  String collectorNumberFallbackLabel(int id) {
    return 'Ableser #$id';
  }

  @override
  String get reassignTooltip => 'Einem anderen Ableser zuweisen';

  @override
  String get assignmentNoLongerPossibleTooltip =>
      'Zuweisung ist nicht mehr möglich';

  @override
  String get reportResolvedTooltip => 'Meldung ist behoben';

  @override
  String changeStatusToTooltip(String status) {
    return 'Status auf „$status“ ändern';
  }

  @override
  String get noteOptionalFieldLabel => 'Notiz (optional)';

  @override
  String get assignmentNoteHint =>
      'Grund der Zuweisung oder Anweisungen für den Ableser';

  @override
  String get reportedAtLabel => 'Gemeldet';

  @override
  String get resolvedAtLabel => 'Behoben';

  @override
  String get photosSectionHeading => 'Fotos';

  @override
  String get noPhotosMessage => 'Keine Fotos angehängt.';

  @override
  String meterReadingsTitle(String serialNumber) {
    return 'Zählerablesungen – $serialNumber';
  }

  @override
  String get noReadingsForMeterMessage =>
      'Für diesen Wasserzähler wurden noch keine Ablesungen erfasst.';

  @override
  String get readingDateColumnLabel => 'Ablesedatum';

  @override
  String get previousReadingColumnLabel => 'Vorherig (m³)';

  @override
  String get newReadingColumnLabel => 'Neu (m³)';

  @override
  String get consumptionColumnLabel => 'Verbrauch (m³)';

  @override
  String get syncColumnLabel => 'Sync';

  @override
  String get syncStatusSynced => 'Synchronisiert';

  @override
  String get syncStatusFailed => 'Fehlgeschlagen';

  @override
  String get tariffCreatedSuccess => 'Tarif hinzugefügt.';

  @override
  String get tariffSavedSuccess => 'Tarif gespeichert.';

  @override
  String get tariffDeletedSuccess => 'Tarif gelöscht.';

  @override
  String get deleteTariffDialogTitle => 'Tarif löschen';

  @override
  String deleteTariffDialogContent(String name) {
    return 'Möchten Sie den Tarif „$name“ wirklich löschen? Das Löschen ist nicht möglich, wenn der Tarif in Rechnungspositionen verwendet wird.';
  }

  @override
  String get tariffsScreenSubtitle =>
      'Tarife anzeigen, hinzufügen, bearbeiten und löschen.';

  @override
  String get newTariffButtonLabel => 'Neuer Tarif';

  @override
  String get allOptionFeminine => 'Alle';

  @override
  String get activeFilterOption => 'Aktiv';

  @override
  String get inactiveFilterOption => 'Inaktiv';

  @override
  String get noTariffsMessage => 'Keine Tarife.';

  @override
  String get tariffsEmptyFilteredMessage =>
      'Keine Tarife entsprechen den gewählten Filtern.';

  @override
  String get pricePerM3Label => 'Preis pro m³';

  @override
  String get tariffStatusInactive => 'Inaktiv';

  @override
  String get tariffStatusActive => 'Aktiv';

  @override
  String get editTariffDialogTitle => 'Tarif bearbeiten';

  @override
  String get invalidNumberError => 'Geben Sie eine gültige Zahl ein.';

  @override
  String get negativeValueError => 'Der Wert darf nicht negativ sein.';

  @override
  String get invoiceStatusIssued => 'Ausgestellt';

  @override
  String get invoiceStatusPaid => 'Bezahlt';

  @override
  String get invoiceStatusCancelled => 'Storniert';

  @override
  String get markAsPaidLabel => 'Als bezahlt markieren';

  @override
  String markAsPaidDialogContent(String invoiceNumber, String amount) {
    return 'Möchten Sie die Rechnung „$invoiceNumber“ wirklich als bezahlt ($amount) markieren?';
  }

  @override
  String get invoiceMarkedPaidSuccess => 'Rechnung als bezahlt markiert.';

  @override
  String get cancelInvoiceDialogTitle => 'Rechnung stornieren';

  @override
  String cancelInvoiceDialogContent(String invoiceNumber) {
    return 'Möchten Sie die Rechnung „$invoiceNumber“ wirklich stornieren?';
  }

  @override
  String get cancelInvoiceButtonLabel => 'Rechnung stornieren';

  @override
  String get invoiceCancelledSuccess => 'Rechnung storniert.';

  @override
  String get invoicesScreenSubtitle =>
      'Rechnungen anzeigen und ihren Status verwalten.';

  @override
  String get invoiceNumberFieldLabel => 'Rechnungsnummer';

  @override
  String get monthFilterLabel => 'Monat';

  @override
  String get noInvoicesMessage => 'Keine Rechnungen.';

  @override
  String get invoicesEmptyFilteredMessage =>
      'Keine Rechnungen entsprechen den gewählten Filtern.';

  @override
  String get waterMeterColumnLabel => 'Wasserzähler';

  @override
  String get periodColumnLabel => 'Zeitraum';

  @override
  String get consumptionM3ColumnLabel => 'Verbrauch m³';

  @override
  String get amountColumnLabel => 'Betrag';

  @override
  String get paymentStatusCompleted => 'Abgeschlossen';

  @override
  String get paymentsScreenSubtitle =>
      'Erfasste Zahlungen anzeigen. Zahlungen werden ausschließlich über die Aktion „Zahlung erfassen“ im Bildschirm „Rechnungen“ erfasst.';

  @override
  String get invoiceIdFieldLabel => 'Rechnungs-ID';

  @override
  String get noPaymentsMessage => 'Keine Zahlungen.';

  @override
  String get paymentsEmptyFilteredMessage =>
      'Keine Zahlungen entsprechen den gewählten Filtern.';

  @override
  String get paymentDateColumnLabel => 'Zahlungsdatum';

  @override
  String get invoiceColumnLabel => 'Rechnung';

  @override
  String get methodColumnLabel => 'Methode';

  @override
  String get manualPaymentMethodLabel => 'Manuell';

  @override
  String get cashPaymentMethodLabel => 'Bar';

  @override
  String get cannotDetermineAdminUserError =>
      'Der Administrator konnte nicht ermittelt werden.';

  @override
  String get notificationCreatedSuccess => 'Benachrichtigung hinzugefügt.';

  @override
  String get cannotDetermineNotificationAuthorError =>
      'Der Verfasser der Benachrichtigung konnte nicht ermittelt werden.';

  @override
  String get notificationSavedSuccess => 'Benachrichtigung gespeichert.';

  @override
  String get deleteNotificationDialogTitle => 'Benachrichtigung löschen';

  @override
  String deleteNotificationDialogContent(String title) {
    return 'Möchten Sie die Benachrichtigung „$title“ wirklich löschen? Die zugehörigen Benachrichtigungseinträge der Benutzer werden ebenfalls entfernt.';
  }

  @override
  String get notificationDeletedSuccess => 'Benachrichtigung gelöscht.';

  @override
  String get notificationsScreenSubtitle =>
      'Systembenachrichtigungen anzeigen, hinzufügen, bearbeiten und löschen.';

  @override
  String get newNotificationButtonLabel => 'Neue Benachrichtigung';

  @override
  String get notificationSearchHint => 'Titel, Inhalt, Typ oder Zielgruppe';

  @override
  String get typeFieldLabel => 'Typ';

  @override
  String get notificationsAllTypesOption => 'Alle Typen';

  @override
  String get audienceFieldLabel => 'Zielgruppe';

  @override
  String get allAudiencesOption => 'Alle Zielgruppen';

  @override
  String get notificationsEmptyMessage => 'Keine Benachrichtigungen.';

  @override
  String get notificationsFilteredEmptyMessage =>
      'Keine Benachrichtigungen entsprechen den gewählten Filtern.';

  @override
  String get notificationColumnLabel => 'Benachrichtigung';

  @override
  String get createdAtColumnLabel => 'Erstellt';

  @override
  String notificationFallbackTitle(int id) {
    return 'Benachrichtigung #$id';
  }

  @override
  String get editNotificationDialogTitle => 'Benachrichtigung bearbeiten';

  @override
  String get contentFieldLabel => 'Inhalt';

  @override
  String imagesCountLabel(int count, int max) {
    return 'Bilder ($count/$max)';
  }

  @override
  String get addImageButtonLabel => 'Bild hinzufügen';

  @override
  String uploadingImageLabel(int current, int total) {
    return 'Bild $current/$total wird hochgeladen...';
  }

  @override
  String get notificationTypeInfoLabel => 'Info';

  @override
  String get notificationTypePlannedWorksLabel => 'Geplante Arbeiten';

  @override
  String get notificationTypeWarningLabel => 'Warnung';

  @override
  String get notificationTypeGenericLabel => 'Benachrichtigung';

  @override
  String get allUsersAudienceLabel => 'Alle Benutzer';

  @override
  String get customersAudienceLabel => 'Kunden';

  @override
  String get settlementAudienceLabel => 'Siedlung';

  @override
  String get supportTicketFilterOpen => 'Offen';

  @override
  String get supportTicketFilterClosed => 'Geschlossen';

  @override
  String get ticketSubjectSearchHint => 'Betreff des Tickets';

  @override
  String get supportTicketsScreenSubtitle =>
      'Alle Support-Tickets der Kunden. Orange markierte Tickets warten auf eine Antwort – die neueste Nachricht im Verlauf stammt nicht vom Support.';

  @override
  String get subjectColumnLabel => 'Betreff';

  @override
  String get messagesColumnLabel => 'Nachrichten';

  @override
  String get lastMessageColumnLabel => 'Letzte Nachricht';

  @override
  String ticketFallbackTitle(int id) {
    return 'Ticket #$id';
  }

  @override
  String get noTicketsFilteredMessage =>
      'Keine Tickets entsprechen den gewählten Filtern.';

  @override
  String get noTicketsMessage => 'Keine Tickets.';

  @override
  String get enterMessageTextError => 'Geben Sie den Nachrichtentext ein.';

  @override
  String get ticketClosedSuccess => 'Ticket geschlossen.';

  @override
  String get ticketReopenedSuccess => 'Ticket wieder geöffnet.';

  @override
  String get ticketFallbackLabel => 'Ticket';

  @override
  String get reopenTicketButtonLabel => 'Wieder öffnen';

  @override
  String get noMessagesMessage => 'Keine Nachrichten.';

  @override
  String get sendButtonLabel => 'Senden';

  @override
  String get writeReplyHint => 'Antwort schreiben...';

  @override
  String openedAtLabel(String date) {
    return 'Geöffnet: $date';
  }

  @override
  String get genericCustomerLabel => 'Kunde';

  @override
  String get ticketClosedBannerMessage =>
      'Dieses Ticket ist geschlossen. Öffnen Sie es erneut, um zu antworten.';

  @override
  String get supportTicketStatusOpen => 'Offen';

  @override
  String get supportTicketStatusClosed => 'Geschlossen';

  @override
  String get messageColumnLabel => 'Nachricht';

  @override
  String get consumptionAlertsNavLabel => 'Verbrauchswarnungen';

  @override
  String get consumptionAlertsScreenSubtitle =>
      'Warnungen zu Auffälligkeiten beim Wasserverbrauch prüfen und erledigen.';

  @override
  String get checkAnomaliesButtonLabel => 'Auffälligkeiten prüfen';

  @override
  String get consumptionAlertsRecomputedSuccess =>
      'Verbrauchsauffälligkeiten geprüft.';

  @override
  String get consumptionAlertsEmptyMessage => 'Keine Verbrauchswarnungen.';

  @override
  String get markAsResolvedTooltip => 'Als erledigt markieren';

  @override
  String get alertMarkedResolvedSuccess => 'Warnung als erledigt markiert.';

  @override
  String get measuredValueColumnLabel => 'Gemessener Wert';

  @override
  String get thresholdValueColumnLabel => 'Schwellenwert';

  @override
  String get resolvedStatusLabel => 'Erledigt';

  @override
  String get unresolvedStatusLabel => 'Nicht erledigt';

  @override
  String get sessionExpiredMessage =>
      'Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an.';

  @override
  String get passwordChangedSignInAgain =>
      'Ihr Passwort wurde geändert. Bitte melden Sie sich erneut an.';

  @override
  String get notificationDetailCreatedAtLabel => 'Erstellungsdatum';

  @override
  String get notificationDetailDescriptionHeading => 'Beschreibung';

  @override
  String get notificationDetailDetailsHeading => 'Details';

  @override
  String get notificationDetailEmptyBody => 'Kein weiterer Inhalt.';

  @override
  String notificationDetailImagesHeading(int count) {
    return 'Bilder ($count)';
  }

  @override
  String get notificationDetailTitle => 'Benachrichtigungsdetails';

  @override
  String get notificationStatusRead => 'Gelesen';

  @override
  String get notificationStatusUnread => 'Neu';

  @override
  String get notificationTypeFieldLabel => 'Benachrichtigungstyp';

  @override
  String get notificationsMarkAllReadTooltip => 'Alle als gelesen markieren';

  @override
  String get notificationsEmptyFilteredMessage =>
      'Keine Benachrichtigungen für den gewählten Typ.';

  @override
  String get notificationsNewBanner => 'Sie haben neue Benachrichtigungen';

  @override
  String get notificationOpenAction => 'Öffnen';

  @override
  String get notificationOpenRelatedFailed =>
      'Das zugehörige Element konnte nicht geöffnet werden. Möglicherweise ist es nicht mehr verfügbar.';

  @override
  String get notificationsInboxNavLabel => 'Meine Benachrichtigungen';

  @override
  String get notificationsManageNavLabel => 'Benachrichtigungen verwalten';

  @override
  String get reportsNavLabel => 'Berichte';

  @override
  String get reportsScreenTitle => 'Berichte';

  @override
  String get reportsScreenSubtitle =>
      'PDF-Berichte für den gewählten Zeitraum herunterladen oder drucken.';

  @override
  String get reportsConsumptionTitle => 'Wasserverbrauch nach Siedlung';

  @override
  String get reportsConsumptionDescription =>
      'Gesamter Wasserverbrauch pro Siedlung für den gewählten Zeitraum und die gewählte Stadt.';

  @override
  String get reportsBillingTitle => 'Rechnungen und Einzug';

  @override
  String get reportsBillingDescription =>
      'Ausgestellte, bezahlte und unbezahlte Rechnungen mit eingezogenen Beträgen für den gewählten Zeitraum.';

  @override
  String get reportsDownloadPdf => 'PDF herunterladen';

  @override
  String get reportsPrint => 'Drucken';

  @override
  String get reportsInvalidRange =>
      'Das Startdatum darf nicht nach dem Enddatum liegen.';

  @override
  String reportsSavedTo(String path) {
    return 'Gespeichert: $path';
  }
}
