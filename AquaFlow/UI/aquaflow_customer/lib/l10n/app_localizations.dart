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

  /// Generic send action tooltip/button label, e.g. for a chat message composer.
  ///
  /// In bs, this message translates to:
  /// **'Pošalji'**
  String get commonSend;

  /// Generic tooltip for a button that opens the take-photo/choose-from-gallery sheet.
  ///
  /// In bs, this message translates to:
  /// **'Dodaj sliku'**
  String get commonAddPhoto;

  /// Option label in the image-source bottom sheet for taking a photo with the camera.
  ///
  /// In bs, this message translates to:
  /// **'Slikaj'**
  String get commonTakePhoto;

  /// Option label in the image-source bottom sheet for picking a photo from the gallery.
  ///
  /// In bs, this message translates to:
  /// **'Iz galerije'**
  String get commonChooseFromGallery;

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

  /// Tooltip for the '+' icon button that opens the new water meter request dialog.
  ///
  /// In bs, this message translates to:
  /// **'Dodaj vodomjer'**
  String get addWaterMeterTooltip;

  /// Empty-state message shown when the customer has no water meters.
  ///
  /// In bs, this message translates to:
  /// **'Trenutno nemate evidentiranih vodomjera.'**
  String get waterMetersEmptyMessage;

  /// Inline last-reading value shown on a water meter list card, with the already-formatted reading value.
  ///
  /// In bs, this message translates to:
  /// **'Zadnje očitanje: {value} m³'**
  String lastReadingLabel(String value);

  /// Snackbar message shown after a new water meter request is submitted successfully.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev za novi vodomjer je poslan.'**
  String get newWaterMeterRequestSuccess;

  /// Title for the water meter requests screen/tooltip, shared by the requests screen app bar and the 'open requests' icon button on the water meters tab.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjevi'**
  String get requestsTitle;

  /// Tooltip for the 'new request' icon button on the requests screen.
  ///
  /// In bs, this message translates to:
  /// **'Novi zahtjev'**
  String get newRequestTooltip;

  /// Title of the confirmation dialog shown before cancelling a water meter request.
  ///
  /// In bs, this message translates to:
  /// **'Otkazati zahtjev?'**
  String get cancelRequestConfirmTitle;

  /// Body of the confirmation dialog shown before cancelling a water meter request.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev za novi vodomjer #{id} će biti otkazan.'**
  String cancelRequestConfirmMessage(int id);

  /// Button label for cancelling a water meter request, used both on the request card and as the confirm action in its confirmation dialog.
  ///
  /// In bs, this message translates to:
  /// **'Otkaži zahtjev'**
  String get cancelRequestButton;

  /// Snackbar message shown after a water meter request is cancelled successfully.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev je otkazan.'**
  String get cancelRequestSuccess;

  /// Title on a water meter request card.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev #{id}'**
  String requestCardTitle(int id);

  /// Empty-state message shown when the customer has no water meter requests.
  ///
  /// In bs, this message translates to:
  /// **'Nemate poslanih zahtjeva za vodomjer.'**
  String get requestsEmptyMessage;

  /// Title of the new water meter request dialog.
  ///
  /// In bs, this message translates to:
  /// **'Zahtjev za novi vodomjer'**
  String get newWaterMeterRequestTitle;

  /// Submit button label on the new water meter request dialog.
  ///
  /// In bs, this message translates to:
  /// **'Pošalji zahtjev'**
  String get newWaterMeterRequestSubmitButton;

  /// Label for the optional note field on the new water meter request dialog.
  ///
  /// In bs, this message translates to:
  /// **'Napomena (opciono)'**
  String get newWaterMeterRequestNoteLabel;

  /// Validation error shown when no settlement is selected on the new water meter request dialog.
  ///
  /// In bs, this message translates to:
  /// **'Odaberite naselje.'**
  String get settlementRequiredError;

  /// Button label on the water meter detail screen that opens that meter's invoices.
  ///
  /// In bs, this message translates to:
  /// **'Prikaži račune'**
  String get showInvoicesButton;

  /// Section heading for the meter info card on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Podaci o vodomjeru'**
  String get meterInfoSectionHeading;

  /// Label for the address field on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Adresa'**
  String get addressLabel;

  /// Label for the installation date field on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Datum ugradnje'**
  String get installedAtLabel;

  /// Label for the initial reading field on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Početno očitanje'**
  String get initialReadingLabel;

  /// Plain label for the last reading field on the water meter detail screen's meter info card.
  ///
  /// In bs, this message translates to:
  /// **'Zadnje očitanje'**
  String get lastReadingFieldLabel;

  /// Label for the last reading stat, with unit, on the water meter detail screen's stats card.
  ///
  /// In bs, this message translates to:
  /// **'Zadnje očitanje (m³)'**
  String get lastReadingM3Label;

  /// Section heading for the stats card on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Statistika'**
  String get statisticsSectionHeading;

  /// Label for the average consumption per billing period stat on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Prosječna potrošnja po obračunskom periodu (m³)'**
  String get averageConsumptionLabel;

  /// Label for the total consumption stat on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Ukupno potrošeno (m³)'**
  String get totalConsumptionLabel;

  /// Value for the total consumption stat: the already-formatted m3 figure plus the invoice count it was computed from.
  ///
  /// In bs, this message translates to:
  /// **'{m3} m³ ({invoiceCount} računa)'**
  String totalConsumptionValue(String m3, int invoiceCount);

  /// Label for the unpaid-invoices stat on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Neplaćeno'**
  String get unpaidLabel;

  /// Value for the unpaid-invoices stat: unpaid invoice count and the already-formatted unpaid amount.
  ///
  /// In bs, this message translates to:
  /// **'{count} računa / {amount} KM'**
  String unpaidValue(int count, String amount);

  /// Label for the last billing period stat on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Zadnji obračunski period'**
  String get lastBillingPeriodLabel;

  /// Section heading for the consumption chart card on the water meter detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Potrošnja po periodima'**
  String get consumptionByPeriodHeading;

  /// Message shown in the consumption chart card when there is no consumption data to plot.
  ///
  /// In bs, this message translates to:
  /// **'Nema podataka o potrošnji.'**
  String get noConsumptionDataMessage;

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

  /// Display label for the 'Pending' water meter request status.
  ///
  /// In bs, this message translates to:
  /// **'Na čekanju'**
  String get requestStatusPending;

  /// Display label for the 'Assigned' water meter request status.
  ///
  /// In bs, this message translates to:
  /// **'Dodijeljen'**
  String get requestStatusAssigned;

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

  /// App bar title for the invoices list screen when not scoped to a single water meter.
  ///
  /// In bs, this message translates to:
  /// **'Računi'**
  String get invoicesTitle;

  /// App bar title for the invoices list screen when scoped to one water meter's invoices.
  ///
  /// In bs, this message translates to:
  /// **'Računi - {serial}'**
  String invoicesTitleForMeter(String serial);

  /// Empty-state message shown when the customer has no invoices at all.
  ///
  /// In bs, this message translates to:
  /// **'Nemate izdatih računa.'**
  String get invoicesEmptyMessage;

  /// Empty-state message shown when a water meter has no invoices yet.
  ///
  /// In bs, this message translates to:
  /// **'Za ovaj vodomjer još nema izdatih računa.'**
  String get invoicesEmptyForMeterMessage;

  /// Inline remaining-amount value shown on a payable invoice's summary card, with the already-formatted amount. The KM currency suffix is not translated - this app is BAM/KM-only regardless of UI language.
  ///
  /// In bs, this message translates to:
  /// **'Preostalo: {amount} KM'**
  String invoiceRemainingAmountLabel(String amount);

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

  /// Tooltip for the 'all invoices' icon button on the invoice detail screen's app bar.
  ///
  /// In bs, this message translates to:
  /// **'Svi računi'**
  String get allInvoicesTooltip;

  /// Eyebrow label above the status name on the invoice detail screen's status banner, shown uppercased.
  ///
  /// In bs, this message translates to:
  /// **'Status računa'**
  String get invoiceStatusFieldLabel;

  /// Button label for paying an invoice, used both on the invoice detail screen and in its payment confirmation dialog.
  ///
  /// In bs, this message translates to:
  /// **'Plati'**
  String get payButton;

  /// Title of the confirmation dialog shown before paying an invoice.
  ///
  /// In bs, this message translates to:
  /// **'Potvrda plaćanja'**
  String get paymentConfirmTitle;

  /// Body of the payment confirmation dialog, with the already-formatted amount. The BAM currency suffix is not translated.
  ///
  /// In bs, this message translates to:
  /// **'Da li ste sigurni da želite platiti {amount} BAM?'**
  String paymentConfirmMessage(String amount);

  /// Snackbar shown when a payment session opens without a Stripe client secret (the Manual provider placeholder flow). currency is the backend-provided currency code, passed through as-is.
  ///
  /// In bs, this message translates to:
  /// **'Plaćanje pokrenuto: {amount} {currency} (status: {statusLabel}).'**
  String paymentStartedMessage(
    String amount,
    String currency,
    String statusLabel,
  );

  /// Snackbar shown after the Stripe payment sheet is presented successfully.
  ///
  /// In bs, this message translates to:
  /// **'Plaćanje u obradi.'**
  String get paymentProcessingMessage;

  /// Error message shown when the customer cancels the Stripe payment sheet.
  ///
  /// In bs, this message translates to:
  /// **'Plaćanje je otkazano.'**
  String get paymentCancelledMessage;

  /// Fallback error message shown when a Stripe payment fails without a specific message from the SDK.
  ///
  /// In bs, this message translates to:
  /// **'Plaćanje nije uspjelo.'**
  String get paymentFailedMessage;

  /// Display label for a 'Completed' payment session status.
  ///
  /// In bs, this message translates to:
  /// **'Završeno'**
  String get paymentStatusCompleted;

  /// Display label for a 'Failed' payment session status.
  ///
  /// In bs, this message translates to:
  /// **'Neuspješno'**
  String get paymentStatusFailed;

  /// Section heading for the readings card on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Očitanja'**
  String get readingsSectionHeading;

  /// Label for the billing period field on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Period'**
  String get periodLabel;

  /// Label for the previous meter reading field on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Prethodno očitanje'**
  String get previousReadingLabel;

  /// Label for the current meter reading field on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Novo očitanje'**
  String get currentReadingLabel;

  /// Label for the consumption field on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Potrošnja'**
  String get consumptionLabel;

  /// Section heading for the amount card on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Iznos'**
  String get amountSectionHeading;

  /// Label for the subtotal field on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Osnovica'**
  String get subtotalLabel;

  /// Label for the total amount field on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Ukupno'**
  String get totalLabel;

  /// Section heading for the payments card on the invoice detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Uplate'**
  String get paymentsSectionHeading;

  /// Empty-state message shown when an invoice has no recorded payments.
  ///
  /// In bs, this message translates to:
  /// **'Nema evidentiranih uplata.'**
  String get paymentsEmptyMessage;

  /// Label for the total-paid field on the invoice detail screen's payments card.
  ///
  /// In bs, this message translates to:
  /// **'Plaćeno ukupno'**
  String get totalPaidLabel;

  /// Label for the remaining-to-pay field on the invoice detail screen's payments card.
  ///
  /// In bs, this message translates to:
  /// **'Preostalo za platiti'**
  String get remainingToPayLabel;

  /// Snackbar message shown after a new fault report is submitted successfully.
  ///
  /// In bs, this message translates to:
  /// **'Prijava kvara je poslana.'**
  String get faultReportSubmitSuccess;

  /// Tooltip for the '+' icon button that opens the new fault report dialog.
  ///
  /// In bs, this message translates to:
  /// **'Nova prijava'**
  String get newFaultReportTooltip;

  /// Empty-state message shown when the customer has no fault reports.
  ///
  /// In bs, this message translates to:
  /// **'Nemate poslanih prijava kvarova.'**
  String get faultReportsEmptyMessage;

  /// Display label for the 'New' fault report status, shared by the report list card and the detail screen's status banner.
  ///
  /// In bs, this message translates to:
  /// **'Nova'**
  String get faultReportStatusNew;

  /// Display label for the 'Assigned' fault report status, shared by the report list card and the detail screen's status banner.
  ///
  /// In bs, this message translates to:
  /// **'Dodijeljena'**
  String get faultReportStatusAssigned;

  /// Display label for the 'InProgress' fault report status, shared by the report list card and the detail screen's status banner.
  ///
  /// In bs, this message translates to:
  /// **'U toku'**
  String get faultReportStatusInProgress;

  /// Display label for the 'Resolved' fault report status, shared by the report list card and the detail screen's status banner.
  ///
  /// In bs, this message translates to:
  /// **'Riješena'**
  String get faultReportStatusResolved;

  /// Eyebrow label above the status name on the fault report detail screen's status banner, shown uppercased.
  ///
  /// In bs, this message translates to:
  /// **'Status prijave'**
  String get faultReportStatusFieldLabel;

  /// Section heading for the photos card on the fault report detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Fotografije'**
  String get photosSectionHeading;

  /// Message shown in the photos card when a fault report has no attached photos.
  ///
  /// In bs, this message translates to:
  /// **'Nema priloženih fotografija.'**
  String get noPhotosMessage;

  /// Section heading for the info card on the fault report detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Podaci o prijavi'**
  String get faultReportInfoSectionHeading;

  /// Label for the reported-at date field on the fault report detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Prijavljeno'**
  String get reportedAtLabel;

  /// Label for the resolved-at date field on the fault report detail screen. Distinct from faultReportStatusResolved ('Riješena') which is a different grammatical form used as the status pill label.
  ///
  /// In bs, this message translates to:
  /// **'Riješeno'**
  String get resolvedAtLabel;

  /// Display label for the 'Open' support ticket status, shown by SupportTicketStatusPill.
  ///
  /// In bs, this message translates to:
  /// **'Otvoren'**
  String get supportTicketStatusOpen;

  /// Display label for the 'Closed' support ticket status, shown by SupportTicketStatusPill.
  ///
  /// In bs, this message translates to:
  /// **'Zatvoren'**
  String get supportTicketStatusClosed;

  /// Tooltip for the '+' icon button that opens the new support ticket dialog.
  ///
  /// In bs, this message translates to:
  /// **'Novi tiket'**
  String get newSupportTicketTooltip;

  /// Snackbar message shown after a new support ticket is submitted successfully.
  ///
  /// In bs, this message translates to:
  /// **'Tiket je kreiran.'**
  String get supportTicketCreateSuccess;

  /// Empty-state title shown when the customer has no support tickets.
  ///
  /// In bs, this message translates to:
  /// **'Nemate otvorenih tiketa.'**
  String get supportTicketsEmptyTitle;

  /// Empty-state subtitle shown below supportTicketsEmptyTitle, prompting the customer to open a new ticket.
  ///
  /// In bs, this message translates to:
  /// **'Otvorite novi tiket da kontaktirate podršku.'**
  String get supportTicketsEmptySubtitle;

  /// Inline last-message timestamp shown on a support ticket list card, with the already-formatted date/time.
  ///
  /// In bs, this message translates to:
  /// **'Zadnja poruka: {date}'**
  String supportTicketLastMessageLabel(String date);

  /// Hint text in the reply composer's text field on the support ticket detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Napišite poruku...'**
  String get supportTicketReplyHint;

  /// Snackbar shown when the customer tries to send a reply with no text (photos alone aren't enough, the backend requires a message body).
  ///
  /// In bs, this message translates to:
  /// **'Unesite tekst poruke.'**
  String get supportTicketReplyRequiredError;

  /// Fallback AppBar title on the support ticket detail screen while the ticket is loading or has an empty subject.
  ///
  /// In bs, this message translates to:
  /// **'Tiket'**
  String get supportTicketDefaultTitle;

  /// Message shown in the thread body when a support ticket has no messages yet.
  ///
  /// In bs, this message translates to:
  /// **'Nema poruka.'**
  String get supportTicketNoMessages;

  /// Ticket-created-at date shown in the status header on the support ticket detail screen, with the already-formatted date/time.
  ///
  /// In bs, this message translates to:
  /// **'Otvoren: {date}'**
  String supportTicketOpenedAtLabel(String date);

  /// Sender label shown above the customer's own chat bubbles on the support ticket detail screen.
  ///
  /// In bs, this message translates to:
  /// **'Vi'**
  String get supportTicketYouLabel;

  /// Banner shown instead of the reply composer once a support ticket is closed.
  ///
  /// In bs, this message translates to:
  /// **'Tiket je zatvoren'**
  String get supportTicketClosedBanner;
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
