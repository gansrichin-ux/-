import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exchange_rate_model.dart';
import 'app_settings_providers.dart';
import '../services/exchange_rate_service.dart';

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService.instance;
});

final exchangeRatesProvider = FutureProvider.autoDispose<ExchangeRates>((ref) {
  final settings = ref.watch(appSettingsProvider);

  if (settings.exchangeAutoRefreshEnabled) {
    final timer = Timer(const Duration(minutes: 30), () {
      ref.invalidateSelf();
    });

    ref.onDispose(timer.cancel);
  }

  return ref.watch(exchangeRateServiceProvider).fetchLatestRates();
});
