import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/cargo_providers.dart';
import '../../core/providers/exchange_rate_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../models/exchange_rate_model.dart';

const _bg = Color(0xFF0B1220);
const _surface = Color(0xFF111827);
const _outline = Color(0xFF263247);
const _mutedText = Color(0xFF94A3B8);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final cargoStats = ref.watch(cargoStatsProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final exchangeRatesAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Compact Header
          _buildCompactHeader(context, unreadCountAsync),
          const SizedBox(height: 12),

          // Quick Stats Grid
          _buildQuickStatsGrid(cargoStats),
          const SizedBox(height: 12),

          // Exchange Rates
          _buildExchangeRatesCard(exchangeRatesAsync),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    AsyncValue<int> unreadCountAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Главная',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ключевые показатели логистики',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          unreadCountAsync.when(
            data: (count) => count > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(CargoStats cargoStats) {
    final cards = [
      _buildCompactStatCard(
        'Всего',
        cargoStats.total.toString(),
        Icons.local_shipping,
        const Color(0xFF3B82F6),
      ),
      _buildCompactStatCard(
        'Новые',
        cargoStats.newCount.toString(),
        Icons.add_circle,
        const Color(0xFF22C55E),
      ),
      _buildCompactStatCard(
        'В пути',
        cargoStats.inTransit.toString(),
        Icons.directions_car,
        const Color(0xFFF59E0B),
      ),
      _buildCompactStatCard(
        'Доставлено',
        cargoStats.completed.toString(),
        Icons.check_circle,
        const Color(0xFF10B981),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 420 ? 2 : 4;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: columns == 2 ? 1.25 : 0.8,
          children: cards,
        );
      },
    );
  }

  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _outline, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRatesCard(AsyncValue<ExchangeRates> ratesAsync) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.currency_exchange_rounded,
                  color: Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Курсы валют',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Обновить',
                onPressed: () => ref.invalidate(exchangeRatesProvider),
                icon: const Icon(Icons.refresh_rounded),
                color: _mutedText,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ratesAsync.when(
            data: _buildExchangeRateContent,
            loading: _buildExchangeRateLoading,
            error: (error, _) => _buildExchangeRateError(),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateContent(ExchangeRates rates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 420 ? 2 : 4;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: columns == 2 ? 1.15 : 0.85,
              children: rates.currencies.map(_buildCurrencyTile).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Обновлено: ${DateFormat('dd.MM.yyyy HH:mm').format(rates.updatedAt)} • ${rates.sourceName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _mutedText, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCurrencyTile(CurrencyRate rate) {
    final color = _currencyColor(rate.tone);
    final value = '${NumberFormat('#,##0.00', 'ru_RU').format(rate.kztRate)} ?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    rate.symbol,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rate.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '1 ${rate.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateLoading() {
    return const SizedBox(
      height: 96,
      child: Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
    );
  }

  Widget _buildExchangeRateError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Не удалось загрузить курсы. Проверьте интернет.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(exchangeRatesProvider),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Color _currencyColor(ColorTone tone) {
    switch (tone) {
      case ColorTone.blue:
        return const Color(0xFF3B82F6);
      case ColorTone.green:
        return const Color(0xFF22C55E);
      case ColorTone.amber:
        return const Color(0xFFF59E0B);
      case ColorTone.violet:
        return const Color(0xFF8B5CF6);
    }
  }
}
