import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repository.dart';
import '../../models/user_model.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.instance;
});

// Current user state
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});

// Auth state for UI
final authStateProvider = Provider<AuthState>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (userModel) => userModel != null
        ? AuthState.authenticated(userModel)
        : const AuthState._(),
    loading: () => const AuthState._(isLoading: true),
    error: (error, stack) => AuthState.error(error.toString()),
  );
});

// Role-based access
final isDriverProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (userModel) => userModel?.isDriver ?? false,
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});

final isLogisticianProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (userModel) => userModel?.isLogistician ?? false,
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState._({
    this.isLoading = false,
    this.user,
    this.error,
  });

  factory AuthState.authenticated(UserModel user) => AuthState._(user: user);

  factory AuthState.unauthenticated() => const AuthState._();

  factory AuthState.loading() => const AuthState._(isLoading: true);

  factory AuthState.error(String error) => AuthState._(error: error);

  bool get isAuthenticated => user != null && !isLoading;
  bool get hasError => error != null;

  T when<T>({
    required T Function() loading,
    required T Function(UserModel user) authenticated,
    required T Function(String error) onError,
    required T Function() unauthenticated,
  }) {
    if (isLoading) {
      return loading();
    } else if (hasError) {
      return onError(error!);
    } else if (user != null) {
      return authenticated(user!);
    } else {
      return unauthenticated();
    }
  }
}
