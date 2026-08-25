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

  /// Generic logout button label, used e.g. by UnavailableScreen.
  ///
  /// In bs, this message translates to:
  /// **'Odjava'**
  String get commonLogout;

  /// Title shown when a non-admin account signs into the desktop app.
  ///
  /// In bs, this message translates to:
  /// **'Nedostupno na računaru'**
  String get desktopUnavailableTitle;

  /// Explanatory message shown alongside desktopUnavailableTitle.
  ///
  /// In bs, this message translates to:
  /// **'Desktop aplikacija je namijenjena samo administratorima. Za vašu ulogu koristite mobilnu aplikaciju.'**
  String get desktopUnavailableMessage;

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

  /// Fallback message shown for a sidebar section with no screen wired up yet.
  ///
  /// In bs, this message translates to:
  /// **'Sekcija \"{label}\" još nije implementirana.'**
  String sectionNotImplementedMessage(String label);

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

  /// Login screen header title.
  ///
  /// In bs, this message translates to:
  /// **'Prijava'**
  String get loginTitle;

  /// Shared label for an email input field (login, registration, account edit, company settings).
  ///
  /// In bs, this message translates to:
  /// **'Email'**
  String get fieldEmailLabel;

  /// Shared validation error shown when an email field is left empty (login, registration).
  ///
  /// In bs, this message translates to:
  /// **'Email je obavezan.'**
  String get emailRequiredError;

  /// Shared validation error shown when an email field does not look like a valid email address (login, registration, company settings).
  ///
  /// In bs, this message translates to:
  /// **'Unesite ispravan email.'**
  String get emailInvalidError;

  /// Shared label for a password input field (login, registration).
  ///
  /// In bs, this message translates to:
  /// **'Lozinka'**
  String get fieldPasswordLabel;

  /// Shared validation error shown when a password field is left empty (login, registration).
  ///
  /// In bs, this message translates to:
  /// **'Lozinka je obavezna.'**
  String get passwordRequiredError;

  /// Label for the 'remember me' checkbox on the login form.
  ///
  /// In bs, this message translates to:
  /// **'Zapamti me'**
  String get loginRememberMe;

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

  /// Login action button label.
  ///
  /// In bs, this message translates to:
  /// **'Prijavi se'**
  String get authLoginButton;

  /// Fallback snackbar message shown when login fails without a specific server error message.
  ///
  /// In bs, this message translates to:
  /// **'Prijava nije uspjela.'**
  String get loginFailedError;

  /// Registration screen header title.
  ///
  /// In bs, this message translates to:
  /// **'Registracija'**
  String get registerTitle;

  /// Shared label for a first-name input field (registration, account edit).
  ///
  /// In bs, this message translates to:
  /// **'Ime'**
  String get fieldFirstNameLabel;

  /// Validation error shown on the registration form when the first name field is left empty.
  ///
  /// In bs, this message translates to:
  /// **'Ime je obavezno.'**
  String get firstNameRequiredError;

  /// Shared label for a last-name input field (registration, account edit).
  ///
  /// In bs, this message translates to:
  /// **'Prezime'**
  String get fieldLastNameLabel;

  /// Validation error shown on the registration form when the last name field is left empty.
  ///
  /// In bs, this message translates to:
  /// **'Prezime je obavezno.'**
  String get lastNameRequiredError;

  /// Shared label for a phone input field (registration, account edit, company settings).
  ///
  /// In bs, this message translates to:
  /// **'Telefon'**
  String get fieldPhoneLabel;

  /// Validation error shown when the phone field contains characters other than digits and + - ( ).
  ///
  /// In bs, this message translates to:
  /// **'Telefon smije sadržavati samo brojeve i simbole + - ( ).'**
  String get phoneInvalidError;

  /// Shared validation error shown when a new password is shorter than 6 characters (registration, password reset, account edit).
  ///
  /// In bs, this message translates to:
  /// **'Lozinka mora imati najmanje 6 znakova.'**
  String get passwordTooShortError;

  /// Label for the confirm-password field on the registration form.
  ///
  /// In bs, this message translates to:
  /// **'Potvrdi lozinku'**
  String get fieldConfirmPasswordLabel;

  /// Shared validation error shown when a password confirmation field does not match (registration, password reset, account edit).
  ///
  /// In bs, this message translates to:
  /// **'Lozinke se ne podudaraju.'**
  String get passwordMismatchError;

  /// Section label above the theme picker on the registration form.
  ///
  /// In bs, this message translates to:
  /// **'Tema'**
  String get registerThemeLabel;

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

  /// Register action button label.
  ///
  /// In bs, this message translates to:
  /// **'Registruj se'**
  String get authRegisterButton;

  /// Fallback snackbar message shown when registration fails without a specific server error message.
  ///
  /// In bs, this message translates to:
  /// **'Registracija nije uspjela.'**
  String get registrationFailedError;

  /// Password reset screen app bar title, also reused as the account edit screen's password section label.
  ///
  /// In bs, this message translates to:
  /// **'Promjena lozinke'**
  String get passwordResetTitle;

  /// Instruction text shown above the password reset form.
  ///
  /// In bs, this message translates to:
  /// **'Unesite trenutnu i novu lozinku da biste je promijenili.'**
  String get passwordResetDescription;

  /// Label for the current-password field (password reset, account edit).
  ///
  /// In bs, this message translates to:
  /// **'Trenutna lozinka'**
  String get passwordResetCurrentLabel;

  /// Label for the new-password field (password reset, account edit).
  ///
  /// In bs, this message translates to:
  /// **'Nova lozinka'**
  String get passwordResetNewLabel;

  /// Label for the confirm-new-password field (password reset, account edit).
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

  /// Generic validation error for a required field left empty.
  ///
  /// In bs, this message translates to:
  /// **'Obavezno polje.'**
  String get fieldRequiredError;

  /// Error shown when the account edit screen tries to load data with no signed-in session.
  ///
  /// In bs, this message translates to:
  /// **'Niste prijavljeni.'**
  String get notLoggedInError;

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

  /// Section header above the theme/language pickers on the account edit form.
  ///
  /// In bs, this message translates to:
  /// **'Izgled'**
  String get personalDetailsAppearanceSectionTitle;

  /// Validation error shown when only one of first/last name is filled in.
  ///
  /// In bs, this message translates to:
  /// **'Obavezno ako unosite ime i prezime.'**
  String get nameRequiredTogetherError;

  /// Generic 'back out without acting' button label, distinct from commonCancel which cancels an in-progress action.
  ///
  /// In bs, this message translates to:
  /// **'Odustani'**
  String get dialogDismissButton;

  /// Label for the address field on the company settings form.
  ///
  /// In bs, this message translates to:
  /// **'Adresa'**
  String get addressLabel;

  /// Sidebar menu label for the notifications section.
  ///
  /// In bs, this message translates to:
  /// **'Obavijesti'**
  String get tabNotifications;

  /// Sidebar menu label for the fault reports section.
  ///
  /// In bs, this message translates to:
  /// **'Prijave kvarova'**
  String get faultReportsScreenTitle;

  /// Sidebar footer label for the logout action.
  ///
  /// In bs, this message translates to:
  /// **'Odjava'**
  String get logoutLabel;

  /// App bar title for the company settings screen, also used as the sidebar menu label for it.
  ///
  /// In bs, this message translates to:
  /// **'Postavke firme'**
  String get companySettingsScreenTitle;

  /// Label for the company name field on the company settings form.
  ///
  /// In bs, this message translates to:
  /// **'Naziv firme'**
  String get companyNameLabel;

  /// Label for the tax number field on the company settings form.
  ///
  /// In bs, this message translates to:
  /// **'Porezni broj'**
  String get taxNumberLabel;

  /// Label for the bank account field on the company settings form.
  ///
  /// In bs, this message translates to:
  /// **'Bankovni račun'**
  String get bankAccountLabel;

  /// Label for the optional logo URL field on the company settings form.
  ///
  /// In bs, this message translates to:
  /// **'URL logotipa (opcionalno)'**
  String get logoUrlOptionalLabel;

  /// Label for the default language field on the company settings form.
  ///
  /// In bs, this message translates to:
  /// **'Jezik'**
  String get defaultLanguageLabel;

  /// Label for the default currency field on the company settings form.
  ///
  /// In bs, this message translates to:
  /// **'Valuta'**
  String get defaultCurrencyLabel;

  /// Snackbar message shown after company settings are saved successfully.
  ///
  /// In bs, this message translates to:
  /// **'Postavke firme su sačuvane.'**
  String get companySettingsSaveSuccess;

  /// Title for the admin's own account screen, used as its header title, the sidebar menu label, and the sidebar footer tile.
  ///
  /// In bs, this message translates to:
  /// **'Moj nalog'**
  String get myAccountTitle;

  /// Subtitle shown under the header on the admin account edit screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredite svoje podatke, izgled aplikacije i lozinku.'**
  String get myAccountSubtitle;

  /// Section label above the name fields on the admin account edit form.
  ///
  /// In bs, this message translates to:
  /// **'Profil'**
  String get profileSectionLabel;

  /// Section label above the email/phone fields on the admin account edit form.
  ///
  /// In bs, this message translates to:
  /// **'Kontakt'**
  String get contactSectionLabel;

  /// Helper text above the password fields on the admin account edit form, noting they're optional.
  ///
  /// In bs, this message translates to:
  /// **'Ostavite prazno ako ne mijenjate lozinku.'**
  String get passwordOptionalHint;

  /// Validation error shown when the phone field on the admin account edit form doesn't look like a valid phone number.
  ///
  /// In bs, this message translates to:
  /// **'Unesite ispravan broj telefona.'**
  String get phoneInvalidNumberError;

  /// Snackbar message shown after the admin account edit form is saved successfully.
  ///
  /// In bs, this message translates to:
  /// **'Podaci naloga su sačuvani.'**
  String get accountDetailsSaveSuccess;

  /// Sidebar menu label for the dashboard section, also used as the dashboard overview's own heading.
  ///
  /// In bs, this message translates to:
  /// **'Dashboard'**
  String get dashboardLabel;

  /// Sidebar menu label for the 'Korisnici' category group and its own customer-management leaf item.
  ///
  /// In bs, this message translates to:
  /// **'Korisnici'**
  String get usersLabel;

  /// Sidebar menu label for the collectors management section.
  ///
  /// In bs, this message translates to:
  /// **'Inkasanti'**
  String get collectorsNavLabel;

  /// Sidebar menu label for the administrators management section.
  ///
  /// In bs, this message translates to:
  /// **'Administratori'**
  String get administratorsLabel;

  /// Sidebar menu label for the 'Finansije' category group.
  ///
  /// In bs, this message translates to:
  /// **'Finansije'**
  String get financeGroupLabel;

  /// Sidebar menu label for the invoices section.
  ///
  /// In bs, this message translates to:
  /// **'Računi'**
  String get invoicesLabel;

  /// Sidebar menu label for the payments section.
  ///
  /// In bs, this message translates to:
  /// **'Plaćanja'**
  String get paymentsLabel;

  /// Sidebar menu label for the tariffs section.
  ///
  /// In bs, this message translates to:
  /// **'Tarife'**
  String get tariffsNavLabel;

  /// Sidebar menu label for the 'Podrška' category group and its own support-tickets leaf item.
  ///
  /// In bs, this message translates to:
  /// **'Podrška'**
  String get supportGroupLabel;

  /// Sidebar menu label for the water meter requests section.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjevi'**
  String get waterMeterRequestsNavLabel;

  /// Sidebar menu label for the 'Sistem' category group.
  ///
  /// In bs, this message translates to:
  /// **'Sistem'**
  String get systemGroupLabel;

  /// Sidebar menu label for the codebook (cities/municipalities/settlements) section.
  ///
  /// In bs, this message translates to:
  /// **'Šifarnik'**
  String get codebookLabel;

  /// Subtitle under the dashboard overview heading, noting the charts show demo data.
  ///
  /// In bs, this message translates to:
  /// **'Pregled ključnih pokazatelja (demo podaci)'**
  String get dashboardOverviewSubtitle;

  /// Title for the demo line chart card on the dashboard overview.
  ///
  /// In bs, this message translates to:
  /// **'Linijski grafikon'**
  String get lineChartTitle;

  /// Title for the demo donut chart card on the dashboard overview.
  ///
  /// In bs, this message translates to:
  /// **'Kružni grafikon'**
  String get donutChartTitle;

  /// Title for the demo bar chart card on the dashboard overview.
  ///
  /// In bs, this message translates to:
  /// **'Trakasti grafikon'**
  String get barChartTitle;

  /// Legend label for the first series in the demo bar chart.
  ///
  /// In bs, this message translates to:
  /// **'Serija A'**
  String get seriesALabel;

  /// Legend label for the second series in the demo bar chart.
  ///
  /// In bs, this message translates to:
  /// **'Serija B'**
  String get seriesBLabel;

  /// Label for a status filter/column, shared across the users, collectors, and water meters screens.
  ///
  /// In bs, this message translates to:
  /// **'Status'**
  String get statusFieldLabel;

  /// Generic 'no filter' option meaning all values, shared by status/event-type filter dropdowns.
  ///
  /// In bs, this message translates to:
  /// **'Svi'**
  String get allOption;

  /// Display label for an active status, shared by users, collectors, and water meters.
  ///
  /// In bs, this message translates to:
  /// **'Aktivan'**
  String get statusActive;

  /// Display label for an inactive status, shared by users, collectors, and water meters.
  ///
  /// In bs, this message translates to:
  /// **'Neaktivan'**
  String get statusInactive;

  /// Generic fallback error message shown when a caught error carries no specific server message.
  ///
  /// In bs, this message translates to:
  /// **'Došlo je do neočekivane greške.'**
  String get unexpectedError;

  /// Table column header for a person's full name, shared by the users and collectors screens.
  ///
  /// In bs, this message translates to:
  /// **'Ime i prezime'**
  String get fullNameColumnLabel;

  /// Table column header for a row's creation date.
  ///
  /// In bs, this message translates to:
  /// **'Kreiran'**
  String get createdColumnLabel;

  /// Table column header for the row actions column.
  ///
  /// In bs, this message translates to:
  /// **'Akcije'**
  String get actionsColumnLabel;

  /// Tooltip for the row action that opens a user's activity log.
  ///
  /// In bs, this message translates to:
  /// **'Aktivnosti'**
  String get activitiesTooltip;

  /// Section label above the status/password fields in an editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Nalog'**
  String get accountSectionLabel;

  /// Label for the password field on an edit dialog, noting it's optional and blank keeps the current password.
  ///
  /// In bs, this message translates to:
  /// **'Nova lozinka (ostavi prazno da zadržiš postojeću)'**
  String get newPasswordOptionalLabel;

  /// Generic close button label for a dialog.
  ///
  /// In bs, this message translates to:
  /// **'Zatvori'**
  String get commonClose;

  /// Display label for the 'Removed' water meter status.
  ///
  /// In bs, this message translates to:
  /// **'Uklonjen'**
  String get waterMeterStatusRemoved;

  /// Label for a water meter's initial reading value.
  ///
  /// In bs, this message translates to:
  /// **'Početno očitanje'**
  String get initialReadingLabel;

  /// Subtitle on the 'Korisnici' (customers) screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodavanje, uređivanje i brisanje korisničkih naloga.'**
  String get usersScreenSubtitle;

  /// Subtitle on the 'Administratori' screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodavanje, uređivanje i brisanje administratorskih naloga.'**
  String get administratorsScreenSubtitle;

  /// 'New' button label and create-dialog title on the 'Korisnici' screen.
  ///
  /// In bs, this message translates to:
  /// **'Novi korisnik'**
  String get newUserButtonLabel;

  /// 'New' button label and create-dialog title on the 'Administratori' screen.
  ///
  /// In bs, this message translates to:
  /// **'Novi administrator'**
  String get newAdministratorButtonLabel;

  /// Edit-dialog title on the 'Korisnici' screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredi korisnika'**
  String get editUserDialogTitle;

  /// Edit-dialog title on the 'Administratori' screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredi administratora'**
  String get editAdministratorDialogTitle;

  /// Snackbar message shown after a customer user is created.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik je dodan.'**
  String get userCreatedSuccess;

  /// Snackbar message shown after an administrator is created.
  ///
  /// In bs, this message translates to:
  /// **'Administrator je dodan.'**
  String get administratorCreatedSuccess;

  /// Snackbar message shown after a customer user is saved.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik je sačuvan.'**
  String get userSavedSuccess;

  /// Snackbar message shown after an administrator is saved.
  ///
  /// In bs, this message translates to:
  /// **'Administrator je sačuvan.'**
  String get administratorSavedSuccess;

  /// Title of the delete-confirmation dialog on the 'Korisnici' screen.
  ///
  /// In bs, this message translates to:
  /// **'Obriši korisnika'**
  String get deleteUserDialogTitle;

  /// Title of the delete-confirmation dialog on the 'Administratori' screen.
  ///
  /// In bs, this message translates to:
  /// **'Obriši administratora'**
  String get deleteAdministratorDialogTitle;

  /// Body text of the delete-confirmation dialog on the 'Korisnici' screen, with the user's email.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite obrisati korisnika \"{email}\"? Ova radnja se ne može poništiti.'**
  String deleteUserDialogContent(String email);

  /// Body text of the delete-confirmation dialog on the 'Administratori' screen, with the user's email.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite obrisati administratora \"{email}\"? Ova radnja se ne može poništiti.'**
  String deleteAdministratorDialogContent(String email);

  /// Snackbar message shown after a customer user is deleted.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik je obrisan.'**
  String get userDeletedSuccess;

  /// Snackbar message shown after an administrator is deleted.
  ///
  /// In bs, this message translates to:
  /// **'Administrator je obrisan.'**
  String get administratorDeletedSuccess;

  /// Empty-state message on the 'Korisnici' screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema korisnika.'**
  String get usersEmptyMessage;

  /// Empty-state message on the 'Administratori' screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema administratora.'**
  String get administratorsEmptyMessage;

  /// Empty-state message on the 'Korisnici' screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema korisnika za zadane filtere.'**
  String get usersEmptyFilteredMessage;

  /// Empty-state message on the 'Administratori' screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema administratora za zadane filtere.'**
  String get administratorsEmptyFilteredMessage;

  /// Hint text for the name search field on the users screen.
  ///
  /// In bs, this message translates to:
  /// **'Ime ili prezime'**
  String get nameSearchHint;

  /// Tooltip for the button that clears the search field on the users screen.
  ///
  /// In bs, this message translates to:
  /// **'Očisti pretragu'**
  String get clearSearchTooltip;

  /// Tooltip for the button that applies the current filters on the users screen.
  ///
  /// In bs, this message translates to:
  /// **'Primijeni filtere'**
  String get applyFiltersTooltip;

  /// Error shown when the user roles lookup fails to load before opening the create/edit dialog.
  ///
  /// In bs, this message translates to:
  /// **'Uloge nisu učitane. Pokušajte ponovo.'**
  String get rolesNotLoadedError;

  /// Error shown when the screen's pinned role name has no matching role on the backend.
  ///
  /// In bs, this message translates to:
  /// **'Rola \"{roleName}\" nije pronađena.'**
  String roleNotFoundError(String roleName);

  /// Tooltip for the row action that opens a customer's water meters.
  ///
  /// In bs, this message translates to:
  /// **'Vodomjeri'**
  String get waterMetersTooltip;

  /// Tooltip shown on the delete action when it targets the signed-in admin's own account.
  ///
  /// In bs, this message translates to:
  /// **'Ne možete obrisati vlastiti korisnički nalog.'**
  String get cannotDeleteOwnAccountError;

  /// Read-only label for the auto-assigned customer code field on the user editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Šifra korisnika (automatski dodijeljena)'**
  String get customerCodeFieldLabel;

  /// Hint shown when the status switch is disabled because it targets the signed-in admin's own account.
  ///
  /// In bs, this message translates to:
  /// **'Ne možete deaktivirati vlastiti nalog.'**
  String get cannotDeactivateOwnAccountError;

  /// Validation error shown when an address is entered without a first/last name on the user editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Unesite ime i prezime da biste sačuvali adresu.'**
  String get nameRequiredForAddressError;

  /// Subtitle on the 'Inkasanti' screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled i uređivanje profila inkasanata za terenski rad.'**
  String get collectorsScreenSubtitle;

  /// 'Add' button label and create-dialog title on the 'Inkasanti' screen.
  ///
  /// In bs, this message translates to:
  /// **'Dodaj inkasanta'**
  String get addCollectorButtonLabel;

  /// Snackbar message shown after a collector is created.
  ///
  /// In bs, this message translates to:
  /// **'Inkasant je dodan.'**
  String get collectorCreatedSuccess;

  /// Snackbar message shown after a collector profile is saved.
  ///
  /// In bs, this message translates to:
  /// **'Profil inkasanta je sačuvan.'**
  String get collectorProfileSavedSuccess;

  /// Empty-state message on the 'Inkasanti' screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema profila inkasanata.'**
  String get collectorsEmptyMessage;

  /// Table column header for a collector's employee code.
  ///
  /// In bs, this message translates to:
  /// **'Šifra inkasanta'**
  String get collectorCodeColumnLabel;

  /// Tooltip for the row action that opens the collector profile editor.
  ///
  /// In bs, this message translates to:
  /// **'Uredi profil'**
  String get editProfileTooltip;

  /// Info banner on the collector create dialog, explaining the employee code is auto-generated.
  ///
  /// In bs, this message translates to:
  /// **'Šifra inkasanta se automatski kreira nakon spremanja, npr. COL-0002.'**
  String get collectorCodeGeneratedHint;

  /// Title of the collector profile editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Uredi profil inkasanta'**
  String get editCollectorProfileDialogTitle;

  /// Read-only label for the auto-assigned collector code field on the collector editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Šifra inkasanta (automatski dodijeljena)'**
  String get collectorCodeFieldLabel;

  /// App bar title on the user activity log screen, with the user's display name.
  ///
  /// In bs, this message translates to:
  /// **'Aktivnosti - {displayName}'**
  String activityLogTitle(String displayName);

  /// Label for the event-type filter dropdown on the activity log screen.
  ///
  /// In bs, this message translates to:
  /// **'Događaj'**
  String get eventTypeFieldLabel;

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

  /// Empty-state message on the activity log screen when the user has no recorded activity.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik nema zabilježenih aktivnosti.'**
  String get userNoActivityMessage;

  /// Empty-state message on the activity log screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema aktivnosti za zadane filtere.'**
  String get activitiesEmptyFilteredMessage;

  /// Table column header and detail-dialog label for an activity log entry's description.
  ///
  /// In bs, this message translates to:
  /// **'Opis'**
  String get descriptionColumnLabel;

  /// Table column header and detail-dialog label for an activity log entry's IP address.
  ///
  /// In bs, this message translates to:
  /// **'IP adresa'**
  String get ipAddressColumnLabel;

  /// Table column header and detail-dialog label for an activity log entry's timestamp.
  ///
  /// In bs, this message translates to:
  /// **'Vrijeme'**
  String get timeColumnLabel;

  /// App bar title on the user water meters screen, with the user's display name.
  ///
  /// In bs, this message translates to:
  /// **'Vodomjeri - {displayName}'**
  String waterMetersTitle(String displayName);

  /// Empty-state message on the user water meters screen when the user has no CustomerProfile.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik nema kreiran profil pa ni vodomjere.'**
  String get userNoProfileMessage;

  /// Empty-state message on the user water meters screen when the user has a profile but no water meters.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik trenutno nema evidentiranih vodomjera.'**
  String get userNoWaterMetersMessage;

  /// Label for a water meter's installation date.
  ///
  /// In bs, this message translates to:
  /// **'Instaliran'**
  String get installedLabel;

  /// Label for a water meter's last reading value.
  ///
  /// In bs, this message translates to:
  /// **'Zadnje očitanje'**
  String get lastReadingLabel;

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

  /// Label for the settlement dropdown/column on a location/address form.
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

  /// Subtitle under the codebook screen's 'Šifarnik' heading.
  ///
  /// In bs, this message translates to:
  /// **'Administrativni šifarnik lokacija: gradovi, općine i naselja.'**
  String get codebookSubtitle;

  /// Tooltip for the back button in the codebook screen's breadcrumb row.
  ///
  /// In bs, this message translates to:
  /// **'Nazad'**
  String get backTooltip;

  /// Display label for the cities level - the breadcrumb root and the cities screen's own header title.
  ///
  /// In bs, this message translates to:
  /// **'Gradovi'**
  String get citiesLabel;

  /// Tooltip for a clickable breadcrumb segment.
  ///
  /// In bs, this message translates to:
  /// **'Otvori'**
  String get openTooltip;

  /// Subtitle on the cities screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodavanje, uređivanje i brisanje gradova.'**
  String get citiesScreenSubtitle;

  /// 'New' button label and create-dialog title on the cities screen.
  ///
  /// In bs, this message translates to:
  /// **'Novi grad'**
  String get newCityButtonLabel;

  /// Snackbar message shown after a city is created.
  ///
  /// In bs, this message translates to:
  /// **'Grad je dodan.'**
  String get cityCreatedSuccess;

  /// Snackbar message shown after a city is saved.
  ///
  /// In bs, this message translates to:
  /// **'Grad je sačuvan.'**
  String get citySavedSuccess;

  /// Title of the delete-confirmation dialog on the cities screen.
  ///
  /// In bs, this message translates to:
  /// **'Obriši grad'**
  String get deleteCityDialogTitle;

  /// Body text of the delete-confirmation dialog on the cities screen, with the city's name.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite obrisati grad \"{name}\"? Ova radnja se ne može poništiti.'**
  String deleteCityDialogContent(String name);

  /// Snackbar message shown after a city is deleted.
  ///
  /// In bs, this message translates to:
  /// **'Grad je obrisan.'**
  String get cityDeletedSuccess;

  /// Hint text for the search field on the cities screen.
  ///
  /// In bs, this message translates to:
  /// **'Naziv grada'**
  String get citySearchHint;

  /// Empty-state message on the cities screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema gradova.'**
  String get citiesEmptyMessage;

  /// Empty-state message on the cities screen when the search excludes every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema gradova za zadanu pretragu.'**
  String get citiesEmptyFilteredMessage;

  /// Table column header and form field label for a codebook row's name, shared by cities/municipalities/settlements.
  ///
  /// In bs, this message translates to:
  /// **'Naziv'**
  String get nameColumnLabel;

  /// Table column header and form field label for a codebook row's code, shared by cities/municipalities.
  ///
  /// In bs, this message translates to:
  /// **'Kod'**
  String get codeColumnLabel;

  /// Edit-dialog title on the cities screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredi grad'**
  String get editCityDialogTitle;

  /// Header title on the municipalities screen, with the parent city's name.
  ///
  /// In bs, this message translates to:
  /// **'Općine · {cityName}'**
  String municipalitiesTitle(String cityName);

  /// Subtitle on the municipalities screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodavanje, uređivanje i brisanje općina.'**
  String get municipalitiesScreenSubtitle;

  /// 'New' button label, create-dialog title, and empty-state action label on the municipalities screen.
  ///
  /// In bs, this message translates to:
  /// **'Nova općina'**
  String get newMunicipalityButtonLabel;

  /// Snackbar message shown after a municipality is created.
  ///
  /// In bs, this message translates to:
  /// **'Općina je dodana.'**
  String get municipalityCreatedSuccess;

  /// Snackbar message shown after a municipality is saved.
  ///
  /// In bs, this message translates to:
  /// **'Općina je sačuvana.'**
  String get municipalitySavedSuccess;

  /// Title of the delete-confirmation dialog on the municipalities screen.
  ///
  /// In bs, this message translates to:
  /// **'Obriši općinu'**
  String get deleteMunicipalityDialogTitle;

  /// Body text of the delete-confirmation dialog on the municipalities screen, with the municipality's name.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite obrisati općinu \"{name}\"? Ova radnja se ne može poništiti.'**
  String deleteMunicipalityDialogContent(String name);

  /// Snackbar message shown after a municipality is deleted.
  ///
  /// In bs, this message translates to:
  /// **'Općina je obrisana.'**
  String get municipalityDeletedSuccess;

  /// Hint text for the search field on the municipalities screen.
  ///
  /// In bs, this message translates to:
  /// **'Naziv općine'**
  String get municipalitySearchHint;

  /// True-empty-state message on the municipalities screen when the parent city has no municipalities yet.
  ///
  /// In bs, this message translates to:
  /// **'Grad \'{cityName}\' još nema općina.'**
  String cityHasNoMunicipalitiesMessage(String cityName);

  /// Empty-state message on the municipalities screen when the search excludes every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema općina za zadanu pretragu.'**
  String get municipalitiesEmptyFilteredMessage;

  /// Edit-dialog title on the municipalities screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredi općinu'**
  String get editMunicipalityDialogTitle;

  /// Header title on the settlements screen, with the parent municipality's name.
  ///
  /// In bs, this message translates to:
  /// **'Naselja · {municipalityName}'**
  String settlementsTitle(String municipalityName);

  /// Subtitle on the settlements screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodavanje, uređivanje i brisanje naselja.'**
  String get settlementsScreenSubtitle;

  /// 'New' button label, create-dialog title, and empty-state action label on the settlements screen.
  ///
  /// In bs, this message translates to:
  /// **'Novo naselje'**
  String get newSettlementButtonLabel;

  /// Snackbar message shown after a settlement is created.
  ///
  /// In bs, this message translates to:
  /// **'Naselje je dodano.'**
  String get settlementCreatedSuccess;

  /// Snackbar message shown after a settlement is saved.
  ///
  /// In bs, this message translates to:
  /// **'Naselje je sačuvano.'**
  String get settlementSavedSuccess;

  /// Title of the delete-confirmation dialog on the settlements screen.
  ///
  /// In bs, this message translates to:
  /// **'Obriši naselje'**
  String get deleteSettlementDialogTitle;

  /// Body text of the delete-confirmation dialog on the settlements screen, with the settlement's name.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite obrisati naselje \"{name}\"? Ova radnja se ne može poništiti.'**
  String deleteSettlementDialogContent(String name);

  /// Snackbar message shown after a settlement is deleted.
  ///
  /// In bs, this message translates to:
  /// **'Naselje je obrisano.'**
  String get settlementDeletedSuccess;

  /// Hint text for the search field on the settlements screen.
  ///
  /// In bs, this message translates to:
  /// **'Naziv naselja'**
  String get settlementSearchHint;

  /// True-empty-state message on the settlements screen when the parent municipality has no settlements yet.
  ///
  /// In bs, this message translates to:
  /// **'Općina \'{municipalityName}\' još nema naselja.'**
  String municipalityHasNoSettlementsMessage(String municipalityName);

  /// Empty-state message on the settlements screen when the search excludes every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema naselja za zadanu pretragu.'**
  String get settlementsEmptyFilteredMessage;

  /// Table column header and form field label for a settlement's postal code.
  ///
  /// In bs, this message translates to:
  /// **'Poštanski broj'**
  String get postalCodeColumnLabel;

  /// Edit-dialog title on the settlements screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredi naselje'**
  String get editSettlementDialogTitle;

  /// Error shown when trying to assign a request/report but no collector profiles exist.
  ///
  /// In bs, this message translates to:
  /// **'Nema dostupnih inkasanata.'**
  String get noCollectorsAvailableError;

  /// App header title on the admin water meter requests screen.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjevi za vodomjer'**
  String get waterMeterRequestsPageTitle;

  /// Subtitle on the admin water meter requests screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodjela collectoru i odbijanje zahtjeva za novi vodomjer.'**
  String get waterMeterRequestsPageSubtitle;

  /// Option in a status filter dropdown meaning no filter (all statuses).
  ///
  /// In bs, this message translates to:
  /// **'Svi statusi'**
  String get allStatusesOption;

  /// Display label for the 'Pending' water meter request status.
  ///
  /// In bs, this message translates to:
  /// **'Na čekanju'**
  String get requestStatusPending;

  /// Display label for the 'Assigned' water meter request status - the request awaits the collector's on-site registration.
  ///
  /// In bs, this message translates to:
  /// **'Čeka registraciju'**
  String get requestStatusAwaitingRegistration;

  /// Display label for the 'Registered' water meter request status.
  ///
  /// In bs, this message translates to:
  /// **'Registrovan'**
  String get requestStatusRegistered;

  /// Display label for the 'Rejected' water meter request status.
  ///
  /// In bs, this message translates to:
  /// **'Odbijen'**
  String get requestStatusRejected;

  /// Display label for the 'Cancelled' water meter request status.
  ///
  /// In bs, this message translates to:
  /// **'Otkazan'**
  String get requestStatusCancelled;

  /// Tooltip for the button that applies the status filter on the water meter requests screen.
  ///
  /// In bs, this message translates to:
  /// **'Primijeni filter'**
  String get applyFilterTooltip;

  /// Empty-state message on the admin water meter requests screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema zahtjeva za novi vodomjer.'**
  String get noWaterMeterRequestsMessage;

  /// Empty-state message on the admin water meter requests screen when the status filter excludes every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema zahtjeva za odabrani status.'**
  String get waterMeterRequestsEmptyFilteredMessage;

  /// Table column header for the customer on the water meter requests screen.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik'**
  String get customerColumnLabel;

  /// Table column header for the assigned collector on the water meter requests screen.
  ///
  /// In bs, this message translates to:
  /// **'Collector'**
  String get collectorColumnLabel;

  /// Fallback collector label on the water meter requests screen when the collector has no code on file.
  ///
  /// In bs, this message translates to:
  /// **'Collector #{id}'**
  String collectorFallbackLabel(int id);

  /// Placeholder shown on a water meter request row when the settlement name is unknown.
  ///
  /// In bs, this message translates to:
  /// **'Naselje nepoznato'**
  String get unknownSettlementLabel;

  /// Placeholder shown on a water meter request row when the request has no street/house number.
  ///
  /// In bs, this message translates to:
  /// **'Bez ulice i broja'**
  String get noStreetAddressLabel;

  /// Fallback customer label on a water meter request row when the customer has no name on file.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik #{id}'**
  String requestCustomerFallbackLabel(int id);

  /// Placeholder shown on a water meter request row when the customer has no phone number on file.
  ///
  /// In bs, this message translates to:
  /// **'Bez telefona'**
  String get noPhoneLabel;

  /// Tooltip/title for the action that assigns a water meter request or fault report to a collector, and the shared assign dialog's own title.
  ///
  /// In bs, this message translates to:
  /// **'Dodijeli inkasantu'**
  String get assignToCollectorTooltip;

  /// Tooltip and submit-button label for rejecting a water meter request.
  ///
  /// In bs, this message translates to:
  /// **'Odbij'**
  String get rejectTooltip;

  /// Table column header for the radio-selection column in the collector assign dialog.
  ///
  /// In bs, this message translates to:
  /// **'Izbor'**
  String get selectionColumnLabel;

  /// Submit button label on the collector assign dialog.
  ///
  /// In bs, this message translates to:
  /// **'Dodijeli'**
  String get assignButtonLabel;

  /// Fallback subtitle in the collector assign dialog's row when the collector has no employee code on file.
  ///
  /// In bs, this message translates to:
  /// **'Profil #{id}'**
  String collectorProfileFallbackLabel(int id);

  /// Title of the reject-request dialog on the water meter requests screen.
  ///
  /// In bs, this message translates to:
  /// **'Odbij zahtjev'**
  String get rejectRequestDialogTitle;

  /// Label for the optional reason field on the reject-request dialog.
  ///
  /// In bs, this message translates to:
  /// **'Razlog (opciono)'**
  String get reasonOptionalLabel;

  /// Snackbar message shown after a water meter request is assigned to a collector.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev je dodijeljen inkasantu.'**
  String get requestAssignedSuccess;

  /// Snackbar message shown after a water meter request is rejected.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev je odbijen.'**
  String get requestRejectedSuccess;

  /// Display label for the 'New' fault report status.
  ///
  /// In bs, this message translates to:
  /// **'Nova'**
  String get faultReportStatusNew;

  /// Display label for the 'Assigned' fault report status.
  ///
  /// In bs, this message translates to:
  /// **'Dodijeljena'**
  String get faultReportStatusAssigned;

  /// Display label for the 'InProgress' fault report status.
  ///
  /// In bs, this message translates to:
  /// **'U toku'**
  String get faultReportStatusInProgress;

  /// Display label for the 'Resolved' fault report status.
  ///
  /// In bs, this message translates to:
  /// **'Riješena'**
  String get faultReportStatusResolved;

  /// Title of the status-advance confirmation dialog on the fault reports screen.
  ///
  /// In bs, this message translates to:
  /// **'Promijeni status'**
  String get changeStatusDialogTitle;

  /// Body text of the status-advance confirmation dialog, with the report's title and the target status label.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite promijeniti status prijave \"{title}\" u \"{status}\"?'**
  String changeStatusDialogContent(String title, String status);

  /// Confirm button label on the status-advance confirmation dialog.
  ///
  /// In bs, this message translates to:
  /// **'Promijeni'**
  String get changeButtonLabel;

  /// Snackbar message shown after a fault report's status is advanced.
  ///
  /// In bs, this message translates to:
  /// **'Status prijave je promijenjen.'**
  String get statusChangedSuccess;

  /// Snackbar message shown after a fault report is assigned to a collector.
  ///
  /// In bs, this message translates to:
  /// **'Prijava je dodijeljena inkasantu.'**
  String get faultReportAssignedSuccess;

  /// Subtitle on the admin fault reports screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled prijava kvarova i upravljanje statusom.'**
  String get faultReportsPageSubtitle;

  /// Label for the search field on the admin fault reports screen.
  ///
  /// In bs, this message translates to:
  /// **'Naslov, kupac ili naselje'**
  String get faultReportSearchLabel;

  /// Empty-state message on the admin fault reports screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema prijava kvarova.'**
  String get noFaultReportsMessage;

  /// Empty-state message on the admin fault reports screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema prijava kvarova za zadane filtere.'**
  String get faultReportsEmptyFilteredMessage;

  /// Table column header for a fault report's title.
  ///
  /// In bs, this message translates to:
  /// **'Naslov'**
  String get titleColumnLabel;

  /// Table column header and detail-dialog label for a fault report's customer.
  ///
  /// In bs, this message translates to:
  /// **'Kupac'**
  String get customerLabel;

  /// Table column header and detail-dialog label for a fault report's assigned collector.
  ///
  /// In bs, this message translates to:
  /// **'Inkasant'**
  String get collectorNameColumnLabel;

  /// Table column header for a fault report's creation date.
  ///
  /// In bs, this message translates to:
  /// **'Datum'**
  String get dateColumnLabel;

  /// Fallback collector label on the fault reports screen when the collector has no code on file.
  ///
  /// In bs, this message translates to:
  /// **'Inkasant #{id}'**
  String collectorNumberFallbackLabel(int id);

  /// Tooltip for the assign action on a fault report that already has a collector assigned.
  ///
  /// In bs, this message translates to:
  /// **'Preraspodijeli drugom inkasantu'**
  String get reassignTooltip;

  /// Tooltip for the disabled assign action once a fault report is past the assignable statuses.
  ///
  /// In bs, this message translates to:
  /// **'Dodjela više nije moguća'**
  String get assignmentNoLongerPossibleTooltip;

  /// Tooltip for the disabled status-advance action once a fault report is resolved.
  ///
  /// In bs, this message translates to:
  /// **'Prijava je riješena'**
  String get reportResolvedTooltip;

  /// Tooltip for the status-advance action, with the target status label.
  ///
  /// In bs, this message translates to:
  /// **'Promijeni status u \"{status}\"'**
  String changeStatusToTooltip(String status);

  /// Label for the optional note field on the fault report assign dialog.
  ///
  /// In bs, this message translates to:
  /// **'Napomena (opcionalno)'**
  String get noteOptionalFieldLabel;

  /// Hint text for the optional note field on the fault report assign dialog.
  ///
  /// In bs, this message translates to:
  /// **'Razlog dodjele ili uputa inkasantu'**
  String get assignmentNoteHint;

  /// Label for the reported-at date row on the fault report detail dialog.
  ///
  /// In bs, this message translates to:
  /// **'Prijavljeno'**
  String get reportedAtLabel;

  /// Label for the resolved-at date row on the fault report detail dialog.
  ///
  /// In bs, this message translates to:
  /// **'Riješeno'**
  String get resolvedAtLabel;

  /// Section heading for the photo gallery on the fault report detail dialog.
  ///
  /// In bs, this message translates to:
  /// **'Fotografije'**
  String get photosSectionHeading;

  /// Message shown in the photo gallery when a fault report has no attached photos.
  ///
  /// In bs, this message translates to:
  /// **'Nema priloženih fotografija.'**
  String get noPhotosMessage;

  /// App bar title on the admin meter readings screen, with the water meter's serial number.
  ///
  /// In bs, this message translates to:
  /// **'Očitanja - {serialNumber}'**
  String meterReadingsTitle(String serialNumber);

  /// Empty-state message on the admin meter readings screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Za ovaj vodomjer još nema evidentiranih očitanja.'**
  String get noReadingsForMeterMessage;

  /// Table column header for a meter reading's date.
  ///
  /// In bs, this message translates to:
  /// **'Datum očitanja'**
  String get readingDateColumnLabel;

  /// Table column header for a meter reading's previous value.
  ///
  /// In bs, this message translates to:
  /// **'Prethodno (m³)'**
  String get previousReadingColumnLabel;

  /// Table column header for a meter reading's new value.
  ///
  /// In bs, this message translates to:
  /// **'Novo (m³)'**
  String get newReadingColumnLabel;

  /// Table column header for a meter reading's consumption, on the meter readings screen.
  ///
  /// In bs, this message translates to:
  /// **'Potrošnja (m³)'**
  String get consumptionColumnLabel;

  /// Table column header for a meter reading's sync status.
  ///
  /// In bs, this message translates to:
  /// **'Sinhronizacija'**
  String get syncColumnLabel;

  /// Display label for the 'Synced' meter reading sync status.
  ///
  /// In bs, this message translates to:
  /// **'Sinhronizovano'**
  String get syncStatusSynced;

  /// Display label for the 'Failed' meter reading sync status.
  ///
  /// In bs, this message translates to:
  /// **'Neuspješno'**
  String get syncStatusFailed;

  /// Snackbar message shown after a tariff is created.
  ///
  /// In bs, this message translates to:
  /// **'Tarifa je dodana.'**
  String get tariffCreatedSuccess;

  /// Snackbar message shown after a tariff is saved.
  ///
  /// In bs, this message translates to:
  /// **'Tarifa je sačuvana.'**
  String get tariffSavedSuccess;

  /// Snackbar message shown after a tariff is deleted.
  ///
  /// In bs, this message translates to:
  /// **'Tarifa je obrisana.'**
  String get tariffDeletedSuccess;

  /// Title of the delete-confirmation dialog on the tariffs screen.
  ///
  /// In bs, this message translates to:
  /// **'Obriši tarifu'**
  String get deleteTariffDialogTitle;

  /// Body text of the delete-confirmation dialog on the tariffs screen, with the tariff's name.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite obrisati tarifu \"{name}\"? Brisanje neće biti moguće ako je tarifa referencirana stavkama računa.'**
  String deleteTariffDialogContent(String name);

  /// Subtitle on the tariffs screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodavanje, uređivanje i brisanje tarifa.'**
  String get tariffsScreenSubtitle;

  /// 'New' button label and create-dialog title on the tariffs screen.
  ///
  /// In bs, this message translates to:
  /// **'Nova tarifa'**
  String get newTariffButtonLabel;

  /// Generic 'no filter' option meaning all values, grammatically agreeing with a feminine-plural noun (e.g. 'tarife') - distinct from allOption's masculine form.
  ///
  /// In bs, this message translates to:
  /// **'Sve'**
  String get allOptionFeminine;

  /// Feminine-plural 'active' filter option (e.g. for tariffs), distinct from statusActive's masculine-singular form.
  ///
  /// In bs, this message translates to:
  /// **'Aktivne'**
  String get activeFilterOption;

  /// Feminine-plural 'inactive' filter option (e.g. for tariffs), distinct from statusInactive's masculine-singular form.
  ///
  /// In bs, this message translates to:
  /// **'Neaktivne'**
  String get inactiveFilterOption;

  /// Empty-state message on the tariffs screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema tarifa.'**
  String get noTariffsMessage;

  /// Empty-state message on the tariffs screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema tarifa za zadane filtere.'**
  String get tariffsEmptyFilteredMessage;

  /// Label for a tariff's price-per-cubic-metre field/column.
  ///
  /// In bs, this message translates to:
  /// **'Cijena po m³'**
  String get pricePerM3Label;

  /// Feminine-agreeing display label for an inactive tariff's status.
  ///
  /// In bs, this message translates to:
  /// **'Neaktivna'**
  String get tariffStatusInactive;

  /// Feminine-agreeing display label for an active tariff's status, also the label on the editor dialog's active switch.
  ///
  /// In bs, this message translates to:
  /// **'Aktivna'**
  String get tariffStatusActive;

  /// Edit-dialog title on the tariffs screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredi tarifu'**
  String get editTariffDialogTitle;

  /// Validation error shown when a numeric field doesn't parse as a number.
  ///
  /// In bs, this message translates to:
  /// **'Unesite ispravan broj.'**
  String get invalidNumberError;

  /// Validation error shown when a numeric field is negative.
  ///
  /// In bs, this message translates to:
  /// **'Vrijednost ne smije biti negativna.'**
  String get negativeValueError;

  /// Display label for the 'Issued' invoice status.
  ///
  /// In bs, this message translates to:
  /// **'Izdat'**
  String get invoiceStatusIssued;

  /// Display label for the 'Paid' invoice status.
  ///
  /// In bs, this message translates to:
  /// **'Plaćen'**
  String get invoiceStatusPaid;

  /// Display label for the 'Cancelled' invoice status.
  ///
  /// In bs, this message translates to:
  /// **'Storniran'**
  String get invoiceStatusCancelled;

  /// Tooltip/button/dialog-title text for the action that records an invoice as paid.
  ///
  /// In bs, this message translates to:
  /// **'Označi kao plaćeno'**
  String get markAsPaidLabel;

  /// Body text of the mark-as-paid confirmation dialog, with the invoice number and the already-formatted remaining amount (currency suffix included).
  ///
  /// In bs, this message translates to:
  /// **'Da li želite označiti račun \"{invoiceNumber}\" kao plaćen ({amount})?'**
  String markAsPaidDialogContent(String invoiceNumber, String amount);

  /// Snackbar message shown after an invoice is recorded as paid.
  ///
  /// In bs, this message translates to:
  /// **'Račun je označen kao plaćen.'**
  String get invoiceMarkedPaidSuccess;

  /// Title of the cancel-invoice confirmation dialog.
  ///
  /// In bs, this message translates to:
  /// **'Storniraj račun'**
  String get cancelInvoiceDialogTitle;

  /// Body text of the cancel-invoice confirmation dialog, with the invoice number.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite stornirati račun \"{invoiceNumber}\"?'**
  String cancelInvoiceDialogContent(String invoiceNumber);

  /// Tooltip/button label for the action that cancels an invoice.
  ///
  /// In bs, this message translates to:
  /// **'Storniraj'**
  String get cancelInvoiceButtonLabel;

  /// Snackbar message shown after an invoice is cancelled.
  ///
  /// In bs, this message translates to:
  /// **'Račun je storniran.'**
  String get invoiceCancelledSuccess;

  /// Subtitle on the invoices screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled računa i upravljanje njihovim statusom.'**
  String get invoicesScreenSubtitle;

  /// Label for the invoice number search field and table column on the invoices screen.
  ///
  /// In bs, this message translates to:
  /// **'Broj računa'**
  String get invoiceNumberFieldLabel;

  /// Label for the billing-month filter chip on the invoices screen when no month is selected.
  ///
  /// In bs, this message translates to:
  /// **'Mjesec'**
  String get monthFilterLabel;

  /// Empty-state message on the invoices screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema računa.'**
  String get noInvoicesMessage;

  /// Empty-state message on the invoices screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema računa za zadane filtere.'**
  String get invoicesEmptyFilteredMessage;

  /// Table column header for the water meter on the invoices screen.
  ///
  /// In bs, this message translates to:
  /// **'Vodomjer'**
  String get waterMeterColumnLabel;

  /// Table column header for an invoice's billing period.
  ///
  /// In bs, this message translates to:
  /// **'Period'**
  String get periodColumnLabel;

  /// Table column header for an invoice's consumption in cubic metres.
  ///
  /// In bs, this message translates to:
  /// **'Potrošnja m³'**
  String get consumptionM3ColumnLabel;

  /// Table column header for a monetary amount, shared by the invoices and payments screens.
  ///
  /// In bs, this message translates to:
  /// **'Iznos'**
  String get amountColumnLabel;

  /// Display label for the 'Completed' payment status.
  ///
  /// In bs, this message translates to:
  /// **'Završena'**
  String get paymentStatusCompleted;

  /// Subtitle on the payments screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled evidentiranih uplata. Uplate se evidentiraju isključivo putem akcije \"Evidentiraj uplatu\" na ekranu Računi.'**
  String get paymentsScreenSubtitle;

  /// Label for the invoice-id search field on the payments screen.
  ///
  /// In bs, this message translates to:
  /// **'ID računa'**
  String get invoiceIdFieldLabel;

  /// Empty-state message on the payments screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema uplata.'**
  String get noPaymentsMessage;

  /// Empty-state message on the payments screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema uplata za zadane filtere.'**
  String get paymentsEmptyFilteredMessage;

  /// Table column header for a payment's date.
  ///
  /// In bs, this message translates to:
  /// **'Datum uplate'**
  String get paymentDateColumnLabel;

  /// Table column header for the related invoice on the payments screen.
  ///
  /// In bs, this message translates to:
  /// **'Račun'**
  String get invoiceColumnLabel;

  /// Table column header for a payment's method.
  ///
  /// In bs, this message translates to:
  /// **'Način'**
  String get methodColumnLabel;

  /// Display label for the 'Manual' payment method.
  ///
  /// In bs, this message translates to:
  /// **'Ručno'**
  String get manualPaymentMethodLabel;

  /// Error shown when creating a notification but the signed-in admin's user id can't be resolved.
  ///
  /// In bs, this message translates to:
  /// **'Nije moguće odrediti admin korisnika.'**
  String get cannotDetermineAdminUserError;

  /// Snackbar message shown after a notification is created.
  ///
  /// In bs, this message translates to:
  /// **'Obavijest je dodana.'**
  String get notificationCreatedSuccess;

  /// Error shown when editing a notification but neither its author nor the signed-in admin's id can be resolved.
  ///
  /// In bs, this message translates to:
  /// **'Nije moguće odrediti autora obavijesti.'**
  String get cannotDetermineNotificationAuthorError;

  /// Snackbar message shown after a notification is saved.
  ///
  /// In bs, this message translates to:
  /// **'Obavijest je sačuvana.'**
  String get notificationSavedSuccess;

  /// Title of the delete-confirmation dialog on the notifications screen.
  ///
  /// In bs, this message translates to:
  /// **'Obriši obavijest'**
  String get deleteNotificationDialogTitle;

  /// Body text of the delete-confirmation dialog on the notifications screen, with the notification's title.
  ///
  /// In bs, this message translates to:
  /// **'Da li želite obrisati obavijest \"{title}\"? Povezani zapisi korisničkih obavijesti će također biti uklonjeni.'**
  String deleteNotificationDialogContent(String title);

  /// Snackbar message shown after a notification is deleted.
  ///
  /// In bs, this message translates to:
  /// **'Obavijest je obrisana.'**
  String get notificationDeletedSuccess;

  /// Subtitle on the notifications screen header.
  ///
  /// In bs, this message translates to:
  /// **'Pregled, dodavanje, uređivanje i brisanje sistemskih obavijesti.'**
  String get notificationsScreenSubtitle;

  /// 'New' button label and create-dialog title on the notifications screen.
  ///
  /// In bs, this message translates to:
  /// **'Nova obavijest'**
  String get newNotificationButtonLabel;

  /// Hint text for the search field on the notifications screen.
  ///
  /// In bs, this message translates to:
  /// **'Naslov, sadržaj, tip ili publika'**
  String get notificationSearchHint;

  /// Label for the notification type filter dropdown and form field.
  ///
  /// In bs, this message translates to:
  /// **'Tip'**
  String get typeFieldLabel;

  /// Option in the notification type filter dropdown meaning no filter (all types).
  ///
  /// In bs, this message translates to:
  /// **'Svi tipovi'**
  String get notificationsAllTypesOption;

  /// Label for the notification audience filter dropdown, form field, and table column - also the generic fallback label for an unrecognized audience value.
  ///
  /// In bs, this message translates to:
  /// **'Publika'**
  String get audienceFieldLabel;

  /// Option in the notification audience filter dropdown meaning no filter (all audiences).
  ///
  /// In bs, this message translates to:
  /// **'Sve publike'**
  String get allAudiencesOption;

  /// Empty-state message on the notifications screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema obavijesti.'**
  String get notificationsEmptyMessage;

  /// Empty-state message on the notifications screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema obavijesti za zadane filtere.'**
  String get notificationsFilteredEmptyMessage;

  /// Table column header for a notification's title/body on the notifications screen.
  ///
  /// In bs, this message translates to:
  /// **'Obavijest'**
  String get notificationColumnLabel;

  /// Table column header for a notification's creation date.
  ///
  /// In bs, this message translates to:
  /// **'Kreirano'**
  String get createdAtColumnLabel;

  /// Fallback notification title used when the notification has no title.
  ///
  /// In bs, this message translates to:
  /// **'Obavijest #{id}'**
  String notificationFallbackTitle(int id);

  /// Edit-dialog title on the notifications screen.
  ///
  /// In bs, this message translates to:
  /// **'Uredi obavijest'**
  String get editNotificationDialogTitle;

  /// Label for the notification body/content field on the notification editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Sadržaj'**
  String get contentFieldLabel;

  /// Label showing how many images are attached out of the maximum allowed, on the notification editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Slike ({count}/{max})'**
  String imagesCountLabel(int count, int max);

  /// Button/tooltip label for adding an image, shared by the notification editor dialog and the support ticket reply composer.
  ///
  /// In bs, this message translates to:
  /// **'Dodaj sliku'**
  String get addImageButtonLabel;

  /// Progress label shown while uploading images on the notification editor dialog.
  ///
  /// In bs, this message translates to:
  /// **'Slanje slike {current}/{total}...'**
  String uploadingImageLabel(int current, int total);

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

  /// Display label for the 'All' notification audience.
  ///
  /// In bs, this message translates to:
  /// **'Svi korisnici'**
  String get allUsersAudienceLabel;

  /// Display label for the 'Customers' notification audience, distinct from usersLabel's 'Users' translation despite the identical Bosnian word.
  ///
  /// In bs, this message translates to:
  /// **'Korisnici'**
  String get customersAudienceLabel;

  /// Display label for the 'Settlement' notification audience.
  ///
  /// In bs, this message translates to:
  /// **'Naselje'**
  String get settlementAudienceLabel;

  /// Plural-form filter option for open support tickets, distinct from supportTicketStatusOpen's singular pill label.
  ///
  /// In bs, this message translates to:
  /// **'Otvoreni'**
  String get supportTicketFilterOpen;

  /// Plural-form filter option for closed support tickets, distinct from supportTicketStatusClosed's singular pill label.
  ///
  /// In bs, this message translates to:
  /// **'Zatvoreni'**
  String get supportTicketFilterClosed;

  /// Hint text for the search field on the support tickets screen.
  ///
  /// In bs, this message translates to:
  /// **'Predmet tiketa'**
  String get ticketSubjectSearchHint;

  /// Subtitle on the support tickets screen header.
  ///
  /// In bs, this message translates to:
  /// **'Svi korisnički tiketi podrške. Tiketi označeni narandžastom čekaju odgovor - zadnja poruka u niti nije od podrške.'**
  String get supportTicketsScreenSubtitle;

  /// Table column header for a support ticket's subject.
  ///
  /// In bs, this message translates to:
  /// **'Predmet'**
  String get subjectColumnLabel;

  /// Table column header for a support ticket's message count.
  ///
  /// In bs, this message translates to:
  /// **'Poruke'**
  String get messagesColumnLabel;

  /// Table column header for a support ticket's last message date.
  ///
  /// In bs, this message translates to:
  /// **'Zadnja poruka'**
  String get lastMessageColumnLabel;

  /// Fallback subject shown on a support ticket row when the ticket has no subject.
  ///
  /// In bs, this message translates to:
  /// **'Tiket #{id}'**
  String ticketFallbackTitle(int id);

  /// Empty-state message on the support tickets screen when filters exclude every row.
  ///
  /// In bs, this message translates to:
  /// **'Nema tiketa za zadane filtere.'**
  String get noTicketsFilteredMessage;

  /// Empty-state message on the support tickets screen when there are no rows.
  ///
  /// In bs, this message translates to:
  /// **'Nema tiketa.'**
  String get noTicketsMessage;

  /// Snackbar message shown when trying to send an empty support ticket reply.
  ///
  /// In bs, this message translates to:
  /// **'Unesite tekst poruke.'**
  String get enterMessageTextError;

  /// Snackbar message shown after a support ticket is closed.
  ///
  /// In bs, this message translates to:
  /// **'Tiket je zatvoren.'**
  String get ticketClosedSuccess;

  /// Snackbar message shown after a support ticket is reopened.
  ///
  /// In bs, this message translates to:
  /// **'Tiket je ponovo otvoren.'**
  String get ticketReopenedSuccess;

  /// Fallback app bar title on the support ticket detail screen when the ticket has no subject and hasn't loaded an id-specific fallback.
  ///
  /// In bs, this message translates to:
  /// **'Tiket'**
  String get ticketFallbackLabel;

  /// Button label for reopening a closed support ticket.
  ///
  /// In bs, this message translates to:
  /// **'Ponovo otvori'**
  String get reopenTicketButtonLabel;

  /// Message shown in the support ticket thread when it has no messages.
  ///
  /// In bs, this message translates to:
  /// **'Nema poruka.'**
  String get noMessagesMessage;

  /// Tooltip/button label for sending a support ticket reply.
  ///
  /// In bs, this message translates to:
  /// **'Pošalji'**
  String get sendButtonLabel;

  /// Hint text for the reply composer's text field on the support ticket detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Napišite odgovor...'**
  String get writeReplyHint;

  /// Inline opened-at date shown on the support ticket detail screen's status header, with the already-formatted date.
  ///
  /// In bs, this message translates to:
  /// **'Otvoren: {date}'**
  String openedAtLabel(String date);

  /// Generic fallback sender label for a support ticket message from a customer with no name on file.
  ///
  /// In bs, this message translates to:
  /// **'Korisnik'**
  String get genericCustomerLabel;

  /// Banner message shown instead of the reply composer when a support ticket is closed.
  ///
  /// In bs, this message translates to:
  /// **'Tiket je zatvoren. Ponovo ga otvorite da odgovorite.'**
  String get ticketClosedBannerMessage;

  /// Singular display label for an open support ticket's status pill.
  ///
  /// In bs, this message translates to:
  /// **'Otvoren'**
  String get supportTicketStatusOpen;

  /// Singular display label for a closed support ticket's status pill.
  ///
  /// In bs, this message translates to:
  /// **'Zatvoren'**
  String get supportTicketStatusClosed;
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
