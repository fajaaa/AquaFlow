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
  String get desktopUnavailableTitle => 'Unavailable on desktop';

  @override
  String get desktopUnavailableMessage =>
      'The desktop app is intended for administrators only. Use the mobile app for your role.';

  @override
  String get stateLoading => 'Loading...';

  @override
  String get errorGeneric => 'Error';

  @override
  String get emptyGeneric => 'No data';

  @override
  String sectionNotImplementedMessage(String label) {
    return 'The \"$label\" section isn\'t implemented yet.';
  }

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
  String get loginTitle => 'Login';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get emailRequiredError => 'Email is required.';

  @override
  String get emailInvalidError => 'Enter a valid email.';

  @override
  String get fieldPasswordLabel => 'Password';

  @override
  String get passwordRequiredError => 'Password is required.';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get welcomeTagline => 'Every drop, recorded.';

  @override
  String get welcomeSubtitle =>
      'Small steps in saving water make big waves of change.';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get loginFailedError => 'Login failed.';

  @override
  String get registerTitle => 'Registration';

  @override
  String get fieldFirstNameLabel => 'First name';

  @override
  String get firstNameRequiredError => 'First name is required.';

  @override
  String get fieldLastNameLabel => 'Last name';

  @override
  String get lastNameRequiredError => 'Last name is required.';

  @override
  String get fieldPhoneLabel => 'Phone';

  @override
  String get phoneInvalidError =>
      'Phone may only contain digits and the symbols + - ( ).';

  @override
  String get passwordTooShortError => 'Password must be at least 6 characters.';

  @override
  String get fieldConfirmPasswordLabel => 'Confirm password';

  @override
  String get passwordMismatchError => 'Passwords do not match.';

  @override
  String get registerThemeLabel => 'Theme';

  @override
  String get themeLightOption => 'Light';

  @override
  String get themeDarkOption => 'Dark';

  @override
  String get authRegisterButton => 'Register';

  @override
  String get registrationFailedError => 'Registration failed.';

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
  String get fieldRequiredError => 'Required field.';

  @override
  String get notLoggedInError => 'Not logged in.';

  @override
  String themeSaveFailedError(String message) {
    return 'Theme not saved: $message';
  }

  @override
  String languageSaveFailedError(String message) {
    return 'Language not saved: $message';
  }

  @override
  String get personalDetailsAppearanceSectionTitle => 'Appearance';

  @override
  String get nameRequiredTogetherError =>
      'Required if entering first and last name.';

  @override
  String get dialogDismissButton => 'Cancel';

  @override
  String get addressLabel => 'Address';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get faultReportsScreenTitle => 'Fault reports';

  @override
  String get logoutLabel => 'Log out';

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
  String get myAccountTitle => 'My account';

  @override
  String get myAccountSubtitle =>
      'Edit your details, app appearance, and password.';

  @override
  String get profileSectionLabel => 'Profile';

  @override
  String get contactSectionLabel => 'Contact';

  @override
  String get passwordOptionalHint =>
      'Leave blank if you\'re not changing your password.';

  @override
  String get phoneInvalidNumberError => 'Enter a valid phone number.';

  @override
  String get accountDetailsSaveSuccess => 'Account details saved.';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get usersLabel => 'Users';

  @override
  String get collectorsNavLabel => 'Collectors';

  @override
  String get administratorsLabel => 'Administrators';

  @override
  String get financeGroupLabel => 'Finance';

  @override
  String get invoicesLabel => 'Invoices';

  @override
  String get paymentsLabel => 'Payments';

  @override
  String get tariffsNavLabel => 'Tariffs';

  @override
  String get supportGroupLabel => 'Support';

  @override
  String get waterMeterRequestsNavLabel => 'Requests';

  @override
  String get systemGroupLabel => 'System';

  @override
  String get codebookLabel => 'Codebook';

  @override
  String get dashboardOverviewSubtitle => 'Overview of key metrics (demo data)';

  @override
  String get lineChartTitle => 'Line chart';

  @override
  String get donutChartTitle => 'Donut chart';

  @override
  String get barChartTitle => 'Bar chart';

  @override
  String get seriesALabel => 'Series A';

  @override
  String get seriesBLabel => 'Series B';

  @override
  String get statusFieldLabel => 'Status';

  @override
  String get allOption => 'All';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get fullNameColumnLabel => 'Full name';

  @override
  String get createdColumnLabel => 'Created';

  @override
  String get actionsColumnLabel => 'Actions';

  @override
  String get activitiesTooltip => 'Activities';

  @override
  String get accountSectionLabel => 'Account';

  @override
  String get newPasswordOptionalLabel =>
      'New password (leave blank to keep current)';

  @override
  String get commonClose => 'Close';

  @override
  String get waterMeterStatusRemoved => 'Removed';

  @override
  String get initialReadingLabel => 'Initial reading';

  @override
  String get usersScreenSubtitle =>
      'View, add, edit, and delete customer accounts.';

  @override
  String get administratorsScreenSubtitle =>
      'View, add, edit, and delete administrator accounts.';

  @override
  String get newUserButtonLabel => 'New customer';

  @override
  String get newAdministratorButtonLabel => 'New administrator';

  @override
  String get editUserDialogTitle => 'Edit customer';

  @override
  String get editAdministratorDialogTitle => 'Edit administrator';

  @override
  String get userCreatedSuccess => 'Customer added.';

  @override
  String get administratorCreatedSuccess => 'Administrator added.';

  @override
  String get userSavedSuccess => 'Customer saved.';

  @override
  String get administratorSavedSuccess => 'Administrator saved.';

  @override
  String get deleteUserDialogTitle => 'Delete customer';

  @override
  String get deleteAdministratorDialogTitle => 'Delete administrator';

  @override
  String deleteUserDialogContent(String email) {
    return 'Are you sure you want to delete the customer \"$email\"? This action cannot be undone.';
  }

  @override
  String deleteAdministratorDialogContent(String email) {
    return 'Are you sure you want to delete the administrator \"$email\"? This action cannot be undone.';
  }

  @override
  String get userDeletedSuccess => 'Customer deleted.';

  @override
  String get administratorDeletedSuccess => 'Administrator deleted.';

  @override
  String get usersEmptyMessage => 'No customers.';

  @override
  String get administratorsEmptyMessage => 'No administrators.';

  @override
  String get usersEmptyFilteredMessage =>
      'No customers match the selected filters.';

  @override
  String get administratorsEmptyFilteredMessage =>
      'No administrators match the selected filters.';

  @override
  String get nameSearchHint => 'First or last name';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get applyFiltersTooltip => 'Apply filters';

  @override
  String get rolesNotLoadedError =>
      'Roles could not be loaded. Please try again.';

  @override
  String roleNotFoundError(String roleName) {
    return 'Role \"$roleName\" was not found.';
  }

  @override
  String get waterMetersTooltip => 'Water meters';

  @override
  String get cannotDeleteOwnAccountError =>
      'You cannot delete your own account.';

  @override
  String get customerCodeFieldLabel => 'Customer code (auto-assigned)';

  @override
  String get cannotDeactivateOwnAccountError =>
      'You cannot deactivate your own account.';

  @override
  String get nameRequiredForAddressError =>
      'Enter a first and last name to save the address.';

  @override
  String get collectorsScreenSubtitle =>
      'View and edit field-work collector profiles.';

  @override
  String get addCollectorButtonLabel => 'Add collector';

  @override
  String get collectorCreatedSuccess => 'Collector added.';

  @override
  String get collectorProfileSavedSuccess => 'Collector profile saved.';

  @override
  String get collectorsEmptyMessage => 'No collector profiles.';

  @override
  String get collectorCodeColumnLabel => 'Collector code';

  @override
  String get editProfileTooltip => 'Edit profile';

  @override
  String get collectorCodeGeneratedHint =>
      'The collector code is generated automatically after saving, e.g. COL-0002.';

  @override
  String get editCollectorProfileDialogTitle => 'Edit collector profile';

  @override
  String get collectorCodeFieldLabel => 'Collector code (auto-assigned)';

  @override
  String activityLogTitle(String displayName) {
    return 'Activities - $displayName';
  }

  @override
  String get eventTypeFieldLabel => 'Event';

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
  String get userNoActivityMessage => 'This user has no recorded activity.';

  @override
  String get activitiesEmptyFilteredMessage =>
      'No activity matches the selected filters.';

  @override
  String get descriptionColumnLabel => 'Description';

  @override
  String get ipAddressColumnLabel => 'IP address';

  @override
  String get timeColumnLabel => 'Time';

  @override
  String waterMetersTitle(String displayName) {
    return 'Water meters - $displayName';
  }

  @override
  String get userNoProfileMessage =>
      'This user has no profile, so no water meters either.';

  @override
  String get userNoWaterMetersMessage =>
      'This user currently has no recorded water meters.';

  @override
  String get installedLabel => 'Installed';

  @override
  String get lastReadingLabel => 'Last reading';

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
  String get codebookSubtitle =>
      'Administrative location codebook: cities, municipalities, and settlements.';

  @override
  String get backTooltip => 'Back';

  @override
  String get citiesLabel => 'Cities';

  @override
  String get openTooltip => 'Open';

  @override
  String get citiesScreenSubtitle => 'View, add, edit, and delete cities.';

  @override
  String get newCityButtonLabel => 'New city';

  @override
  String get cityCreatedSuccess => 'City added.';

  @override
  String get citySavedSuccess => 'City saved.';

  @override
  String get deleteCityDialogTitle => 'Delete city';

  @override
  String deleteCityDialogContent(String name) {
    return 'Are you sure you want to delete the city \"$name\"? This action cannot be undone.';
  }

  @override
  String get cityDeletedSuccess => 'City deleted.';

  @override
  String get citySearchHint => 'City name';

  @override
  String get citiesEmptyMessage => 'No cities.';

  @override
  String get citiesEmptyFilteredMessage => 'No cities match the search.';

  @override
  String get nameColumnLabel => 'Name';

  @override
  String get codeColumnLabel => 'Code';

  @override
  String get editCityDialogTitle => 'Edit city';

  @override
  String municipalitiesTitle(String cityName) {
    return 'Municipalities · $cityName';
  }

  @override
  String get municipalitiesScreenSubtitle =>
      'View, add, edit, and delete municipalities.';

  @override
  String get newMunicipalityButtonLabel => 'New municipality';

  @override
  String get municipalityCreatedSuccess => 'Municipality added.';

  @override
  String get municipalitySavedSuccess => 'Municipality saved.';

  @override
  String get deleteMunicipalityDialogTitle => 'Delete municipality';

  @override
  String deleteMunicipalityDialogContent(String name) {
    return 'Are you sure you want to delete the municipality \"$name\"? This action cannot be undone.';
  }

  @override
  String get municipalityDeletedSuccess => 'Municipality deleted.';

  @override
  String get municipalitySearchHint => 'Municipality name';

  @override
  String cityHasNoMunicipalitiesMessage(String cityName) {
    return 'The city \'$cityName\' has no municipalities yet.';
  }

  @override
  String get municipalitiesEmptyFilteredMessage =>
      'No municipalities match the search.';

  @override
  String get editMunicipalityDialogTitle => 'Edit municipality';

  @override
  String settlementsTitle(String municipalityName) {
    return 'Settlements · $municipalityName';
  }

  @override
  String get settlementsScreenSubtitle =>
      'View, add, edit, and delete settlements.';

  @override
  String get newSettlementButtonLabel => 'New settlement';

  @override
  String get settlementCreatedSuccess => 'Settlement added.';

  @override
  String get settlementSavedSuccess => 'Settlement saved.';

  @override
  String get deleteSettlementDialogTitle => 'Delete settlement';

  @override
  String deleteSettlementDialogContent(String name) {
    return 'Are you sure you want to delete the settlement \"$name\"? This action cannot be undone.';
  }

  @override
  String get settlementDeletedSuccess => 'Settlement deleted.';

  @override
  String get settlementSearchHint => 'Settlement name';

  @override
  String municipalityHasNoSettlementsMessage(String municipalityName) {
    return 'The municipality \'$municipalityName\' has no settlements yet.';
  }

  @override
  String get settlementsEmptyFilteredMessage =>
      'No settlements match the search.';

  @override
  String get postalCodeColumnLabel => 'Postal code';

  @override
  String get editSettlementDialogTitle => 'Edit settlement';

  @override
  String get noCollectorsAvailableError => 'No collectors available.';

  @override
  String get waterMeterRequestsPageTitle => 'Water meter requests';

  @override
  String get waterMeterRequestsPageSubtitle =>
      'View, assign to a collector, and reject requests for a new water meter.';

  @override
  String get allStatusesOption => 'All statuses';

  @override
  String get requestStatusPending => 'Pending';

  @override
  String get requestStatusAwaitingRegistration => 'Awaiting registration';

  @override
  String get requestStatusRegistered => 'Registered';

  @override
  String get requestStatusRejected => 'Rejected';

  @override
  String get requestStatusCancelled => 'Cancelled';

  @override
  String get applyFilterTooltip => 'Apply filter';

  @override
  String get noWaterMeterRequestsMessage => 'No water meter requests.';

  @override
  String get waterMeterRequestsEmptyFilteredMessage =>
      'No requests match the selected status.';

  @override
  String get customerColumnLabel => 'Customer';

  @override
  String get collectorColumnLabel => 'Collector';

  @override
  String collectorFallbackLabel(int id) {
    return 'Collector #$id';
  }

  @override
  String get unknownSettlementLabel => 'Unknown settlement';

  @override
  String get noStreetAddressLabel => 'No street address';

  @override
  String requestCustomerFallbackLabel(int id) {
    return 'Customer #$id';
  }

  @override
  String get noPhoneLabel => 'No phone';

  @override
  String get assignToCollectorTooltip => 'Assign to collector';

  @override
  String get rejectTooltip => 'Reject';

  @override
  String get selectionColumnLabel => 'Selection';

  @override
  String get assignButtonLabel => 'Assign';

  @override
  String collectorProfileFallbackLabel(int id) {
    return 'Profile #$id';
  }

  @override
  String get rejectRequestDialogTitle => 'Reject request';

  @override
  String get reasonOptionalLabel => 'Reason (optional)';

  @override
  String get requestAssignedSuccess => 'Request assigned to collector.';

  @override
  String get requestRejectedSuccess => 'Request rejected.';

  @override
  String get faultReportStatusNew => 'New';

  @override
  String get faultReportStatusAssigned => 'Assigned';

  @override
  String get faultReportStatusInProgress => 'In progress';

  @override
  String get faultReportStatusResolved => 'Resolved';

  @override
  String get changeStatusDialogTitle => 'Change status';

  @override
  String changeStatusDialogContent(String title, String status) {
    return 'Are you sure you want to change the status of report \"$title\" to \"$status\"?';
  }

  @override
  String get changeButtonLabel => 'Change';

  @override
  String get statusChangedSuccess => 'Report status changed.';

  @override
  String get faultReportAssignedSuccess =>
      'Fault report assigned to collector.';

  @override
  String get faultReportsPageSubtitle =>
      'View fault reports and manage their status.';

  @override
  String get faultReportSearchLabel => 'Title, customer, or settlement';

  @override
  String get noFaultReportsMessage => 'No fault reports.';

  @override
  String get faultReportsEmptyFilteredMessage =>
      'No fault reports match the selected filters.';

  @override
  String get titleColumnLabel => 'Title';

  @override
  String get customerLabel => 'Customer';

  @override
  String get collectorNameColumnLabel => 'Collector';

  @override
  String get dateColumnLabel => 'Date';

  @override
  String collectorNumberFallbackLabel(int id) {
    return 'Collector #$id';
  }

  @override
  String get reassignTooltip => 'Reassign to another collector';

  @override
  String get assignmentNoLongerPossibleTooltip =>
      'Assignment is no longer possible';

  @override
  String get reportResolvedTooltip => 'Report is resolved';

  @override
  String changeStatusToTooltip(String status) {
    return 'Change status to \"$status\"';
  }

  @override
  String get noteOptionalFieldLabel => 'Note (optional)';

  @override
  String get assignmentNoteHint =>
      'Reason for the assignment or instructions for the collector';

  @override
  String get reportedAtLabel => 'Reported';

  @override
  String get resolvedAtLabel => 'Resolved';

  @override
  String get photosSectionHeading => 'Photos';

  @override
  String get noPhotosMessage => 'No photos attached.';

  @override
  String meterReadingsTitle(String serialNumber) {
    return 'Readings - $serialNumber';
  }

  @override
  String get noReadingsForMeterMessage =>
      'No readings recorded for this water meter yet.';

  @override
  String get readingDateColumnLabel => 'Reading date';

  @override
  String get previousReadingColumnLabel => 'Previous (m³)';

  @override
  String get newReadingColumnLabel => 'New (m³)';

  @override
  String get consumptionColumnLabel => 'Consumption (m³)';

  @override
  String get syncColumnLabel => 'Sync';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusFailed => 'Failed';

  @override
  String get tariffCreatedSuccess => 'Tariff added.';

  @override
  String get tariffSavedSuccess => 'Tariff saved.';

  @override
  String get tariffDeletedSuccess => 'Tariff deleted.';

  @override
  String get deleteTariffDialogTitle => 'Delete tariff';

  @override
  String deleteTariffDialogContent(String name) {
    return 'Are you sure you want to delete the tariff \"$name\"? Deletion won\'t be possible if the tariff is referenced by invoice line items.';
  }

  @override
  String get tariffsScreenSubtitle => 'View, add, edit, and delete tariffs.';

  @override
  String get newTariffButtonLabel => 'New tariff';

  @override
  String get allOptionFeminine => 'All';

  @override
  String get activeFilterOption => 'Active';

  @override
  String get inactiveFilterOption => 'Inactive';

  @override
  String get noTariffsMessage => 'No tariffs.';

  @override
  String get tariffsEmptyFilteredMessage =>
      'No tariffs match the selected filters.';

  @override
  String get pricePerM3Label => 'Price per m³';

  @override
  String get tariffStatusInactive => 'Inactive';

  @override
  String get tariffStatusActive => 'Active';

  @override
  String get editTariffDialogTitle => 'Edit tariff';

  @override
  String get invalidNumberError => 'Enter a valid number.';

  @override
  String get negativeValueError => 'Value must not be negative.';

  @override
  String get invoiceStatusIssued => 'Issued';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusCancelled => 'Cancelled';

  @override
  String get markAsPaidLabel => 'Mark as paid';

  @override
  String markAsPaidDialogContent(String invoiceNumber, String amount) {
    return 'Are you sure you want to mark invoice \"$invoiceNumber\" as paid ($amount)?';
  }

  @override
  String get invoiceMarkedPaidSuccess => 'Invoice marked as paid.';

  @override
  String get cancelInvoiceDialogTitle => 'Cancel invoice';

  @override
  String cancelInvoiceDialogContent(String invoiceNumber) {
    return 'Are you sure you want to cancel invoice \"$invoiceNumber\"?';
  }

  @override
  String get cancelInvoiceButtonLabel => 'Cancel invoice';

  @override
  String get invoiceCancelledSuccess => 'Invoice cancelled.';

  @override
  String get invoicesScreenSubtitle => 'View invoices and manage their status.';

  @override
  String get invoiceNumberFieldLabel => 'Invoice number';

  @override
  String get monthFilterLabel => 'Month';

  @override
  String get noInvoicesMessage => 'No invoices.';

  @override
  String get invoicesEmptyFilteredMessage =>
      'No invoices match the selected filters.';

  @override
  String get waterMeterColumnLabel => 'Water meter';

  @override
  String get periodColumnLabel => 'Period';

  @override
  String get consumptionM3ColumnLabel => 'Consumption m³';

  @override
  String get amountColumnLabel => 'Amount';

  @override
  String get paymentStatusCompleted => 'Completed';

  @override
  String get paymentsScreenSubtitle =>
      'View recorded payments. Payments are recorded exclusively through the \"Record payment\" action on the Invoices screen.';

  @override
  String get invoiceIdFieldLabel => 'Invoice ID';

  @override
  String get noPaymentsMessage => 'No payments.';

  @override
  String get paymentsEmptyFilteredMessage =>
      'No payments match the selected filters.';

  @override
  String get paymentDateColumnLabel => 'Payment date';

  @override
  String get invoiceColumnLabel => 'Invoice';

  @override
  String get methodColumnLabel => 'Method';

  @override
  String get manualPaymentMethodLabel => 'Manual';

  @override
  String get cannotDetermineAdminUserError =>
      'Could not determine the admin user.';

  @override
  String get notificationCreatedSuccess => 'Notification added.';

  @override
  String get cannotDetermineNotificationAuthorError =>
      'Could not determine the notification\'s author.';

  @override
  String get notificationSavedSuccess => 'Notification saved.';

  @override
  String get deleteNotificationDialogTitle => 'Delete notification';

  @override
  String deleteNotificationDialogContent(String title) {
    return 'Are you sure you want to delete the notification \"$title\"? Related user notification records will also be removed.';
  }

  @override
  String get notificationDeletedSuccess => 'Notification deleted.';

  @override
  String get notificationsScreenSubtitle =>
      'View, add, edit, and delete system notifications.';

  @override
  String get newNotificationButtonLabel => 'New notification';

  @override
  String get notificationSearchHint => 'Title, content, type, or audience';

  @override
  String get typeFieldLabel => 'Type';

  @override
  String get notificationsAllTypesOption => 'All types';

  @override
  String get audienceFieldLabel => 'Audience';

  @override
  String get allAudiencesOption => 'All audiences';

  @override
  String get notificationsEmptyMessage => 'No notifications.';

  @override
  String get notificationsFilteredEmptyMessage =>
      'No notifications match the selected filters.';

  @override
  String get notificationColumnLabel => 'Notification';

  @override
  String get createdAtColumnLabel => 'Created';

  @override
  String notificationFallbackTitle(int id) {
    return 'Notification #$id';
  }

  @override
  String get editNotificationDialogTitle => 'Edit notification';

  @override
  String get contentFieldLabel => 'Content';

  @override
  String imagesCountLabel(int count, int max) {
    return 'Images ($count/$max)';
  }

  @override
  String get addImageButtonLabel => 'Add image';

  @override
  String uploadingImageLabel(int current, int total) {
    return 'Uploading image $current/$total...';
  }

  @override
  String get notificationTypeInfoLabel => 'Info';

  @override
  String get notificationTypePlannedWorksLabel => 'Planned works';

  @override
  String get notificationTypeWarningLabel => 'Warning';

  @override
  String get notificationTypeGenericLabel => 'Notification';

  @override
  String get allUsersAudienceLabel => 'All users';

  @override
  String get customersAudienceLabel => 'Customers';

  @override
  String get settlementAudienceLabel => 'Settlement';

  @override
  String get supportTicketFilterOpen => 'Open';

  @override
  String get supportTicketFilterClosed => 'Closed';

  @override
  String get ticketSubjectSearchHint => 'Ticket subject';

  @override
  String get supportTicketsScreenSubtitle =>
      'All customer support tickets. Tickets highlighted in orange are awaiting a reply - the newest message in the thread isn\'t from support.';

  @override
  String get subjectColumnLabel => 'Subject';

  @override
  String get messagesColumnLabel => 'Messages';

  @override
  String get lastMessageColumnLabel => 'Last message';

  @override
  String ticketFallbackTitle(int id) {
    return 'Ticket #$id';
  }

  @override
  String get noTicketsFilteredMessage =>
      'No tickets match the selected filters.';

  @override
  String get noTicketsMessage => 'No tickets.';

  @override
  String get enterMessageTextError => 'Enter message text.';

  @override
  String get ticketClosedSuccess => 'Ticket closed.';

  @override
  String get ticketReopenedSuccess => 'Ticket reopened.';

  @override
  String get ticketFallbackLabel => 'Ticket';

  @override
  String get reopenTicketButtonLabel => 'Reopen';

  @override
  String get noMessagesMessage => 'No messages.';

  @override
  String get sendButtonLabel => 'Send';

  @override
  String get writeReplyHint => 'Write a reply...';

  @override
  String openedAtLabel(String date) {
    return 'Opened: $date';
  }

  @override
  String get genericCustomerLabel => 'Customer';

  @override
  String get ticketClosedBannerMessage =>
      'This ticket is closed. Reopen it to reply.';

  @override
  String get supportTicketStatusOpen => 'Open';

  @override
  String get supportTicketStatusClosed => 'Closed';

  @override
  String get recommendationsAndAlertsGroupLabel => 'Recommendations & alerts';

  @override
  String get recommendationsNavLabel => 'Recommendations';

  @override
  String get recommendationsScreenSubtitle =>
      'Review consumption-based recommendations and resolve them.';

  @override
  String get refreshRecommendationsButtonLabel => 'Refresh recommendations';

  @override
  String get recommendationsRecomputedSuccess => 'Recommendations refreshed.';

  @override
  String get recommendationsEmptyMessage => 'No recommendations.';

  @override
  String get markAsReadTooltip => 'Mark as read';

  @override
  String get recommendationMarkedReadSuccess =>
      'Recommendation marked as read.';

  @override
  String get deleteRecommendationDialogTitle => 'Delete recommendation';

  @override
  String get deleteRecommendationDialogContent =>
      'Are you sure you want to delete this recommendation?';

  @override
  String get recommendationDeletedSuccess => 'Recommendation deleted.';

  @override
  String get reasonColumnLabel => 'Reason';

  @override
  String get messageColumnLabel => 'Message';

  @override
  String get readStatusLabel => 'Read';

  @override
  String get unreadStatusLabel => 'Unread';

  @override
  String get consumptionAlertsNavLabel => 'Consumption alerts';

  @override
  String get consumptionAlertsScreenSubtitle =>
      'Review water consumption anomaly alerts and resolve them.';

  @override
  String get checkAnomaliesButtonLabel => 'Check anomalies';

  @override
  String get consumptionAlertsRecomputedSuccess =>
      'Consumption anomalies checked.';

  @override
  String get consumptionAlertsEmptyMessage => 'No consumption alerts.';

  @override
  String get markAsResolvedTooltip => 'Mark as resolved';

  @override
  String get alertMarkedResolvedSuccess => 'Alert marked as resolved.';

  @override
  String get measuredValueColumnLabel => 'Measured value';

  @override
  String get thresholdValueColumnLabel => 'Threshold value';

  @override
  String get resolvedStatusLabel => 'Resolved';

  @override
  String get unresolvedStatusLabel => 'Unresolved';
}
