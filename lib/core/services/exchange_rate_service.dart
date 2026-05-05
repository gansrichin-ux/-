import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/exchange_rate_model.dart';

class ExchangeRateService {
  ExchangeRateService({http.Client? client})
    : _client = client ?? http.Client();

  static final ExchangeRateService instance = ExchangeRateService();

  final http.Client _client;

  Future<ExchangeRates> fetchLatestRates() async {
    final uri = Uri.https('open.er-api.com', '/v6/latest/USD');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить курсы валют');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['result'] != 'success') {
      throw Exception('Сервис курсов временно недоступен');
    }

    final rates = (payload['rates'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    final usdToKzt = _requiredRate(rates, 'KZT');
    final usdToEur = _requiredRate(rates, 'EUR');
    final usdToRub = _requiredRate(rates, 'RUB');
    final updatedAt = _updatedAt(payload);

    return ExchangeRates(
      updatedAt: updatedAt,
      sourceName: 'ExchangeRate-API',
      sourceUrl: 'https://www.exchangerate-api.com',
      currencies: [
        CurrencyRate(
          code: 'RUB',
          name: 'Рубль',
          symbol: '₽',
          kztRate: usdToKzt / usdToRub,
          tone: ColorTone.amber,
        ),
        CurrencyRate(
          code: 'USD',
          name: 'Доллар',
          symbol: r'$',
          kztRate: usdToKzt,
          tone: ColorTone.blue,
        ),
        CurrencyRate(
          code: 'EUR',
          name: 'Евро',
          symbol: '€',
          kztRate: usdToKzt / usdToEur,
          tone: ColorTone.violet,
        ),
      ],
    );
  }

  double _requiredRate(Map<String, double> rates, String code) {
    final value = rates[code];
    if (value == null || value <= 0) {
      throw Exception('Курс $code не найден');
    }
    return value;
  }

  DateTime _updatedAt(Map<String, dynamic> payload) {
    final unix = payload['time_last_update_unix'];
    if (unix is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        unix.toInt() * 1000,
        isUtc: true,
      ).toLocal();
    }
    return DateTime.now();
  }
}
