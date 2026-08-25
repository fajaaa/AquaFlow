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
  String get commonLogout => 'Log out';

  @override
  String get unknownRoleTitle => 'Unknown role';

  @override
  String get unknownRoleMessage =>
      'Your account doesn\'t have a supported role for this app. Contact your administrator.';

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
  String get companySettingsScreenTitle => 'Company settings';

  @override
  String get companyNameLabel => 'Company name';

  @override
  String get taxNumberLabel => 'Tax number';

  @override
  String get bankAccountLabel => 'Bank account';

  @override
  String get logoUrlOptionalLabel => 'Logo URL (optional)';

  @override
  String get defaultLanguageLabel => 'Language';

  @override
  String get defaultCurrencyLabel => 'Currency';

  @override
  String get companySettingsSaveSuccess => 'Company settings saved.';

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
  String get mobileShellThemeTooltip => 'Change theme';

  @override
  String get mobileShellLogoutTooltip => 'Log out';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabWaterMeters => 'Water meters';

  @override
  String get tabWaterMeterRequests => 'Orders';

  @override
  String get tabAccount => 'Account';

  @override
  String get notLoggedInError => 'Not logged in.';

  @override
  String get notificationsMarkAllReadTooltip => 'Mark all as read';

  @override
  String get notificationTypeFieldLabel => 'Notification type';

  @override
  String get notificationsAllTypesOption => 'All types';

  @override
  String get notificationTypeInfoLabel => 'Info';

  @override
  String get notificationTypePlannedWorksLabel => 'Planned works';

  @override
  String get notificationTypeWarningLabel => 'Warning';

  @override
  String get notificationTypeGenericLabel => 'Notification';

  @override
  String notificationFallbackTitle(int id) {
    return 'Notification #$id';
  }

  @override
  String get notificationsEmptyMessage => 'No notifications.';

  @override
  String get notificationsEmptyFilteredMessage =>
      'No notifications for the selected type.';

  @override
  String get notificationDetailTitle => 'Notification details';

  @override
  String get notificationDetailDescriptionHeading => 'Description';

  @override
  String get notificationDetailEmptyBody => 'No additional content.';

  @override
  String get notificationDetailDetailsHeading => 'Details';

  @override
  String get notificationDetailCreatedAtLabel => 'Date created';

  @override
  String notificationDetailImagesHeading(int count) {
    return 'Images ($count)';
  }

  @override
  String get notificationStatusRead => 'Read';

  @override
  String get notificationStatusUnread => 'New';

  @override
  String get activityLogEmptyMessage => 'No recorded activity.';

  @override
  String get activityTypeLoginSuccess => 'Successful login';

  @override
  String get activityTypeLoginFailed => 'Failed login';

  @override
  String get activityTypeTokenRefreshed => 'Session refresh';

  @override
  String get activityTypePasswordChanged => 'Password changed';

  @override
  String get activityTypeAccountUpdated => 'Account updated';

  @override
  String get activityTypeUserRoleChanged => 'Role changed';

  @override
  String get activityTypeUserActivated => 'User activated';

  @override
  String get activityTypeUserDeactivated => 'User deactivated';

  @override
  String get activityTypeUserDeleted => 'User deleted';

  @override
  String get activityTypeGenericLabel => 'Activity';

  @override
  String get dialogDismissButton => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClear => 'Clear';

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
  String get locationNameRequiredError =>
      'Enter your first and last name in \"Personal details\" to save the address.';

  @override
  String get locationSaveSuccess => 'Location saved.';

  @override
  String get settlementRequiredError => 'Select a settlement.';

  @override
  String requestCardTitle(int id) {
    return 'Request #$id';
  }

  @override
  String get requestStatusAssigned => 'Assigned';

  @override
  String get initialReadingLabel => 'Initial reading';

  @override
  String get consumptionLabel => 'Consumption';

  @override
  String get totalLabel => 'Total';

  @override
  String get waterMeterStatusActive => 'Active';

  @override
  String get waterMeterStatusInactive => 'Inactive';

  @override
  String get waterMeterStatusRemoved => 'Removed';

  @override
  String get meterInfoSectionHeading => 'Meter information';

  @override
  String get lastReadingStateLabel => 'Last reading';

  @override
  String get faultReportsTooltip => 'Fault reports';

  @override
  String get collectorMeterSearchHint =>
      'Owner name, settlement, serial number, or address';

  @override
  String collectorMetersEmptyMessage(String term) {
    return 'No water meters for \"$term\".';
  }

  @override
  String collectorLastReadingLabel(String value) {
    return 'Last reading: $value m³';
  }

  @override
  String get collectorMetersPromptMessage =>
      'Enter the owner name, settlement, serial number, or address.';

  @override
  String get waterMeterRequestsScreenTitle => 'Work orders';

  @override
  String get waterMeterRequestsEmptyMessage =>
      'No requests assigned right now.';

  @override
  String get meterRegisteredSuccess => 'Water meter registered.';

  @override
  String customerFallbackLabel(int id) {
    return 'Customer #$id';
  }

  @override
  String get phoneNotAvailableLabel => 'Phone number not available';

  @override
  String createdAtInlineLabel(String date) {
    return 'Created: $date';
  }

  @override
  String get callButton => 'Call';

  @override
  String get actionNotSupportedError =>
      'This action isn\'t supported on this device.';

  @override
  String get registerWaterMeterTitle => 'Register water meter';

  @override
  String get registerButton => 'Register';

  @override
  String get serialNumberLabel => 'Serial number';

  @override
  String get installedAtFieldLabel => 'Installation date';

  @override
  String get pickDateTooltip => 'Pick a date';

  @override
  String get positiveNumberRequiredError => 'Enter a positive number.';

  @override
  String get markBrokenTooltip => 'Mark as faulty';

  @override
  String nextReadingAllowedLabel(String date) {
    return 'Next reading possible from: $date';
  }

  @override
  String get newReadingSectionHeading => 'New reading';

  @override
  String get newReadingFieldLabel => 'New reading (m³)';

  @override
  String get tariffLabel => 'Tariff';

  @override
  String get tariffsLoadingHint => 'Loading tariffs...';

  @override
  String get tariffsEmptyHint => 'No active tariffs';

  @override
  String get tariffSelectHint => 'Select a tariff';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get photoUrlOptionalLabel => 'Photo (URL, optional)';

  @override
  String get submitReadingButton => 'Save reading';

  @override
  String readingSubmittedWithInvoiceSuccess(
    String consumption,
    String invoiceNumber,
    String total,
  ) {
    return 'Reading saved. Consumption: $consumption m³. Invoice $invoiceNumber: $total BAM.';
  }

  @override
  String readingSubmittedNoInvoiceSuccess(String consumption) {
    return 'Reading saved. Consumption: $consumption m³. No invoice created (consumption is 0).';
  }

  @override
  String get meterMarkedBrokenSuccess => 'Water meter marked as faulty.';

  @override
  String markBrokenDialogTitle(String serialNumber) {
    return 'Mark water meter $serialNumber as faulty';
  }

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonRequiredError => 'Reason is required.';

  @override
  String get priceSummaryHeading => 'Price summary';

  @override
  String get pricePerM3Label => 'Price per m³';

  @override
  String get faultReportStatusNew => 'New';

  @override
  String get faultReportStatusAssigned => 'Assigned';

  @override
  String get faultReportStatusInProgress => 'In progress';

  @override
  String get faultReportStatusResolved => 'Resolved';

  @override
  String get faultReportStatusFieldLabel => 'Report status';

  @override
  String get photosSectionHeading => 'Photos';

  @override
  String get noPhotosMessage => 'No photos attached.';

  @override
  String get faultReportInfoSectionHeading => 'Report information';

  @override
  String get reportedAtLabel => 'Reported';

  @override
  String get resolvedAtLabel => 'Resolved';

  @override
  String get addressLabel => 'Address';

  @override
  String get customerLabel => 'Customer';

  @override
  String get faultReportsScreenTitle => 'Fault reports';

  @override
  String get faultReportSearchHint => 'Title or customer name';

  @override
  String get collectorFaultReportsEmptyMessage => 'No fault reports.';

  @override
  String reportedAtInlineLabel(String date) {
    return 'Reported: $date';
  }

  @override
  String get allStatusesOption => 'All statuses';

  @override
  String get statusChangeDialogTitle => 'Status change';

  @override
  String statusChangeDialogContent(String status) {
    return 'Set the report status to \"$status\"?';
  }

  @override
  String get startActionButton => 'Start';

  @override
  String get resolveActionButton => 'Resolve';
}
