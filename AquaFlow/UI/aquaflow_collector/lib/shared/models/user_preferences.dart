/// The signed-in user's own preferences as returned by
/// `GET /Account/preferences` (mirrors the backend `UserPreferenceResponse`).
/// A user with no `UserPreference` row yet gets the backend's defaults
/// (light/bs/both notifications on), so this model has no "unset" state.
class UserPreferences {
  const UserPreferences({
    required this.theme,
    required this.language,
    required this.receiveEmailNotifications,
    required this.receivePushNotifications,
  });

  /// `'light'` or `'dark'` (backend `UserPreferenceUpdateValidator` rejects
  /// anything else).
  final String theme;
  final String language;
  final bool receiveEmailNotifications;
  final bool receivePushNotifications;

  bool get isDarkTheme => theme.toLowerCase() == 'dark';

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: (json['theme'] ?? 'light') as String,
      language: (json['language'] ?? 'bs') as String,
      receiveEmailNotifications: json['receiveEmailNotifications'] != false,
      receivePushNotifications: json['receivePushNotifications'] != false,
    );
  }

  /// Body for `PUT /Account/preferences`. The backend takes the full object
  /// (no PATCH), so every field is always sent back, even when only [theme]
  /// changed.
  Map<String, dynamic> toJson() => {
        'theme': theme,
        'language': language,
        'receiveEmailNotifications': receiveEmailNotifications,
        'receivePushNotifications': receivePushNotifications,
      };

  UserPreferences copyWith({String? theme}) => UserPreferences(
        theme: theme ?? this.theme,
        language: language,
        receiveEmailNotifications: receiveEmailNotifications,
        receivePushNotifications: receivePushNotifications,
      );
}
