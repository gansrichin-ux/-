class CurrencyRate {
  final String code;
  final String name;
  final String symbol;
  final double kztRate;
  final ColorTone tone;

  const CurrencyRate({
    required this.code,
    required this.name,
    required this.symbol,
    required this.kztRate,
    required this.tone,
  });
}

class ExchangeRates {
  final DateTime updatedAt;
  final List<CurrencyRate> currencies;
  final String sourceName;
  final String sourceUrl;

  const ExchangeRates({
    required this.updatedAt,
    required this.currencies,
    required this.sourceName,
    required this.sourceUrl,
  });
}

enum ColorTone { blue, green, amber, violet }
