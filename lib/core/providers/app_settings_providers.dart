import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool notificationsEnabled;
  final bool exchangeAutoRefreshEnabled;

  const AppSettings({
    this.notificationsEnabled = true,
    this.exchangeAutoRefreshEnabled = true,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? exchangeAutoRefreshEnabled,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      exchangeAutoRefreshEnabled:
          exchangeAutoRefreshEnabled ?? this.exchangeAutoRefreshEnabled,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _exchangeAutoRefreshEnabledKey = 'exchange_auto_refresh_enabled';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> _load() async {
    final prefs = await _prefs;
    state = AppSettings(
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
      exchangeAutoRefreshEnabled:
          prefs.getBool(_exchangeAutoRefreshEnabledKey) ?? true,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await _prefs;
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  Future<void> setExchangeAutoRefreshEnabled(bool value) async {
    state = state.copyWith(exchangeAutoRefreshEnabled: value);
    final prefs = await _prefs;
    await prefs.setBool(_exchangeAutoRefreshEnabledKey, value);
  }
}
