import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cargo_model.dart';
import '../../models/client_model.dart';
import '../../core/config/cargo_statuses.dart';
import 'cargo_providers.dart';
import 'client_providers.dart';

/// Провайдер для аналитики и отчетов
class AnalyticsData {
  final Map<String, dynamic> cargoStats;
  final Map<String, dynamic> clientStats;
  final List<CargoModel> recentCargos;
  final List<ClientModel> topClients;

  const AnalyticsData({
    required this.cargoStats,
    required this.clientStats,
    required this.recentCargos,
    required this.topClients,
  });
}

/// Провайдер полной аналитики
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  // Получаем данные параллельно
  final futures = await Future.wait([
    ref.read(allCargosProvider.future),
    ref.read(allClientsProvider.future),
  ]);

  final cargos = futures[0] as List<CargoModel>;
  final clients = futures[1] as List<ClientModel>;

  // Статистика грузов
  final cargoStats = _calculateCargoStats(cargos);

  // Статистика клиентов
  final clientStats = _calculateClientStats(clients);

  // Последние грузы
  final recentCargos =
      cargos
          .where(
            (c) =>
                c.createdAt != null &&
                c.createdAt!.isAfter(
                  DateTime.now().subtract(const Duration(days: 7)),
                ),
          )
          .toList()
        ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

  // Топ клиенты по доходу
  final topClients = clients.where((c) => c.isActive).toList()
    ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue))
    ..take(10);

  return AnalyticsData(
    cargoStats: cargoStats,
    clientStats: clientStats,
    recentCargos: recentCargos,
    topClients: topClients,
  );
});

/// Провайдер статистики по периодам
enum ReportPeriod { week, month, quarter, year }

final periodAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, ReportPeriod>((
      ref,
      period,
    ) async {
      final cargosAsync = await ref.read(allCargosProvider.future);

      final cargos = cargosAsync;
      final clients = await ref.read(allClientsProvider.future);

      final DateTime cutoff = _getCutoffDate(period);

      final filteredCargos = cargos
          .where((c) => c.createdAt != null && c.createdAt!.isAfter(cutoff))
          .toList();
      final filteredClients = clients
          .where((c) => c.createdAt.isAfter(cutoff))
          .toList();

      return {
        'period': period.name,
        'cargos': _calculateCargoStats(filteredCargos),
        'clients': _calculateClientStats(filteredClients),
        'revenue': filteredCargos.fold<double>(
          0.0,
          (sum, cargo) => sum + 10000.0,
        ), // Заглушка цены
        'growth': _calculateGrowth(filteredCargos, period),
      };
    });

/// Провайдер для графиков статусов грузов
final cargoStatusChartProvider = FutureProvider<Map<String, int>>((ref) async {
  final cargosAsync = await ref.read(allCargosProvider.future);
  final cargos = cargosAsync;

  final Map<String, int> statusCounts = {};
  for (final cargo in cargos) {
    statusCounts[cargo.status] = (statusCounts[cargo.status] ?? 0) + 1;
  }

  return statusCounts;
});

/// Провайдер для популярных маршрутов
final popularRoutesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final cargosAsync = await ref.read(allCargosProvider.future);
  final cargos = cargosAsync;

  final Map<String, int> routeCounts = {};
  for (final cargo in cargos) {
    final route = '${cargo.from} → ${cargo.to}';
    routeCounts[route] = (routeCounts[route] ?? 0) + 1;
  }

  final sortedRoutes = routeCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sortedRoutes
      .take(10)
      .map((entry) => {'route': entry.key, 'count': entry.value})
      .toList();
});

Map<String, dynamic> _calculateCargoStats(List<CargoModel> cargos) {
  final totalCargos = cargos.length;
  final deliveredCargos = cargos.where((c) => c.status == 'Доставлен').length;
  final inTransitCargos = cargos.where((c) => c.status == 'В пути').length;
  final newCargos = cargos.where((c) => c.status == CargoStatus.published).length;
  final totalRevenue = cargos.fold<double>(
    0.0,
    (sum, cargo) => sum + 10000.0,
  ); // Заглушка цены
  final averagePrice = totalCargos > 0 ? totalRevenue / totalCargos : 0.0;

  return {
    'total': totalCargos,
    'delivered': deliveredCargos,
    'inTransit': inTransitCargos,
    'new': newCargos,
    'totalRevenue': totalRevenue,
    'averagePrice': averagePrice,
    'deliveryRate': totalCargos > 0
        ? (deliveredCargos / totalCargos) * 100
        : 0.0,
  };
}

Map<String, dynamic> _calculateClientStats(List<ClientModel> clients) {
  final totalClients = clients.length;
  final activeClients = clients.where((c) => c.isActive).length;
  final totalRevenue = clients.fold<double>(
    0.0,
    (sum, client) => sum + client.totalRevenue,
  );
  final totalOrders = clients.fold<int>(
    0,
    (sum, client) => sum + client.totalOrders,
  );
  final averageRevenue = totalClients > 0 ? totalRevenue / totalClients : 0.0;

  return {
    'total': totalClients,
    'active': activeClients,
    'inactive': totalClients - activeClients,
    'totalRevenue': totalRevenue,
    'totalOrders': totalOrders,
    'averageRevenue': averageRevenue,
    'activeRate': totalClients > 0 ? (activeClients / totalClients) * 100 : 0.0,
  };
}

DateTime _getCutoffDate(ReportPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case ReportPeriod.week:
      return now.subtract(const Duration(days: 7));
    case ReportPeriod.month:
      return DateTime(now.year, now.month - 1, now.day);
    case ReportPeriod.quarter:
      return DateTime(now.year, now.month - 3, now.day);
    case ReportPeriod.year:
      return DateTime(now.year - 1, now.month, now.day);
  }
}

double _calculateGrowth(List<CargoModel> cargos, ReportPeriod period) {
  // Простая логика роста - сравнение с предыдущим периодом
  // В реальном приложении здесь будет более сложная логика
  return 15.5; // Заглушка
}
