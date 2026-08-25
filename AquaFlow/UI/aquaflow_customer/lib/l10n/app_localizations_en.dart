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
  String get commonSend => 'Send';

  @override
  String get commonAddPhoto => 'Add photo';

  @override
  String get commonTakePhoto => 'Take photo';

  @override
  String get commonChooseFromGallery => 'From gallery';

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
  String get addWaterMeterTooltip => 'Add water meter';

  @override
  String get waterMetersEmptyMessage =>
      'You currently have no registered water meters.';

  @override
  String lastReadingLabel(String value) {
    return 'Last reading: $value m³';
  }

  @override
  String get newWaterMeterRequestSuccess => 'New water meter request sent.';

  @override
  String get requestsTitle => 'Requests';

  @override
  String get newRequestTooltip => 'New request';

  @override
  String get cancelRequestConfirmTitle => 'Cancel request?';

  @override
  String cancelRequestConfirmMessage(int id) {
    return 'The new water meter request #$id will be cancelled.';
  }

  @override
  String get cancelRequestButton => 'Cancel request';

  @override
  String get cancelRequestSuccess => 'Request cancelled.';

  @override
  String requestCardTitle(int id) {
    return 'Request #$id';
  }

  @override
  String get requestsEmptyMessage =>
      'You have no submitted water meter requests.';

  @override
  String get newWaterMeterRequestTitle => 'New water meter request';

  @override
  String get newWaterMeterRequestSubmitButton => 'Submit request';

  @override
  String get newWaterMeterRequestNoteLabel => 'Note (optional)';

  @override
  String get settlementRequiredError => 'Select a settlement.';

  @override
  String get showInvoicesButton => 'Show invoices';

  @override
  String get meterInfoSectionHeading => 'Meter information';

  @override
  String get addressLabel => 'Address';

  @override
  String get installedAtLabel => 'Installation date';

  @override
  String get initialReadingLabel => 'Initial reading';

  @override
  String get lastReadingFieldLabel => 'Last reading';

  @override
  String get lastReadingM3Label => 'Last reading (m³)';

  @override
  String get statisticsSectionHeading => 'Statistics';

  @override
  String get averageConsumptionLabel =>
      'Average consumption per billing period (m³)';

  @override
  String get totalConsumptionLabel => 'Total consumption (m³)';

  @override
  String totalConsumptionValue(String m3, int invoiceCount) {
    return '$m3 m³ ($invoiceCount invoices)';
  }

  @override
  String get unpaidLabel => 'Unpaid';

  @override
  String unpaidValue(int count, String amount) {
    return '$count invoices / $amount KM';
  }

  @override
  String get lastBillingPeriodLabel => 'Last billing period';

  @override
  String get consumptionByPeriodHeading => 'Consumption by period';

  @override
  String get noConsumptionDataMessage => 'No consumption data.';

  @override
  String get waterMeterStatusActive => 'Active';

  @override
  String get waterMeterStatusInactive => 'Inactive';

  @override
  String get waterMeterStatusRemoved => 'Removed';

  @override
  String get requestStatusPending => 'Pending';

  @override
  String get requestStatusAssigned => 'Assigned';

  @override
  String get requestStatusRegistered => 'Registered';

  @override
  String get requestStatusRejected => 'Rejected';

  @override
  String get requestStatusCancelled => 'Cancelled';

  @override
  String get invoicesTitle => 'Invoices';

  @override
  String invoicesTitleForMeter(String serial) {
    return 'Invoices - $serial';
  }

  @override
  String get invoicesEmptyMessage => 'You have no issued invoices.';

  @override
  String get invoicesEmptyForMeterMessage =>
      'No invoices have been issued for this meter yet.';

  @override
  String invoiceRemainingAmountLabel(String amount) {
    return 'Remaining: $amount KM';
  }

  @override
  String get invoiceStatusIssued => 'Issued';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusCancelled => 'Cancelled';

  @override
  String get allInvoicesTooltip => 'All invoices';

  @override
  String get invoiceStatusFieldLabel => 'Invoice status';

  @override
  String get payButton => 'Pay';

  @override
  String get paymentConfirmTitle => 'Payment confirmation';

  @override
  String paymentConfirmMessage(String amount) {
    return 'Are you sure you want to pay $amount BAM?';
  }

  @override
  String paymentStartedMessage(
    String amount,
    String currency,
    String statusLabel,
  ) {
    return 'Payment started: $amount $currency (status: $statusLabel).';
  }

  @override
  String get paymentProcessingMessage => 'Payment processing.';

  @override
  String get paymentCancelledMessage => 'Payment cancelled.';

  @override
  String get paymentFailedMessage => 'Payment failed.';

  @override
  String get paymentStatusCompleted => 'Completed';

  @override
  String get paymentStatusFailed => 'Failed';

  @override
  String get readingsSectionHeading => 'Readings';

  @override
  String get periodLabel => 'Period';

  @override
  String get previousReadingLabel => 'Previous reading';

  @override
  String get currentReadingLabel => 'Current reading';

  @override
  String get consumptionLabel => 'Consumption';

  @override
  String get amountSectionHeading => 'Amount';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get totalLabel => 'Total';

  @override
  String get paymentsSectionHeading => 'Payments';

  @override
  String get paymentsEmptyMessage => 'No recorded payments.';

  @override
  String get totalPaidLabel => 'Total paid';

  @override
  String get remainingToPayLabel => 'Remaining to pay';

  @override
  String get faultReportSubmitSuccess => 'Fault report submitted.';

  @override
  String get newFaultReportTooltip => 'New report';

  @override
  String get faultReportsEmptyMessage => 'You have no submitted fault reports.';

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
  String get supportTicketStatusOpen => 'Open';

  @override
  String get supportTicketStatusClosed => 'Closed';

  @override
  String get newSupportTicketTooltip => 'New ticket';

  @override
  String get supportTicketCreateSuccess => 'Ticket created.';

  @override
  String get supportTicketsEmptyTitle => 'You have no open tickets.';

  @override
  String get supportTicketsEmptySubtitle =>
      'Open a new ticket to contact support.';

  @override
  String supportTicketLastMessageLabel(String date) {
    return 'Last message: $date';
  }

  @override
  String get supportTicketReplyHint => 'Write a message...';

  @override
  String get supportTicketReplyRequiredError => 'Enter a message.';

  @override
  String get supportTicketDefaultTitle => 'Ticket';

  @override
  String get supportTicketNoMessages => 'No messages.';

  @override
  String supportTicketOpenedAtLabel(String date) {
    return 'Opened: $date';
  }

  @override
  String get supportTicketYouLabel => 'You';

  @override
  String get supportTicketClosedBanner => 'This ticket is closed';
}
