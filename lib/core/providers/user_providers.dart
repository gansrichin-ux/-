import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/user_repository.dart';
import '../../models/user_model.dart';

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository.instance;
});

// All drivers
final driversProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).watchDrivers();
});

// All users (for admin purposes)
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).watchAllUsers();
});

// User search filter
final userSearchFilterProvider =
    StateNotifierProvider<UserSearchFilterNotifier, UserSearchFilter>((ref) {
  return UserSearchFilterNotifier();
});

// Filtered users
final filteredUsersProvider = Provider<List<UserModel>>((ref) {
  final allUsers = ref.watch(allUsersProvider);
  final filter = ref.watch(userSearchFilterProvider);

  return allUsers.when(
    data: (users) {
      return users.where((user) {
        // Role filter
        if (filter.role != null && user.role != filter.role) {
          return false;
        }

        // Search query
        if (filter.query.isNotEmpty) {
          final query = filter.query.toLowerCase();
          return user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              (user.car?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

// User statistics
final userStatsProvider = Provider<UserStats>((ref) {
  final allUsers = ref.watch(allUsersProvider);

  return allUsers.when(
    data: (users) {
      return UserStats(
        total: users.length,
        drivers: users.where((u) => u.isDriver).length,
        logisticians: users.where((u) => u.isLogistician).length,
      );
    },
    loading: () => UserStats.empty,
    error: (error, stackTrace) => UserStats.empty,
  );
});

class UserSearchFilterNotifier extends StateNotifier<UserSearchFilter> {
  UserSearchFilterNotifier() : super(const UserSearchFilter());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setRole(String? role) {
    state = state.copyWith(role: role);
  }

  void clearFilters() {
    state = const UserSearchFilter();
  }
}

class UserSearchFilter {
  final String query;
  final String? role;

  const UserSearchFilter({
    this.query = '',
    this.role,
  });

  UserSearchFilter copyWith({
    String? query,
    String? role,
  }) {
    return UserSearchFilter(
      query: query ?? this.query,
      role: role ?? this.role,
    );
  }
}

class UserStats {
  final int total;
  final int drivers;
  final int logisticians;
  final int active;

  const UserStats({
    this.total = 0,
    this.drivers = 0,
    this.logisticians = 0,
    this.active = 0,
  });

  static const UserStats empty = UserStats();

  double get driverRatio => total > 0 ? drivers / total : 0.0;
  double get logisticianRatio => total > 0 ? logisticians / total : 0.0;
}
