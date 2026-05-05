import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client_model.dart';

class ClientService {
  ClientService._();
  static final ClientService instance = ClientService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _clients =>
      _firestore.collection('clients');

  // Create client
  Future<String> createClient(ClientModel client) async {
    final docRef = await _clients.add(client.toMap());
    return docRef.id;
  }

  // Get client by ID
  Future<ClientModel?> getClient(String clientId) async {
    try {
      final doc = await _clients.doc(clientId).get();
      if (!doc.exists) return null;
      return ClientModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Get all clients
  Future<List<ClientModel>> getAllClients({String? ownerId}) async {
    try {
      Query<Map<String, dynamic>> query = _clients;
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final snapshot = await query.get();
      final clients = snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
      clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return clients;
    } catch (e) {
      return [];
    }
  }

  // Get active clients
  Future<List<ClientModel>> getActiveClients({String? ownerId}) async {
    try {
      Query<Map<String, dynamic>> query = _clients.where(
        'isActive',
        isEqualTo: true,
      );
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final snapshot = await query.get();
      final clients = snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
      clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return clients;
    } catch (e) {
      return [];
    }
  }

  // Search clients
  Future<List<ClientModel>> searchClients(String query) async {
    try {
      final snapshot = await _clients
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('name')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Update client
  Future<bool> updateClient(ClientModel client) async {
    try {
      await _clients.doc(client.id).update(client.toUpdateMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update client statistics
  Future<bool> updateClientStats({
    required String clientId,
    int? totalOrders,
    double? totalRevenue,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (totalOrders != null) {
        updates['totalOrders'] = FieldValue.increment(totalOrders);
      }

      if (totalRevenue != null) {
        updates['totalRevenue'] = FieldValue.increment(totalRevenue);
      }

      updates['lastContactDate'] = FieldValue.serverTimestamp();

      await _clients.doc(clientId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete client
  Future<bool> deleteClient(String clientId) async {
    try {
      await _clients.doc(clientId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Restore client
  Future<bool> restoreClient(String clientId) async {
    try {
      await _clients.doc(clientId).update({'isActive': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get client statistics
  Future<ClientStats> getClientStats({String? ownerId}) async {
    try {
      Query<Map<String, dynamic>> query = _clients;
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final snapshot = await query.get();
      final clients = snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();

      final activeClients = clients.where((c) => c.isActive).length;
      final totalRevenue = clients.fold<double>(
        0.0,
        (total, client) => total + client.totalRevenue,
      );
      final totalOrders = clients.fold<int>(
        0,
        (total, client) => total + client.totalOrders,
      );

      return ClientStats(
        totalClients: clients.length,
        activeClients: activeClients,
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
      );
    } catch (e) {
      return ClientStats.empty;
    }
  }

  // Watch all clients stream
  Stream<List<ClientModel>> watchAllClients({String? ownerId}) {
    Query<Map<String, dynamic>> query = _clients;
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return query.snapshots().map((snapshot) {
      final clients = snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
      clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return clients;
    });
  }

  // Watch active clients stream
  Stream<List<ClientModel>> watchActiveClients({String? ownerId}) {
    Query<Map<String, dynamic>> query = _clients.where(
      'isActive',
      isEqualTo: true,
    );
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return query.snapshots().map((snapshot) {
      final clients = snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
      clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return clients;
    });
  }

  // Watch single client stream
  Stream<ClientModel?> watchClient(String clientId) {
    return _clients.doc(clientId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClientModel.fromFirestore(doc);
    });
  }
}

class ClientStats {
  final int totalClients;
  final int activeClients;
  final double totalRevenue;
  final int totalOrders;

  const ClientStats({
    required this.totalClients,
    required this.activeClients,
    required this.totalRevenue,
    required this.totalOrders,
  });

  static const ClientStats empty = ClientStats(
    totalClients: 0,
    activeClients: 0,
    totalRevenue: 0.0,
    totalOrders: 0,
  );

  double get averageRevenuePerClient =>
      totalClients > 0 ? totalRevenue / totalClients : 0.0;
  double get averageOrdersPerClient =>
      totalClients > 0 ? totalOrders / totalClients : 0.0;
  double get clientActivityRate =>
      totalClients > 0 ? activeClients / totalClients : 0.0;
}
