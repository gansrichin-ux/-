import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/cargo_model.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/document_model.dart';
import '../../models/delivery_report_model.dart';

class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  static const String _cargoKey = 'cached_cargos';
  static const String _userKey = 'cached_user';
  static const String _clientsKey = 'cached_clients';
  static const String _documentsKey = 'cached_documents';
  static const String _reportsKey = 'cached_reports';
  static const String _pendingActionsKey = 'pending_actions';

  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _connectionController.add(results.isNotEmpty && results.first != ConnectivityResult.none);
    });

    // Check initial connectivity
    final initialConnectivity = await Connectivity().checkConnectivity();
    _connectionController.add(initialConnectivity.isNotEmpty && initialConnectivity.first != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _connectionController.close();
  }

  // Cargo caching
  Future<void> cacheCargos(List<CargoModel> cargos) async {
    try {
      final jsonList = cargos.map((cargo) => cargo.toMap()).toList();
      await _prefs?.setString(_cargoKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error
    }
  }

  Future<List<CargoModel>> getCachedCargos() async {
    try {
      final jsonString = _prefs?.getString(_cargoKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => CargoModel.fromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // User caching
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonMap = user.toMap();
      await _prefs?.setString(_userKey, jsonEncode(jsonMap));
    } catch (e) {
      // Handle error
    }
  }

  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = _prefs?.getString(_userKey);
      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromMap(jsonMap);
    } catch (e) {
      return null;
    }
  }

  // Client caching
  Future<void> cacheClients(List<ClientModel> clients) async {
    try {
      final jsonList = clients.map((client) => client.toLocalMap()).toList();
      await _prefs?.setString(_clientsKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error
    }
  }

  Future<List<ClientModel>> getCachedClients() async {
    try {
      final jsonString = _prefs?.getString(_clientsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => ClientModel.fromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Document caching
  Future<void> cacheDocuments(List<DocumentModel> documents) async {
    try {
      final jsonList = documents.map((doc) => doc.toMap()).toList();
      await _prefs?.setString(_documentsKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error
    }
  }

  Future<List<DocumentModel>> getCachedDocuments() async {
    try {
      final jsonString = _prefs?.getString(_documentsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => DocumentModel.fromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Report caching
  Future<void> cacheReports(List<DeliveryReportModel> reports) async {
    try {
      final jsonList = reports.map((report) => report.toMap()).toList();
      await _prefs?.setString(_reportsKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error
    }
  }

  Future<List<DeliveryReportModel>> getCachedReports() async {
    try {
      final jsonString = _prefs?.getString(_reportsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => DeliveryReportModel.fromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Pending actions
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    try {
      final actions = await getPendingActions();
      actions.add(action);
      await _prefs?.setString(_pendingActionsKey, jsonEncode(actions));
    } catch (e) {
      // Handle error
    }
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    try {
      final jsonString = _prefs?.getString(_pendingActionsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearPendingActions() async {
    try {
      await _prefs?.remove(_pendingActionsKey);
    } catch (e) {
      // Handle error
    }
  }

  // Clear all cache
  Future<void> clearCache() async {
    try {
      await _prefs?.clear();
    } catch (e) {
      // Handle error
    }
  }

  // Connectivity check
  Future<bool> hasNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      return true; // Assume connection if check fails
    }
  }

  // Sync pending actions
  Future<void> syncPendingActions() async {
    try {
      if (!await hasNetworkConnection()) return;

      final actions = await getPendingActions();
      for (final action in actions) {
        await _processAction(action);
      }
      
      await clearPendingActions();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _processAction(Map<String, dynamic> action) async {
    final type = action['type'] as String;
    switch (type) {
      case 'create_cargo':
        // Handle cargo creation
        break;
      case 'update_cargo':
        // Handle cargo update
        break;
      case 'create_client':
        // Handle client creation
        break;
      default:
        // Handle unknown action
        break;
    }
  }

  // Cache statistics
  Future<CacheStats> getCacheStats() async {
    final cargos = await getCachedCargos();
    final clients = await getCachedClients();
    final documents = await getCachedDocuments();
    final pendingActions = await getPendingActions();

    return CacheStats(
      cachedCargos: cargos.length,
      cachedClients: clients.length,
      cachedDocuments: documents.length,
      pendingActions: pendingActions.length,
      lastSyncTime: DateTime.now(),
    );
  }
}

class CacheStats {
  final int cachedCargos;
  final int cachedClients;
  final int cachedDocuments;
  final int pendingActions;
  final DateTime lastSyncTime;

  const CacheStats({
    required this.cachedCargos,
    required this.cachedClients,
    required this.cachedDocuments,
    required this.pendingActions,
    required this.lastSyncTime,
  });

  static CacheStats empty = CacheStats(
    cachedCargos: 0,
    cachedClients: 0,
    cachedDocuments: 0,
    pendingActions: 0,
    lastSyncTime: DateTime.now(),
  );

  int get totalCachedItems => cachedCargos + cachedClients + cachedDocuments;
}
