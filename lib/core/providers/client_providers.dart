import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/client_service.dart';
import '../../models/client_model.dart';
import 'auth_providers.dart';

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СЃРµСЂРІРёСЃР° РєР»РёРµРЅС‚РѕРІ
final clientServiceProvider = Provider<ClientService>((ref) {
  return ClientService.instance;
});

/// РџСЂРѕРІР°Р№РґРµСЂ РІСЃРµС… РєР»РёРµРЅС‚РѕРІ
final allClientsProvider = FutureProvider<List<ClientModel>>((ref) async {
  final clientService = ref.watch(clientServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return await clientService.getAllClients(ownerId: user.uid);
});

/// РџСЂРѕРІР°Р№РґРµСЂ Р°РєС‚РёРІРЅС‹С… РєР»РёРµРЅС‚РѕРІ
final activeClientsProvider = FutureProvider<List<ClientModel>>((ref) async {
  final clientService = ref.watch(clientServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return await clientService.getActiveClients(ownerId: user.uid);
});

/// РџСЂРѕРІР°Р№РґРµСЂ РєР»РёРµРЅС‚Р° РїРѕ ID
final clientProvider = FutureProvider.family<ClientModel?, String>((
  ref,
  clientId,
) async {
  final clientService = ref.watch(clientServiceProvider);
  return await clientService.getClient(clientId);
});

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ РїРѕРёСЃРєР° РєР»РёРµРЅС‚РѕРІ
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

/// РџСЂРѕРІР°Р№РґРµСЂ РѕС‚С„РёР»СЊС‚СЂРѕРІР°РЅРЅС‹С… РєР»РёРµРЅС‚РѕРІ
final filteredClientsProvider = Provider<List<ClientModel>>((ref) {
  final allClientsAsync = ref.watch(allClientsProvider);
  final filter = ref.watch(clientSearchFilterProvider);

  return allClientsAsync.when(
    data: (allClients) {
      return allClients.where((client) {
        // Р¤РёР»СЊС‚СЂ РїРѕ Р°РєС‚РёРІРЅРѕСЃС‚Рё
        if (filter.isActive != null && client.isActive != filter.isActive) {
          return false;
        }

        // Р¤РёР»СЊС‚СЂ РїРѕ РїРѕРёСЃРєРѕРІРѕРјСѓ Р·Р°РїСЂРѕСЃСѓ
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

/// РџСЂРѕРІР°Р№РґРµСЂ СЃС‚Р°С‚РёСЃС‚РёРєРё РєР»РёРµРЅС‚РѕРІ
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

/// РџСЂРѕРІР°Р№РґРµСЂ С‚РѕРї РєР»РёРµРЅС‚РѕРІ РїРѕ РґРѕС…РѕРґСѓ
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

/// РџСЂРѕРІР°Р№РґРµСЂ С‚РѕРї РєР»РёРµРЅС‚РѕРІ РїРѕ РєРѕР»РёС‡РµСЃС‚РІСѓ Р·Р°РєР°Р·РѕРІ
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

/// РџСЂРѕРІР°Р№РґРµСЂ РЅРµРґР°РІРЅРѕ РґРѕР±Р°РІР»РµРЅРЅС‹С… РєР»РёРµРЅС‚РѕРІ
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

/// РџСЂРѕРІР°Р№РґРµСЂ РєР»РёРµРЅС‚РѕРІ Р±РµР· РЅРµРґР°РІРЅРёС… Р·Р°РєР°Р·РѕРІ
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
