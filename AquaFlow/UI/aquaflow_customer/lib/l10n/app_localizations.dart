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

  /// Snackbar message shown when trying to save an address before a name has been set on the personal details screen.
  ///
  /// In bs, this message translates to:
  /// **'Unesite ime i prezime u \"Lični podaci\" da biste sačuvali adresu.'**
  String get locationNameRequiredError;

  /// Snackbar message shown after the location is saved successfully.
  ///
  /// In bs, this message translates to:
  /// **'Lokacija je sačuvana.'**
  String get locationSaveSuccess;

  /// Label for the city dropdown on the location edit form.
  ///
  /// In bs, this message translates to:
  /// **'Grad'**
  String get locationCityLabel;

  /// Option in the city dropdown meaning no city selected.
  ///
  /// In bs, this message translates to:
  /// **'Bez grada'**
  String get locationNoCityOption;

  /// Label for the municipality dropdown on the location edit form.
  ///
  /// In bs, this message translates to:
  /// **'Općina'**
  String get locationMunicipalityLabel;

  /// Option in the municipality dropdown meaning no municipality selected.
  ///
  /// In bs, this message translates to:
  /// **'Bez općine'**
  String get locationNoMunicipalityOption;

  /// Label for the settlement dropdown on the location edit form.
  ///
  /// In bs, this message translates to:
  /// **'Naselje'**
  String get locationSettlementLabel;

  /// Option in the settlement dropdown meaning no settlement selected.
  ///
  /// In bs, this message translates to:
  /// **'Bez naselja'**
  String get locationNoSettlementOption;

  /// Label for the street field on the location edit form.
  ///
  /// In bs, this message translates to:
  /// **'Ulica'**
  String get locationStreetLabel;

  /// Label for the house number field on the location edit form.
  ///
  /// In bs, this message translates to:
  /// **'Broj'**
  String get locationHouseNumberLabel;

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

  /// Bottom navigation label for the fault reports tab.
  ///
  /// In bs, this message translates to:
  /// **'Prijave kvarova'**
  String get tabFaultReports;

  /// Bottom navigation label for the account tab.
  ///
  /// In bs, this message translates to:
  /// **'Nalog'**
  String get tabAccount;

  /// Title for the support entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Podrška'**
  String get supportTitle;

  /// Subtitle for the support entry on the account screen.
  ///
  /// In bs, this message translates to:
  /// **'Vaši tiketi i poruke podršci'**
  String get supportSubtitle;
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
