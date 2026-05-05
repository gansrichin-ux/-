import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/cargo_repository.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/user_repository.dart';

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository.instance);
final cargoRepositoryProvider = Provider<CargoRepository>((ref) => CargoRepository.instance);
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository.instance);
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository.instance);
