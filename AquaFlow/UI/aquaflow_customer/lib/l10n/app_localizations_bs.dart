// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bosnian (`bs`).
class AppLocalizationsBs extends AppLocalizations {
  AppLocalizationsBs([String locale = 'bs']) : super(locale);

  @override
  String get appTitle => 'AquaFlow';

  @override
  String get commonSave => 'Sačuvaj';

  @override
  String get commonCancel => 'Otkaži';

  @override
  String get commonDelete => 'Obriši';

  @override
  String get commonEdit => 'Uredi';

  @override
  String get commonRefresh => 'Osvježi';

  @override
  String get commonSearch => 'Pretraga';

  @override
  String get commonRetry => 'Pokušaj ponovo';

  @override
  String get stateLoading => 'Učitavanje...';

  @override
  String get errorGeneric => 'Greška';

  @override
  String get emptyGeneric => 'Nema podataka';

  @override
  String get emptyList => 'Prazna lista';

  @override
  String get paginationPrevious => 'Prethodna stranica';

  @override
  String get paginationNext => 'Sljedeća stranica';

  @override
  String paginationPageOf(int page, int totalPages) {
    return 'Stranica $page od $totalPages';
  }

  @override
  String paginationTotalCount(int count) {
    return '$count ukupno';
  }

  @override
  String get commonSaving => 'Spašavanje...';

  @override
  String get welcomeTagline => 'Svaka kap, evidentirana.';

  @override
  String get welcomeSubtitle =>
      'Mali koraci u štednji vode prave velike valove promjena.';

  @override
  String get authLoginButton => 'Prijavi se';

  @override
  String get authRegisterButton => 'Registruj se';

  @override
  String get loginTitle => 'Prijava';

  @override
  String get loginWelcomeBack => 'Dobrodošli nazad';

  @override
  String get loginRememberMe => 'Zapamti me';

  @override
  String get loginFailedError => 'Prijava nije uspjela.';

  @override
  String get registerTitle => 'Registracija';

  @override
  String get firstNameRequiredError => 'Ime je obavezno.';

  @override
  String get lastNameRequiredError => 'Prezime je obavezno.';

  @override
  String get phoneInvalidError =>
      'Telefon smije sadržavati samo brojeve i simbole + - ( ).';

  @override
  String get fieldConfirmPasswordLabel => 'Potvrdi lozinku';

  @override
  String get registerThemeLabel => 'Tema';

  @override
  String get registrationFailedError => 'Registracija nije uspjela.';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get fieldPhoneLabel => 'Telefon';

  @override
  String get fieldFirstNameLabel => 'Ime';

  @override
  String get fieldLastNameLabel => 'Prezime';

  @override
  String get fieldPasswordLabel => 'Lozinka';

  @override
  String get emailRequiredError => 'Email je obavezan.';

  @override
  String get emailInvalidError => 'Unesite ispravan email.';

  @override
  String get passwordRequiredError => 'Lozinka je obavezna.';

  @override
  String get passwordTooShortError => 'Lozinka mora imati najmanje 6 znakova.';

  @override
  String get passwordMismatchError => 'Lozinke se ne podudaraju.';

  @override
  String get fieldRequiredError => 'Obavezno polje.';

  @override
  String get themeLightOption => 'Svijetla';

  @override
  String get themeDarkOption => 'Tamna';

  @override
  String get passwordResetTitle => 'Promjena lozinke';

  @override
  String get passwordResetDescription =>
      'Unesite trenutnu i novu lozinku da biste je promijenili.';

  @override
  String get passwordResetCurrentLabel => 'Trenutna lozinka';

  @override
  String get passwordResetNewLabel => 'Nova lozinka';

  @override
  String get passwordResetConfirmLabel => 'Potvrda nove lozinke';

  @override
  String get passwordResetSubmitButton => 'Promijeni lozinku';

  @override
  String get passwordResetSuccess => 'Lozinka je promijenjena.';

  @override
  String get passwordResetCurrentRequiredError => 'Unesite trenutnu lozinku.';

  @override
  String get passwordResetNewRequiredError => 'Unesite novu lozinku.';

  @override
  String get personalDetailsTitle => 'Lični podaci';

  @override
  String themeSaveFailedError(String message) {
    return 'Tema nije sačuvana: $message';
  }

  @override
  String languageSaveFailedError(String message) {
    return 'Jezik nije sačuvan: $message';
  }

  @override
  String get personalDetailsSaveSuccess => 'Lični podaci su sačuvani.';

  @override
  String get personalDetailsNameSectionTitle => 'Ime i prezime';

  @override
  String get personalDetailsAppearanceSectionTitle => 'Izgled';

  @override
  String get nameRequiredTogetherError => 'Obavezno ako unosite ime i prezime.';

  @override
  String get accountDataSectionTitle => 'Podaci o nalogu';

  @override
  String get accountPersonalDetailsSubtitle =>
      'Ime, prezime, email, telefon i tema';

  @override
  String get locationTitle => 'Lokacija';

  @override
  String get accountLocationSubtitle => 'Adresa prebivališta';

  @override
  String get accountPasswordSubtitle => 'Ažuriranje lozinke naloga';

  @override
  String get accountActivityLogTitle => 'Moje aktivnosti';

  @override
  String get accountActivityLogSubtitle => 'Historija prijava i izmjena naloga';

  @override
  String get accountCompanySettingsTitle => 'Postavke firme';

  @override
  String get accountCompanySettingsSubtitle => 'Upravljanje podacima firme';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleCollector => 'Inkasant';

  @override
  String get roleCustomer => 'Korisnik';

  @override
  String get locationNameRequiredError =>
      'Unesite ime i prezime u \"Lični podaci\" da biste sačuvali adresu.';

  @override
  String get locationSaveSuccess => 'Lokacija je sačuvana.';

  @override
  String get locationCityLabel => 'Grad';

  @override
  String get locationNoCityOption => 'Bez grada';

  @override
  String get locationMunicipalityLabel => 'Općina';

  @override
  String get locationNoMunicipalityOption => 'Bez općine';

  @override
  String get locationSettlementLabel => 'Naselje';

  @override
  String get locationNoSettlementOption => 'Bez naselja';

  @override
  String get locationStreetLabel => 'Ulica';

  @override
  String get locationHouseNumberLabel => 'Broj';

  @override
  String get mobileShellThemeTooltip => 'Promijeni temu';

  @override
  String get mobileShellLogoutTooltip => 'Odjava';

  @override
  String get tabNotifications => 'Obavijesti';

  @override
  String get tabWaterMeters => 'Vodomjeri';

  @override
  String get tabFaultReports => 'Prijave kvarova';

  @override
  String get tabAccount => 'Nalog';

  @override
  String get supportTitle => 'Podrška';

  @override
  String get supportSubtitle => 'Vaši tiketi i poruke podršci';
}
