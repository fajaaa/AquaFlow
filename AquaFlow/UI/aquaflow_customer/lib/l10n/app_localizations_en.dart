// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AquaFlow';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonRetry => 'Try again';

  @override
  String get stateLoading => 'Loading...';

  @override
  String get errorGeneric => 'Error';

  @override
  String get emptyGeneric => 'No data';

  @override
  String get emptyList => 'Empty list';

  @override
  String get paginationPrevious => 'Previous page';

  @override
  String get paginationNext => 'Next page';

  @override
  String paginationPageOf(int page, int totalPages) {
    return 'Page $page of $totalPages';
  }

  @override
  String paginationTotalCount(int count) {
    return '$count total';
  }

  @override
  String get commonSaving => 'Saving...';

  @override
  String get welcomeTagline => 'Every drop, recorded.';

  @override
  String get welcomeSubtitle =>
      'Small steps in saving water make big waves of change.';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authRegisterButton => 'Register';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginFailedError => 'Login failed.';

  @override
  String get registerTitle => 'Registration';

  @override
  String get firstNameRequiredError => 'First name is required.';

  @override
  String get lastNameRequiredError => 'Last name is required.';

  @override
  String get phoneInvalidError =>
      'Phone may only contain digits and the symbols + - ( ).';

  @override
  String get fieldConfirmPasswordLabel => 'Confirm password';

  @override
  String get registerThemeLabel => 'Theme';

  @override
  String get registrationFailedError => 'Registration failed.';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get fieldPhoneLabel => 'Phone';

  @override
  String get fieldFirstNameLabel => 'First name';

  @override
  String get fieldLastNameLabel => 'Last name';

  @override
  String get fieldPasswordLabel => 'Password';

  @override
  String get emailRequiredError => 'Email is required.';

  @override
  String get emailInvalidError => 'Enter a valid email.';

  @override
  String get passwordRequiredError => 'Password is required.';

  @override
  String get passwordTooShortError => 'Password must be at least 6 characters.';

  @override
  String get passwordMismatchError => 'Passwords do not match.';

  @override
  String get fieldRequiredError => 'Required field.';

  @override
  String get themeLightOption => 'Light';

  @override
  String get themeDarkOption => 'Dark';

  @override
  String get passwordResetTitle => 'Change password';

  @override
  String get passwordResetDescription =>
      'Enter your current and new password to change it.';

  @override
  String get passwordResetCurrentLabel => 'Current password';

  @override
  String get passwordResetNewLabel => 'New password';

  @override
  String get passwordResetConfirmLabel => 'Confirm new password';

  @override
  String get passwordResetSubmitButton => 'Change password';

  @override
  String get passwordResetSuccess => 'Password changed.';

  @override
  String get passwordResetCurrentRequiredError =>
      'Enter your current password.';

  @override
  String get passwordResetNewRequiredError => 'Enter your new password.';

  @override
  String get personalDetailsTitle => 'Personal details';

  @override
  String themeSaveFailedError(String message) {
    return 'Theme not saved: $message';
  }

  @override
  String languageSaveFailedError(String message) {
    return 'Language not saved: $message';
  }

  @override
  String get personalDetailsSaveSuccess => 'Personal details saved.';

  @override
  String get personalDetailsNameSectionTitle => 'First and last name';

  @override
  String get personalDetailsAppearanceSectionTitle => 'Appearance';

  @override
  String get nameRequiredTogetherError =>
      'Required if entering first and last name.';

  @override
  String get accountDataSectionTitle => 'Account details';

  @override
  String get accountPersonalDetailsSubtitle =>
      'First name, last name, email, phone and theme';

  @override
  String get locationTitle => 'Location';

  @override
  String get accountLocationSubtitle => 'Home address';

  @override
  String get accountPasswordSubtitle => 'Update account password';

  @override
  String get accountActivityLogTitle => 'My activity';

  @override
  String get accountActivityLogSubtitle =>
      'History of logins and account changes';

  @override
  String get accountCompanySettingsTitle => 'Company settings';

  @override
  String get accountCompanySettingsSubtitle => 'Manage company details';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCollector => 'Collector';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get locationNameRequiredError =>
      'Enter your first and last name in \"Personal details\" to save the address.';

  @override
  String get locationSaveSuccess => 'Location saved.';

  @override
  String get locationCityLabel => 'City';

  @override
  String get locationNoCityOption => 'No city';

  @override
  String get locationMunicipalityLabel => 'Municipality';

  @override
  String get locationNoMunicipalityOption => 'No municipality';

  @override
  String get locationSettlementLabel => 'Settlement';

  @override
  String get locationNoSettlementOption => 'No settlement';

  @override
  String get locationStreetLabel => 'Street';

  @override
  String get locationHouseNumberLabel => 'House number';

  @override
  String get mobileShellThemeTooltip => 'Change theme';

  @override
  String get mobileShellLogoutTooltip => 'Log out';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabWaterMeters => 'Water meters';

  @override
  String get tabFaultReports => 'Fault reports';

  @override
  String get tabAccount => 'Account';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportSubtitle => 'Your support tickets and messages';
}
