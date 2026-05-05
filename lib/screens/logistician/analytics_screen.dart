import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/analytics_providers.dart';

const _bg = Color(0xFF0B1220);
const _surface = Color(0xFF111827);
const _outline = Color(0xFF263247);
const _mutedText = Color(0xFF94A3B8);

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.month;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final statusChartAsync = ref.watch(cargoStatusChartProvider);
    final routesAsync = ref.watch(popularRoutesProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsProvider);
          ref.invalidate(periodAnalyticsProvider(_selectedPeriod));
          ref.invalidate(cargoStatusChartProvider);
          ref.invalidate(popularRoutesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // РџРµСЂРёРѕРґ Р°РЅР°Р»РёС‚РёРєРё
              _buildPeriodSelector(),
              const SizedBox(height: 16),

              // РћСЃРЅРѕРІРЅР°СЏ СЃС‚Р°С‚РёСЃС‚РёРєР°
              if (analyticsAsync.when(
                data: (data) => true,
                loading: () => false,
                error: (error, stackTrace) => false,
              ))
                _buildMainStats(analyticsAsync),
              const SizedBox(height: 16),

              // Р“СЂР°С„РёРєРё Рё РґРёР°РіСЂР°РјРјС‹
              if (statusChartAsync.when(
                data: (data) => true,
                loading: () => false,
                error: (error, stackTrace) => false,
              ))
                _buildStatusChart(statusChartAsync),
              const SizedBox(height: 16),

              // РџРѕРїСѓР»СЏСЂРЅС‹Рµ РјР°СЂС€СЂСѓС‚С‹
              if (routesAsync.when(
                data: (data) => true,
                loading: () => false,
                error: (error, stackTrace) => false,
              ))
                _buildPopularRoutes(routesAsync),
              const SizedBox(height: 16),

              // РўРѕРї РєР»РёРµРЅС‚С‹
              if (analyticsAsync.when(
                data: (data) => true,
                loading: () => false,
                error: (error, stackTrace) => false,
              ))
                _buildTopClients(analyticsAsync),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics, color: Color(0xFF3B82F6), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'РџРµСЂРёРѕРґ Р°РЅР°Р»РёР·Р°',
                  style: TextStyle(fontSize: 12, color: _mutedText),
                ),
                Text(
                  _getPeriodText(_selectedPeriod),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<ReportPeriod>(
            icon: const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF3B82F6),
            ),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ReportPeriod.week,
                child: Text('РќРµРґРµР»СЏ'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.month,
                child: Text('РњРµСЃСЏС†'),
              ),
              const PopupMenuItem(
                value: ReportPeriod.quarter,
                child: Text('РљРІР°СЂС‚Р°Р»'),
              ),
              const PopupMenuItem(
                  value: ReportPeriod.year, child: Text('Р“РѕРґ')),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.26),
              ),
            ),
            child: Text(
              _getPeriodGrowth(_selectedPeriod),
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(AsyncValue<AnalyticsData> analyticsAsync) {
    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('РћС€РёР±РєР°: $error')),
      data: (analytics) => Column(
        children: [
          // РЎС‚Р°С‚РёСЃС‚РёРєР° РіСЂСѓР·РѕРІ
          _buildStatsCard('РЎС‚Р°С‚РёСЃС‚РёРєР° РіСЂСѓР·РѕРІ', [
            _buildStatItem(
              'Р’СЃРµРіРѕ РіСЂСѓР·РѕРІ',
              '${analytics.cargoStats['total']}',
              Icons.local_shipping,
              const Color(0xFF3B82F6),
            ),
            _buildStatItem(
              'Р”РѕСЃС‚Р°РІР»РµРЅРѕ',
              '${analytics.cargoStats['delivered']}',
              Icons.check_circle,
              const Color(0xFF22C55E),
            ),
            _buildStatItem(
              'Р’ РїСѓС‚Рё',
              '${analytics.cargoStats['inTransit']}',
              Icons.directions_car,
              const Color(0xFFF59E0B),
            ),
            _buildStatItem(
              'РќРѕРІС‹Рµ',
              '${analytics.cargoStats['new']}',
              Icons.add_circle,
              const Color(0xFF8B5CF6),
            ),
          ]),
          const SizedBox(height: 16),

          // РЎС‚Р°С‚РёСЃС‚РёРєР° РєР»РёРµРЅС‚РѕРІ
          _buildStatsCard('РЎС‚Р°С‚РёСЃС‚РёРєР° РєР»РёРµРЅС‚РѕРІ', [
            _buildStatItem(
              'Р’СЃРµРіРѕ РєР»РёРµРЅС‚РѕРІ',
              '${analytics.clientStats['total']}',
              Icons.people,
              const Color(0xFF6366F1),
            ),
            _buildStatItem(
              'РђРєС‚РёРІРЅС‹Рµ',
              '${analytics.clientStats['active']}',
              Icons.person,
              const Color(0xFF22C55E),
            ),
            _buildStatItem(
              'Р”РѕС…РѕРґ',
              '${(analytics.clientStats['totalRevenue'] as double).toStringAsFixed(0)} ?',
              Icons.attach_money,
              const Color(0xFF10B981),
            ),
            _buildStatItem(
              'Р—Р°РєР°Р·С‹',
              '${analytics.clientStats['totalOrders']}',
              Icons.shopping_cart,
              const Color(0xFFF59E0B),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: children.map((child) => Expanded(child: child)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _mutedText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusChart(AsyncValue<Map<String, int>> statusChartAsync) {
    return statusChartAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('РћС€РёР±РєР°: $error')),
      data: (statusData) => Container(
        padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'РЎС‚Р°С‚СѓСЃС‹ РіСЂСѓР·РѕРІ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...statusData.entries.map((entry) {
              final percentage =
                  statusData.values.fold(0, (sum, val) => sum + val) > 0
                      ? (entry.value /
                          statusData.values.fold(0, (sum, val) => sum + val) *
                          100)
                      : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: _mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getStatusColor(entry.key),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRoutes(
    AsyncValue<List<Map<String, dynamic>>> routesAsync,
  ) {
    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('РћС€РёР±РєР°: $error')),
      data: (routes) => Container(
        padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.route,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'РџРѕРїСѓР»СЏСЂРЅС‹Рµ РјР°СЂС€СЂСѓС‚С‹',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...routes.take(5).map(
                  (route) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '${route['count']}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            route['route'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClients(AsyncValue<AnalyticsData> analyticsAsync) {
    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('РћС€РёР±РєР°: $error')),
      data: (analytics) => Container(
        padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'РўРѕРї РєР»РёРµРЅС‚С‹',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...analytics.topClients.take(5).map(
                  (client) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(
                            0xFFF59E0B,
                          ).withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${client.totalOrders} Р·Р°РєР°Р·РѕРІ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${client.totalRevenue.toStringAsFixed(0)} ?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _getPeriodText(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.week:
        return 'РџРѕСЃР»РµРґРЅСЏСЏ РЅРµРґРµР»СЏ';
      case ReportPeriod.month:
        return 'РџРѕСЃР»РµРґРЅРёР№ РјРµСЃСЏС†';
      case ReportPeriod.quarter:
        return 'РџРѕСЃР»РµРґРЅРёР№ РєРІР°СЂС‚Р°Р»';
      case ReportPeriod.year:
        return 'РџРѕСЃР»РµРґРЅРёР№ РіРѕРґ';
    }
  }

  String _getPeriodGrowth(ReportPeriod period) {
    // Р—Р°РіР»СѓС€РєР° СЂРѕСЃС‚Р°
    switch (period) {
      case ReportPeriod.week:
        return '+12.5%';
      case ReportPeriod.month:
        return '+15.3%';
      case ReportPeriod.quarter:
        return '+28.7%';
      case ReportPeriod.year:
        return '+45.2%';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'РќРѕРІС‹Р№':
        return const Color(0xFF22C55E);
      case 'Р’ РїСѓС‚Рё':
        return const Color(0xFF3B82F6);
      case 'Р”РѕСЃС‚Р°РІР»РµРЅ':
        return const Color(0xFF10B981);
      case 'РћС‚РјРµРЅРµРЅ':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }
}
