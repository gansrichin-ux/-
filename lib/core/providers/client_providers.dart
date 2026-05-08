import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/client_service.dart';
import '../../models/client_model.dart';
import 'auth_providers.dart';

/// Провайдер для сервиса клиентов
final clientServiceProvider = Provider<ClientService>((ref) {
  return ClientService.instance;
});

/// Провайдер всех клиентов
final allClientsProvider = FutureProvider<List<ClientModel>>((ref) async {
  final clientService = ref.watch(clientServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return await clientService.getAllClients(ownerId: user.uid);
});

/// Провайдер активных клиентов
final activeClientsProvider = FutureProvider<List<ClientModel>>((ref) async {
  final clientService = ref.watch(clientServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return await clientService.getActiveClients(ownerId: user.uid);
});

/// Провайдер клиента по ID
final clientProvider = FutureProvider.family<ClientModel?, String>((
  ref,
  clientId,
) async {
  final clientService = ref.watch(clientServiceProvider);
  return await clientService.getClient(clientId);
});

/// Провайдер для поиска клиентов
class ClientSearchFilter {
  final String query;
  final bool? isActive;

  const ClientSearchFilter({this.query = '', this.isActive});

  ClientSearchFilter copyWith({String? query, bool? isActive}) {
    return ClientSearchFilter(
      query: query ?? this.query,
      isActive: isActive ?? this.isActive,
    );
  }
}

final clientSearchFilterProvider = StateProvider<ClientSearchFilter>((ref) {
  return const ClientSearchFilter();
});

/// Провайдер отфильтрованных клиентов
final filteredClientsProvider = Provider<List<ClientModel>>((ref) {
  final allClientsAsync = ref.watch(allClientsProvider);
  final filter = ref.watch(clientSearchFilterProvider);

  return allClientsAsync.when(
    data: (allClients) {
      return allClients.where((client) {
        // Фильтр по активности
        if (filter.isActive != null && client.isActive != filter.isActive) {
          return false;
        }

        // Фильтр по поисковому запросу
        if (filter.query.isNotEmpty) {
          final query = filter.query.toLowerCase();
          return client.name.toLowerCase().contains(query) ||
              (client.phone?.toLowerCase().contains(query) ?? false) ||
              (client.email?.toLowerCase().contains(query) ?? false) ||
              (client.company?.toLowerCase().contains(query) ?? false) ||
              (client.address?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Провайдер статистики клиентов
final clientStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final allClientsAsync = ref.watch(allClientsProvider);

  return allClientsAsync.when(
    data: (clients) {
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
      final averageRevenue =
          totalClients > 0 ? totalRevenue / totalClients : 0.0;

      return {
        'totalClients': totalClients,
        'activeClients': activeClients,
        'inactiveClients': totalClients - activeClients,
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'averageRevenue': averageRevenue,
        'activeRate': totalClients > 0 ? activeClients / totalClients : 0.0,
      };
    },
    loading: () => {},
    error: (error, stackTrace) => {},
  );
});

/// Провайдер топ клиентов по доходу
final topClientsByRevenueProvider = Provider<List<ClientModel>>((ref) {
  final allClientsAsync = ref.watch(allClientsProvider);

  return allClientsAsync.when(
    data: (clients) {
      return clients.where((c) => c.isActive).toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue))
        ..take(10);
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Провайдер топ клиентов по количеству заказов
final topClientsByOrdersProvider = Provider<List<ClientModel>>((ref) {
  final allClientsAsync = ref.watch(allClientsProvider);

  return allClientsAsync.when(
    data: (clients) {
      return clients.where((c) => c.isActive).toList()
        ..sort((a, b) => b.totalOrders.compareTo(a.totalOrders))
        ..take(10);
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Провайдер недавно добавленных клиентов
final recentClientsProvider = Provider<List<ClientModel>>((ref) {
  final allClientsAsync = ref.watch(allClientsProvider);

  return allClientsAsync.when(
    data: (clients) {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      return clients.where((c) => c.createdAt.isAfter(thirtyDaysAgo)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Провайдер клиентов без недавних заказов
final inactiveClientsProvider = Provider<List<ClientModel>>((ref) {
  final allClientsAsync = ref.watch(allClientsProvider);

  return allClientsAsync.when(
    data: (clients) {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      return clients
          .where(
            (c) =>
                c.isActive &&
                (c.lastContactDate == null ||
                    c.lastContactDate!.isBefore(thirtyDaysAgo)),
          )
          .toList()
        ..sort(
          (a, b) => (a.lastContactDate ?? DateTime(1900)).compareTo(
            b.lastContactDate ?? DateTime(1900),
          ),
        );
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});
