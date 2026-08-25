import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bs'),
    Locale('en'),
  ];

  /// The application name, shown in the OS task switcher and window title.
  ///
  /// In bs, this message translates to:
  /// **'AquaFlow'**
  String get appTitle;

  /// Generic save action button label.
  ///
  /// In bs, this message translates to:
  /// **'Sačuvaj'**
  String get commonSave;

  /// Generic cancel action button label.
  ///
  /// In bs, this message translates to:
  /// **'Otkaži'**
  String get commonCancel;

  /// Generic delete action button label.
  ///
  /// In bs, this message translates to:
  /// **'Obriši'**
  String get commonDelete;

  /// Generic edit action button label.
  ///
  /// In bs, this message translates to:
  /// **'Uredi'**
  String get commonEdit;

  /// Generic refresh action button label.
  ///
  /// In bs, this message translates to:
  /// **'Osvježi'**
  String get commonRefresh;

  /// Generic search field label/placeholder.
  ///
  /// In bs, this message translates to:
  /// **'Pretraga'**
  String get commonSearch;

  /// Retry button label shown by ErrorRetry.
  ///
  /// In bs, this message translates to:
  /// **'Pokušaj ponovo'**
  String get commonRetry;

  /// Generic loading indicator caption.
  ///
  /// In bs, this message translates to:
  /// **'Učitavanje...'**
  String get stateLoading;

  /// Generic error state heading.
  ///
  /// In bs, this message translates to:
  /// **'Greška'**
  String get errorGeneric;

  /// Generic empty-state message used by EmptyStateView.
  ///
  /// In bs, this message translates to:
  /// **'Nema podataka'**
  String get emptyGeneric;

  /// Generic empty-list message, alternate phrasing of emptyGeneric for list-shaped content.
  ///
  /// In bs, this message translates to:
  /// **'Prazna lista'**
  String get emptyList;

  /// Tooltip for the previous-page button in PagedTablePaginationBar.
  ///
  /// In bs, this message translates to:
  /// **'Prethodna stranica'**
  String get paginationPrevious;

  /// Tooltip for the next-page button in PagedTablePaginationBar.
  ///
  /// In bs, this message translates to:
  /// **'Sljedeća stranica'**
  String get paginationNext;

  /// Current page summary in PagedTablePaginationBar.
  ///
  /// In bs, this message translates to:
  /// **'Stranica {page} od {totalPages}'**
  String paginationPageOf(int page, int totalPages);

  /// Total row count summary in PagedTablePaginationBar.
  ///
  /// In bs, this message translates to:
  /// **'{count} ukupno'**
  String paginationTotalCount(int count);

  /// Generic saving-in-progress button label, shown while a save request is in flight.
  ///
  /// In bs, this message translates to:
  /// **'Spašavanje...'**
  String get commonSaving;

  /// Tagline shown under the logo on the welcome screen.
  ///
  /// In bs, this message translates to:
  /// **'Svaka kap, evidentirana.'**
  String get welcomeTagline;

  /// Subtitle/italic quote shown under the tagline on the welcome screen.
  ///
  /// In bs, this message translates to:
  /// **'Mali koraci u štednji vode prave velike valove promjena.'**
  String get welcomeSubtitle;

  /// Login action button label, used on the welcome screen and as the login form's submit button.
  ///
  /// In bs, this message translates to:
  /// **'Prijavi se'**
  String get authLoginButton;

  /// Register action button label, used on the welcome screen and as the registration form's submit button.
  ///
  /// In bs, this message translates to:
  /// **'Registruj se'**
  String get authRegisterButton;

  /// Login screen app bar / header title.
  ///
  /// In bs, this message translates to:
  /// **'Prijava'**
  String get loginTitle;

  /// Welcome-back caption shown above the login form.
  ///
  /// In bs, this message translates to:
  /// **'Dobrodošli nazad'**
  String get loginWelcomeBack;

  /// Label for the 'remember me' checkbox on the login form.
  ///
  /// In bs, this message translates to:
  /// **'Zapamti me'**
  String get loginRememberMe;

  /// Fallback snackbar message shown when login fails without a specific server error message.
  ///
  /// In bs, this message translates to:
  /// **'Prijava nije uspjela.'**
  String get loginFailedError;

  /// Registration screen app bar / header title.
  ///
  /// In bs, this message translates to:
  /// **'Registracija'**
  String get registerTitle;

  /// Validation error shown on the registration form when the first name field is left empty.
  ///
  /// In bs, this message translates to:
  /// **'Ime je obavezno.'**
  String get firstNameRequiredError;

  /// Validation error shown on the registration form when the last name field is left empty.
  ///
  /// In bs, this message translates to:
  /// **'Prezime je obavezno.'**
  String get lastNameRequiredError;

  /// Validation error shown when the phone field contains characters other than digits and + - ( ).
  ///
  /// In bs, this message translates to:
  /// **'Telefon smije sadržavati samo brojeve i simbole + - ( ).'**
  String get phoneInvalidError;

  /// Label for the confirm-password field on the registration form.
  ///
  /// In bs, this message translates to:
  /// **'Potvrdi lozinku'**
  String get fieldConfirmPasswordLabel;

  /// Section label above the theme picker on the registration form.
  ///
  /// In bs, this message translates to:
  /// **'Tema'**
  String get registerThemeLabel;

  /// Fallback snackbar message shown when registration fails without a specific server error message.
  ///
  /// In bs, this message translates to:
  /// **'Registracija nije uspjela.'**
  String get registrationFailedError;

  /// Shared label for an email input field (login, registration, personal details).
  ///
  /// In bs, this message translates to:
  /// **'Email'**
  String get fieldEmailLabel;

  /// Shared label for a phone input field (registration, personal details).
  ///
  /// In bs, this message translates to:
  /// **'Telefon'**
  String get fieldPhoneLabel;

  /// Shared label for a first-name input field (registration, personal details).
  ///
  /// In bs, this message translates to:
  /// **'Ime'**
  String get fieldFirstNameLabel;

  /// Shared label for a last-name input field (registration, personal details).
  ///
  /// In bs, this message translates to:
  /// **'Prezime'**
  String get fieldLastNameLabel;

  /// Shared label for a password input field (login, registration).
  ///
  /// In bs, this message translates to:
  /// **'Lozinka'**
  String get fieldPasswordLabel;

  /// Shared validation error shown when an email field is left empty (login, registration).
  ///
  /// In bs, this message translates to:
  /// **'Email je obavezan.'**
  String get emailRequiredError;

  /// Shared validation error shown when an email field does not look like a valid email address (login, registration, personal details).
  ///
  /// In bs, this message translates to:
  /// **'Unesite ispravan email.'**
  String get emailInvalidError;

  /// Shared validation error shown when a password field is left empty (login, registration).
  ///
  /// In bs, this message translates to:
  /// **'Lozinka je obavezna.'**
  String get passwordRequiredError;

  /// Shared validation error shown when a new password is shorter than 6 characters (registration, password reset).
  ///
  /// In bs, this message translates to:
  /// **'Lozinka mora imati najmanje 6 znakova.'**
  String get passwordTooShortError;

  /// Shared validation error shown when a password confirmation field does not match (registration, password reset).
  ///
  /// In bs, this message translates to:
  /// **'Lozinke se ne podudaraju.'**
  String get passwordMismatchError;

  /// Generic validation error for a required field left empty.
  ///
  /// In bs, this message translates to:
  /// **'Obavezno polje.'**
  String get fieldRequiredError;

  /// Label for the light-theme option in a theme picker.
  ///
  /// In bs, this message translates to:
  /// **'Svijetla'**
  String get themeLightOption;

  /// Label for the dark-theme option in a theme picker.
  ///
  /// In bs, this message translates to:
  /// **'Tamna'**
  String get themeDarkOption;

  /// Password reset screen app bar title, also used as the account screen's entry title for it.
  ///
  /// In bs, this message translates to:
  /// **'Promjena lozinke'**
  String get passwordResetTitle;

  /// Instruction text shown above the password reset form.
  ///
  /// In bs, this message translates to:
  /// **'Unesite trenutnu i novu lozinku da biste je promijenili.'**
  String get passwordResetDescription;

  /// Label for the current-password field on the password reset form.
  ///
  /// In bs, this message translates to:
  /// **'Trenutna lozinka'**
  String get passwordResetCurrentLabel;

  /// Label for the new-password field on the password reset form.
  ///
  /// In bs, this message translates to:
  /// **'Nova lozinka'**
  String get passwordResetNewLabel;

  /// Label for the confirm-new-password field on the password reset form.
  ///
  /// In bs, this message translates to:
  /// **'Potvrda nove lozinke'**
  String get passwordResetConfirmLabel;

  /// Submit button label on the password reset form.
  ///
  /// In bs, this message translates to:
  /// **'Promijeni lozinku'**
  String get passwordResetSubmitButton;

  /// Snackbar message shown after a successful password change.
  ///
  /// In bs, this message translates to:
  /// **'Lozinka je promijenjena.'**
  String get passwordResetSuccess;

  /// Validation error shown when the current-password field is left empty.
  ///
  /// In bs, this message translates to:
  /// **'Unesite trenutnu lozinku.'**
  String get passwordResetCurrentRequiredError;

  /// Validation error shown when the new-password field is left empty.
  ///
  /// In bs, this message translates to:
  /// **'Unesite novu lozinku.'**
  String get passwordResetNewRequiredError;

  /// Personal details screen app bar title, also used as the account screen's entry title for it.
  ///
  /// In bs, this message translates to:
  /// **'Lični podaci'**
  String get personalDetailsTitle;

  /// Snackbar message shown when saving the theme preference fails, with the server error appended.
  ///
  /// In bs, this message translates to:
  /// **'Tema nije sačuvana: {message}'**
  String themeSaveFailedError(String message);

  /// Snackbar message shown when saving the language preference fails, with the server error appended.
  ///
  /// In bs, this message translates to:
  /// **'Jezik nije sačuvan: {message}'**
  String languageSaveFailedError(String message);

  /// Snackbar message shown after personal details are saved successfully.
  ///
  /// In bs, this message translates to:
  /// **'Lični podaci su sačuvani.'**
  String get personalDetailsSaveSuccess;

  /// Section header above the first/last name fields on the personal details form.
  ///
  /// In bs, this message translates to:
  /// **'Ime i prezime'**
  String get personalDetailsNameSectionTitle;

  /// Section header above the theme/language pickers on the personal details form.
  ///
  /// In bs, this message translates to:
  /// **'Izgled'**
  String get personalDetailsAppearanceSectionTitle;

  /// Validation error shown on the personal details form when only one of first/last name is filled in.
  ///
  /// In bs, this message translates to:
  /// **'Obavezno ako unosite ime i prezime.'**
  String get nameRequiredTogetherError;

  /// Section header above the account-data entry cards on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Podaci o nalogu'**
  String get accountDataSectionTitle;

  /// Subtitle for the personal details entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Ime, prezime, email, telefon i tema'**
  String get accountPersonalDetailsSubtitle;

  /// Location edit screen app bar title, also used as the account screen's entry title for it.
  ///
  /// In bs, this message translates to:
  /// **'Lokacija'**
  String get locationTitle;

  /// Subtitle for the location entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Adresa prebivališta'**
  String get accountLocationSubtitle;

  /// Subtitle for the password-change entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Ažuriranje lozinke naloga'**
  String get accountPasswordSubtitle;

  /// Title for the activity log entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Moje aktivnosti'**
  String get accountActivityLogTitle;

  /// Subtitle for the activity log entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Historija prijava i izmjena naloga'**
  String get accountActivityLogSubtitle;

  /// Title for the admin-only company settings entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Postavke firme'**
  String get accountCompanySettingsTitle;

  /// Subtitle for the admin-only company settings entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Upravljanje podacima firme'**
  String get accountCompanySettingsSubtitle;

  /// Display label for the admin user role.
  ///
  /// In bs, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// Display label for the collector user role.
  ///
  /// In bs, this message translates to:
  /// **'Inkasant'**
  String get roleCollector;

  /// Display label for the customer user role, also used as the generic fallback role label.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik'**
  String get roleCustomer;

  /// Tooltip for the theme-toggle icon button in the mobile shell's app bar.
  ///
  /// In bs, this message translates to:
  /// **'Promijeni temu'**
  String get mobileShellThemeTooltip;

  /// Tooltip for the logout icon button in the mobile shell's app bar.
  ///
  /// In bs, this message translates to:
  /// **'Odjava'**
  String get mobileShellLogoutTooltip;

  /// Bottom navigation label for the notifications tab.
  ///
  /// In bs, this message translates to:
  /// **'Obavijesti'**
  String get tabNotifications;

  /// Bottom navigation label for the water meters tab.
  ///
  /// In bs, this message translates to:
  /// **'Vodomjeri'**
  String get tabWaterMeters;

  /// Bottom navigation label for the collector's assigned water meter requests tab.
  ///
  /// In bs, this message translates to:
  /// **'Nalozi'**
  String get tabWaterMeterRequests;

  /// Bottom navigation label for the account tab.
  ///
  /// In bs, this message translates to:
  /// **'Nalog'**
  String get tabAccount;

  /// Error shown when a screen tries to load per-user data (notifications, activity log) with no signed-in session.
  ///
  /// In bs, this message translates to:
  /// **'Niste prijavljeni.'**
  String get notLoggedInError;

  /// Tooltip for the 'mark all as read' icon button on the notifications screen.
  ///
  /// In bs, this message translates to:
  /// **'Označi sve kao pročitano'**
  String get notificationsMarkAllReadTooltip;

  /// Shared label for the notification type: the filter dropdown on the notifications list, and the type field on the notification detail screen (also shown uppercased as an eyebrow label there).
  ///
  /// In bs, this message translates to:
  /// **'Tip obavijesti'**
  String get notificationTypeFieldLabel;

  /// Option in the notification type filter dropdown meaning no filter (all types).
  ///
  /// In bs, this message translates to:
  /// **'Svi tipovi'**
  String get notificationsAllTypesOption;

  /// Display label for the 'Info' notification type.
  ///
  /// In bs, this message translates to:
  /// **'Info'**
  String get notificationTypeInfoLabel;

  /// Display label for the 'PlannedWorks' notification type.
  ///
  /// In bs, this message translates to:
  /// **'Planirani radovi'**
  String get notificationTypePlannedWorksLabel;

  /// Display label for the 'Warning' notification type.
  ///
  /// In bs, this message translates to:
  /// **'Upozorenje'**
  String get notificationTypeWarningLabel;

  /// Generic singular fallback label for a notification of unknown/empty type.
  ///
  /// In bs, this message translates to:
  /// **'Obavijest'**
  String get notificationTypeGenericLabel;

  /// Fallback notification title used when the notification has no title, shown on both the list card and the detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Obavijest #{id}'**
  String notificationFallbackTitle(int id);

  /// Empty-state message shown when the notification list has no items.
  ///
  /// In bs, this message translates to:
  /// **'Nema obavijesti.'**
  String get notificationsEmptyMessage;

  /// Empty-state message shown when the notification list has no items matching the selected type filter.
  ///
  /// In bs, this message translates to:
  /// **'Nema obavijesti za odabrani tip.'**
  String get notificationsEmptyFilteredMessage;

  /// Notification detail screen app bar title.
  ///
  /// In bs, this message translates to:
  /// **'Detalji obavijesti'**
  String get notificationDetailTitle;

  /// Generic 'Description' section heading, used above the notification body text on the notification detail screen and above the description text on the fault report detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Opis'**
  String get notificationDetailDescriptionHeading;

  /// Placeholder shown in the description section when the notification has no body text.
  ///
  /// In bs, this message translates to:
  /// **'Nema dodatnog sadržaja.'**
  String get notificationDetailEmptyBody;

  /// Section heading above the type/date detail rows on the notification detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Detalji'**
  String get notificationDetailDetailsHeading;

  /// Label for the created-at date row on the notification detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Datum kreiranja'**
  String get notificationDetailCreatedAtLabel;

  /// Section heading above the image gallery on the notification detail screen, with the image count.
  ///
  /// In bs, this message translates to:
  /// **'Slike ({count})'**
  String notificationDetailImagesHeading(int count);

  /// Status pill label shown on a read notification's detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Pročitano'**
  String get notificationStatusRead;

  /// Status pill label shown on an unread notification's detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Novo'**
  String get notificationStatusUnread;

  /// Empty-state message shown when the activity log has no items.
  ///
  /// In bs, this message translates to:
  /// **'Nema zabilježenih aktivnosti.'**
  String get activityLogEmptyMessage;

  /// Display label for the 'LoginSuccess' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Uspješna prijava'**
  String get activityTypeLoginSuccess;

  /// Display label for the 'LoginFailed' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Neuspješna prijava'**
  String get activityTypeLoginFailed;

  /// Display label for the 'TokenRefreshed' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Obnova sesije'**
  String get activityTypeTokenRefreshed;

  /// Display label for the 'PasswordChanged' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Promjena lozinke'**
  String get activityTypePasswordChanged;

  /// Display label for the 'AccountUpdated' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Izmjena naloga'**
  String get activityTypeAccountUpdated;

  /// Display label for the 'UserRoleChanged' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Promjena role'**
  String get activityTypeUserRoleChanged;

  /// Display label for the 'UserActivated' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik aktiviran'**
  String get activityTypeUserActivated;

  /// Display label for the 'UserDeactivated' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik deaktiviran'**
  String get activityTypeUserDeactivated;

  /// Display label for the 'UserDeleted' activity log event type.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik obrisan'**
  String get activityTypeUserDeleted;

  /// Generic singular fallback label for an activity log event of unknown/empty type.
  ///
  /// In bs, this message translates to:
  /// **'Aktivnost'**
  String get activityTypeGenericLabel;

  /// Generic 'back out of this dialog without acting' button label, distinct from commonCancel which cancels an in-progress action.
  ///
  /// In bs, this message translates to:
  /// **'Odustani'**
  String get dialogDismissButton;

  /// Generic confirm action button label.
  ///
  /// In bs, this message translates to:
  /// **'Potvrdi'**
  String get commonConfirm;

  /// Generic tooltip for a button that clears a text field's content (e.g. a search box), distinct from commonDelete which removes a record.
  ///
  /// In bs, this message translates to:
  /// **'Obriši'**
  String get commonClear;

  /// Label for the city dropdown on a location/address form.
  ///
  /// In bs, this message translates to:
  /// **'Grad'**
  String get locationCityLabel;

  /// Option in the city dropdown meaning no city selected.
  ///
  /// In bs, this message translates to:
  /// **'Bez grada'**
  String get locationNoCityOption;

  /// Label for the municipality dropdown on a location/address form.
  ///
  /// In bs, this message translates to:
  /// **'Općina'**
  String get locationMunicipalityLabel;

  /// Option in the municipality dropdown meaning no municipality selected.
  ///
  /// In bs, this message translates to:
  /// **'Bez općine'**
  String get locationNoMunicipalityOption;

  /// Label for the settlement dropdown on a location/address form.
  ///
  /// In bs, this message translates to:
  /// **'Naselje'**
  String get locationSettlementLabel;

  /// Option in the settlement dropdown meaning no settlement selected.
  ///
  /// In bs, this message translates to:
  /// **'Bez naselja'**
  String get locationNoSettlementOption;

  /// Label for the street field on a location/address form.
  ///
  /// In bs, this message translates to:
  /// **'Ulica'**
  String get locationStreetLabel;

  /// Label for the house number field on a location/address form.
  ///
  /// In bs, this message translates to:
  /// **'Broj'**
  String get locationHouseNumberLabel;

  /// Validation error shown when no settlement is selected on the water meter registration dialog.
  ///
  /// In bs, this message translates to:
  /// **'Odaberite naselje.'**
  String get settlementRequiredError;

  /// Title on a water meter request card.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev #{id}'**
  String requestCardTitle(int id);

  /// Display label for the 'Assigned' water meter request status.
  ///
  /// In bs, this message translates to:
  /// **'Dodijeljen'**
  String get requestStatusAssigned;

  /// Label for the initial reading field on the water meter registration dialog.
  ///
  /// In bs, this message translates to:
  /// **'Početno očitanje'**
  String get initialReadingLabel;

  /// Label for the consumption line on the meter reading entry screen's price preview.
  ///
  /// In bs, this message translates to:
  /// **'Potrošnja'**
  String get consumptionLabel;

  /// Label for the total amount line on the meter reading entry screen's price preview.
  ///
  /// In bs, this message translates to:
  /// **'Ukupno'**
  String get totalLabel;

  /// Display label for the 'Active' water meter status.
  ///
  /// In bs, this message translates to:
  /// **'Aktivan'**
  String get waterMeterStatusActive;

  /// Display label for the 'Inactive' water meter status.
  ///
  /// In bs, this message translates to:
  /// **'Neaktivan'**
  String get waterMeterStatusInactive;

  /// Display label for the 'Removed' water meter status.
  ///
  /// In bs, this message translates to:
  /// **'Uklonjen'**
  String get waterMeterStatusRemoved;

  /// Section heading for the meter info card on the meter reading entry screen.
  ///
  /// In bs, this message translates to:
  /// **'Podaci o vodomjeru'**
  String get meterInfoSectionHeading;

  /// Eyebrow label above the meter's last reading value on the meter reading entry screen, shown uppercased.
  ///
  /// In bs, this message translates to:
  /// **'Zadnje stanje'**
  String get lastReadingStateLabel;

  /// Tooltip for the icon button on the water meters screen that opens the fault reports screen.
  ///
  /// In bs, this message translates to:
  /// **'Prijave kvarova'**
  String get faultReportsTooltip;

  /// Hint text for the free-text search field on the collector water meters screen.
  ///
  /// In bs, this message translates to:
  /// **'Ime vlasnika, naselje, serijski broj ili adresa'**
  String get collectorMeterSearchHint;

  /// Empty-state message shown when a water meter search returns no results, with the searched term.
  ///
  /// In bs, this message translates to:
  /// **'Nema vodomjera za \"{term}\".'**
  String collectorMetersEmptyMessage(String term);

  /// Inline last-reading value shown on a water meter list card, with the already-formatted reading value.
  ///
  /// In bs, this message translates to:
  /// **'Zadnje stanje: {value} m³'**
  String collectorLastReadingLabel(String value);

  /// Prompt message shown on the water meters screen before any search term has been entered.
  ///
  /// In bs, this message translates to:
  /// **'Unesite ime vlasnika, naselje, serijski broj ili adresu.'**
  String get collectorMetersPromptMessage;

  /// Header title on the collector's assigned water meter requests screen.
  ///
  /// In bs, this message translates to:
  /// **'Radni nalozi'**
  String get waterMeterRequestsScreenTitle;

  /// Empty-state message shown when the collector has no assigned water meter requests.
  ///
  /// In bs, this message translates to:
  /// **'Trenutno nema dodijeljenih zahtjeva.'**
  String get waterMeterRequestsEmptyMessage;

  /// Snackbar message shown after a water meter is registered successfully from a request.
  ///
  /// In bs, this message translates to:
  /// **'Vodomjer je registrovan.'**
  String get meterRegisteredSuccess;

  /// Fallback customer label used on a water meter request card when the customer has no name on file.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik #{id}'**
  String customerFallbackLabel(int id);

  /// Placeholder shown on a water meter request card when the customer has no phone number on file.
  ///
  /// In bs, this message translates to:
  /// **'Broj telefona nije dostupan'**
  String get phoneNotAvailableLabel;

  /// Inline created-at date shown on a water meter request card, with the already-formatted date/time.
  ///
  /// In bs, this message translates to:
  /// **'Kreirano: {date}'**
  String createdAtInlineLabel(String date);

  /// Button label that starts a phone call to the customer from a water meter request card.
  ///
  /// In bs, this message translates to:
  /// **'Pozovi'**
  String get callButton;

  /// Snackbar shown when launching a phone call/SMS intent fails because the device doesn't support it.
  ///
  /// In bs, this message translates to:
  /// **'Akcija nije podržana na ovom uređaju.'**
  String get actionNotSupportedError;

  /// Title for the water meter registration action/dialog, used both as the card's submit button label and the dialog's title.
  ///
  /// In bs, this message translates to:
  /// **'Registruj vodomjer'**
  String get registerWaterMeterTitle;

  /// Submit button label on the water meter registration dialog.
  ///
  /// In bs, this message translates to:
  /// **'Registruj'**
  String get registerButton;

  /// Label for the serial number field on the water meter registration dialog.
  ///
  /// In bs, this message translates to:
  /// **'Serijski broj'**
  String get serialNumberLabel;

  /// Label for the installation date field on the water meter registration dialog.
  ///
  /// In bs, this message translates to:
  /// **'Datum instalacije'**
  String get installedAtFieldLabel;

  /// Tooltip for the icon button that opens the date/time picker on the water meter registration dialog.
  ///
  /// In bs, this message translates to:
  /// **'Odaberi datum'**
  String get pickDateTooltip;

  /// Validation error shown when a numeric reading field is empty, negative, or not a number.
  ///
  /// In bs, this message translates to:
  /// **'Unesite pozitivan broj.'**
  String get positiveNumberRequiredError;

  /// Tooltip for the app bar action that marks a water meter as no longer functional.
  ///
  /// In bs, this message translates to:
  /// **'Označi kao neispravan'**
  String get markBrokenTooltip;

  /// Banner message shown when fewer than 15 days have passed since the meter's last reading, with the date the next reading becomes allowed.
  ///
  /// In bs, this message translates to:
  /// **'Sljedeće očitanje je moguće od: {date}'**
  String nextReadingAllowedLabel(String date);

  /// Section heading for the reading entry form on the meter reading entry screen.
  ///
  /// In bs, this message translates to:
  /// **'Novo očitanje'**
  String get newReadingSectionHeading;

  /// Label for the new reading value field on the meter reading entry screen.
  ///
  /// In bs, this message translates to:
  /// **'Novo stanje (m³)'**
  String get newReadingFieldLabel;

  /// Label for the tariff dropdown on the meter reading entry screen.
  ///
  /// In bs, this message translates to:
  /// **'Tarifa'**
  String get tariffLabel;

  /// Placeholder hint shown in the tariff dropdown while active tariffs are loading.
  ///
  /// In bs, this message translates to:
  /// **'Učitavanje tarifa...'**
  String get tariffsLoadingHint;

  /// Placeholder hint shown in the tariff dropdown when there are no active tariffs to choose from.
  ///
  /// In bs, this message translates to:
  /// **'Nema aktivnih tarifa'**
  String get tariffsEmptyHint;

  /// Placeholder hint shown in the tariff dropdown prompting the collector to pick one.
  ///
  /// In bs, this message translates to:
  /// **'Odaberite tarifu'**
  String get tariffSelectHint;

  /// Label for the optional note field on the meter reading entry screen.
  ///
  /// In bs, this message translates to:
  /// **'Napomena (opcionalno)'**
  String get noteOptionalLabel;

  /// Label for the optional photo URL field on the meter reading entry screen.
  ///
  /// In bs, this message translates to:
  /// **'Foto (URL, opcionalno)'**
  String get photoUrlOptionalLabel;

  /// Submit button label on the meter reading entry form.
  ///
  /// In bs, this message translates to:
  /// **'Snimi očitanje'**
  String get submitReadingButton;

  /// Snackbar message shown after a meter reading is submitted and the server generated an invoice for it, with the already-formatted consumption/invoice number/total.
  ///
  /// In bs, this message translates to:
  /// **'Očitanje je snimljeno. Potrošnja: {consumption} m³. Račun {invoiceNumber}: {total} BAM.'**
  String readingSubmittedWithInvoiceSuccess(
    String consumption,
    String invoiceNumber,
    String total,
  );

  /// Snackbar message shown after a meter reading is submitted with zero consumption, so the server created no invoice.
  ///
  /// In bs, this message translates to:
  /// **'Očitanje je snimljeno. Potrošnja: {consumption} m³. Račun nije kreiran (potrošnja je 0).'**
  String readingSubmittedNoInvoiceSuccess(String consumption);

  /// Snackbar message shown after a water meter is successfully marked as broken/removed.
  ///
  /// In bs, this message translates to:
  /// **'Vodomjer je označen kao neispravan.'**
  String get meterMarkedBrokenSuccess;

  /// Title of the mark-broken confirmation dialog, with the meter's serial number.
  ///
  /// In bs, this message translates to:
  /// **'Označi vodomjer {serialNumber} neispravnim'**
  String markBrokenDialogTitle(String serialNumber);

  /// Label for the reason field on the mark-broken dialog.
  ///
  /// In bs, this message translates to:
  /// **'Razlog'**
  String get reasonLabel;

  /// Validation error shown when the mark-broken dialog's reason field is left empty.
  ///
  /// In bs, this message translates to:
  /// **'Razlog je obavezan.'**
  String get reasonRequiredError;

  /// Eyebrow heading above the live price preview on the meter reading entry screen, shown uppercased.
  ///
  /// In bs, this message translates to:
  /// **'Pregled iznosa'**
  String get priceSummaryHeading;

  /// Label for the price-per-cubic-metre line on the meter reading entry screen's price preview.
  ///
  /// In bs, this message translates to:
  /// **'Cijena po m³'**
  String get pricePerM3Label;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bs':
      return AppLocalizationsBs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
