import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/cargo_model.dart';
import '../../models/client_model.dart';
import '../services/client_service.dart';

enum ExportFormat {
  csv,
  json,
  txt,
}

enum ExportType {
  cargo,
  client,
  analytics,
  all,
}

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final ClientService _clientService = ClientService.instance;

  /// Export data to specified format
  Future<String> exportData({
    required ExportType type,
    required ExportFormat format,
    DateTime? startDate,
    DateTime? endDate,
    List<CargoModel>? cargoData,
  }) async {
    try {
      switch (type) {
        case ExportType.cargo:
          return await _exportCargoData(format, startDate, endDate, cargoData);
        case ExportType.client:
          return await _exportClientData(format, startDate, endDate);
        case ExportType.analytics:
          return await _exportAnalyticsData(format, startDate, endDate, cargoData);
        case ExportType.all:
          return await _exportAllData(format, startDate, endDate, cargoData);
      }
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  /// Export cargo data
  Future<String> _exportCargoData(ExportFormat format, DateTime? startDate, DateTime? endDate, List<CargoModel>? cargoData) async {
    // Use provided cargo data or get from providers
    final cargos = cargoData ?? [];
    
    // Filter by date range if provided
    final filteredCargos = _filterByDateRange(cargos, startDate, endDate);

    switch (format) {
      case ExportFormat.csv:
        return await _exportCargoToCsv(filteredCargos);
      case ExportFormat.json:
        return await _exportCargoToJson(filteredCargos);
      case ExportFormat.txt:
        return await _exportCargoToTxt(filteredCargos);
    }
  }

  /// Export client data
  Future<String> _exportClientData(ExportFormat format, DateTime? startDate, DateTime? endDate) async {
    final clients = await _clientService.getAllClients();
    
    // Filter by date range if provided
    final filteredClients = _filterByDateRange(clients, startDate, endDate);

    switch (format) {
      case ExportFormat.csv:
        return await _exportClientToCsv(filteredClients);
      case ExportFormat.json:
        return await _exportClientToJson(filteredClients);
      case ExportFormat.txt:
        return await _exportClientToTxt(filteredClients);
    }
  }

  /// Export analytics data
  Future<String> _exportAnalyticsData(ExportFormat format, DateTime? startDate, DateTime? endDate, List<CargoModel>? cargoData) async {
    final cargos = cargoData ?? [];
    final clients = await _clientService.getAllClients();
    
    final filteredCargos = _filterByDateRange(cargos, startDate, endDate);
    final filteredClients = _filterByDateRange(clients, startDate, endDate);

    final analytics = _generateAnalytics(filteredCargos, filteredClients);

    switch (format) {
      case ExportFormat.csv:
        return await _exportAnalyticsToCsv(analytics);
      case ExportFormat.json:
        return await _exportAnalyticsToJson(analytics);
      case ExportFormat.txt:
        return await _exportAnalyticsToTxt(analytics);
    }
  }

  /// Export all data
  Future<String> _exportAllData(ExportFormat format, DateTime? startDate, DateTime? endDate, List<CargoModel>? cargoData) async {
    final cargos = cargoData ?? [];
    final clients = await _clientService.getAllClients();
    
    final filteredCargos = _filterByDateRange(cargos, startDate, endDate);
    final filteredClients = _filterByDateRange(clients, startDate, endDate);

    switch (format) {
      case ExportFormat.csv:
        return await _exportAllToCsv(filteredCargos, filteredClients);
      case ExportFormat.json:
        return await _exportAllToJson(filteredCargos, filteredClients);
      case ExportFormat.txt:
        return await _exportAllToTxt(filteredCargos, filteredClients);
    }
  }

  /// Filter data by date range
  List<T> _filterByDateRange<T>(List<T> items, DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return items;

    return items.where((item) {
      DateTime? itemDate;
      
      if (item is CargoModel) {
        itemDate = item.createdAt;
      } else if (item is ClientModel) {
        itemDate = item.createdAt;
      }

      if (itemDate == null) return false;

      if (startDate != null && itemDate.isBefore(startDate)) return false;
      if (endDate != null && itemDate.isAfter(endDate)) return false;

      return true;
    }).toList();
  }

  /// Generate analytics data
  Map<String, dynamic> _generateAnalytics(List<CargoModel> cargos, List<ClientModel> clients) {
    final totalCargos = cargos.length;
    final deliveredCargos = cargos.where((c) => c.status == 'Delivered').length;
    final inTransitCargos = cargos.where((c) => c.status == 'In Transit').length;
    final totalRevenue = cargos.fold<double>(0.0, (sum, cargo) => sum + 10000.0); // Placeholder price

    final totalClients = clients.length;
    final activeClients = clients.where((c) => c.isActive).length;
    final clientRevenue = clients.fold<double>(0.0, (sum, client) => sum + client.totalRevenue);

    return {
      'cargo_stats': {
        'total': totalCargos,
        'delivered': deliveredCargos,
        'in_transit': inTransitCargos,
        'delivery_rate': totalCargos > 0 ? (deliveredCargos / totalCargos * 100).toStringAsFixed(2) : '0.00',
        'total_revenue': totalRevenue.toStringAsFixed(2),
      },
      'client_stats': {
        'total': totalClients,
        'active': activeClients,
        'inactive': totalClients - activeClients,
        'total_revenue': clientRevenue.toStringAsFixed(2),
        'average_revenue': totalClients > 0 ? (clientRevenue / totalClients).toStringAsFixed(2) : '0.00',
      },
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Export cargo to CSV
  Future<String> _exportCargoToCsv(List<CargoModel> cargos) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Title,From,To,Status,Created At,Driver ID');
    
    for (final cargo in cargos) {
      buffer.writeln([
        cargo.id,
        cargo.title,
        cargo.from,
        cargo.to,
        cargo.status,
        cargo.createdAt?.toIso8601String() ?? '',
        cargo.driverId ?? '',
      ].join(','));
    }

    return await _saveToFile(buffer.toString(), 'cargo_export_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  /// Export client to CSV
  Future<String> _exportClientToCsv(List<ClientModel> clients) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Name,Phone,Email,Company,Active,Total Revenue,Total Orders,Created At');
    
    for (final client in clients) {
      buffer.writeln([
        client.id,
        client.name,
        client.phone ?? '',
        client.email ?? '',
        client.company ?? '',
        client.isActive.toString(),
        client.totalRevenue.toStringAsFixed(2),
        client.totalOrders.toString(),
        client.createdAt.toIso8601String(),
      ].join(','));
    }

    return await _saveToFile(buffer.toString(), 'client_export_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  /// Export analytics to CSV
  Future<String> _exportAnalyticsToCsv(Map<String, dynamic> analytics) async {
    final buffer = StringBuffer();
    buffer.writeln('Metric,Value');
    buffer.writeln('Total Cargos,${analytics['cargo_stats']['total']}');
    buffer.writeln('Delivered Cargos,${analytics['cargo_stats']['delivered']}');
    buffer.writeln('In Transit Cargos,${analytics['cargo_stats']['in_transit']}');
    buffer.writeln('Delivery Rate (%),${analytics['cargo_stats']['delivery_rate']}');
    buffer.writeln('Total Revenue (Cargos),${analytics['cargo_stats']['total_revenue']}');
    buffer.writeln('Total Clients,${analytics['client_stats']['total']}');
    buffer.writeln('Active Clients,${analytics['client_stats']['active']}');
    buffer.writeln('Inactive Clients,${analytics['client_stats']['inactive']}');
    buffer.writeln('Total Revenue (Clients),${analytics['client_stats']['total_revenue']}');
    buffer.writeln('Average Revenue per Client,${analytics['client_stats']['average_revenue']}');
    buffer.writeln('Generated At,${analytics['generated_at']}');

    return await _saveToFile(buffer.toString(), 'analytics_export_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  /// Export all data to CSV
  Future<String> _exportAllToCsv(List<CargoModel> cargos, List<ClientModel> clients) async {
    final buffer = StringBuffer();
    
    // Cargo section
    buffer.writeln('=== CARGO DATA ===');
    buffer.writeln('ID,Title,From,To,Status,Created At,Driver ID');
    for (final cargo in cargos) {
      buffer.writeln([
        cargo.id,
        cargo.title,
        cargo.from,
        cargo.to,
        cargo.status,
        cargo.createdAt?.toIso8601String() ?? '',
        cargo.driverId ?? '',
      ].join(','));
    }
    
    buffer.writeln('\n=== CLIENT DATA ===');
    buffer.writeln('ID,Name,Phone,Email,Company,Active,Total Revenue,Total Orders,Created At');
    for (final client in clients) {
      buffer.writeln([
        client.id,
        client.name,
        client.phone ?? '',
        client.email ?? '',
        client.company ?? '',
        client.isActive.toString(),
        client.totalRevenue.toStringAsFixed(2),
        client.totalOrders.toString(),
        client.createdAt.toIso8601String(),
      ].join(','));
    }

    return await _saveToFile(buffer.toString(), 'all_data_export_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  /// Export cargo to JSON
  Future<String> _exportCargoToJson(List<CargoModel> cargos) async {
    final jsonData = {
      'type': 'cargo_export',
      'generated_at': DateTime.now().toIso8601String(),
      'total_count': cargos.length,
      'data': cargos.map((cargo) => cargo.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    return await _saveToFile(jsonString, 'cargo_export_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  /// Export client to JSON
  Future<String> _exportClientToJson(List<ClientModel> clients) async {
    final jsonData = {
      'type': 'client_export',
      'generated_at': DateTime.now().toIso8601String(),
      'total_count': clients.length,
      'data': clients.map((client) => client.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    return await _saveToFile(jsonString, 'client_export_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  /// Export analytics to JSON
  Future<String> _exportAnalyticsToJson(Map<String, dynamic> analytics) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(analytics);
    return await _saveToFile(jsonString, 'analytics_export_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  /// Export all data to JSON
  Future<String> _exportAllToJson(List<CargoModel> cargos, List<ClientModel> clients) async {
    final jsonData = {
      'type': 'full_export',
      'generated_at': DateTime.now().toIso8601String(),
      'cargo_data': {
        'total_count': cargos.length,
        'data': cargos.map((cargo) => cargo.toMap()).toList(),
      },
      'client_data': {
        'total_count': clients.length,
        'data': clients.map((client) => client.toMap()).toList(),
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    return await _saveToFile(jsonString, 'full_export_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  /// Export cargo to TXT
  Future<String> _exportCargoToTxt(List<CargoModel> cargos) async {
    final buffer = StringBuffer();
    buffer.writeln('CARGO EXPORT REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Cargos: ${cargos.length}');
    buffer.writeln('\n');
    
    for (final cargo in cargos) {
      buffer.writeln('ID: ${cargo.id}');
      buffer.writeln('Title: ${cargo.title}');
      buffer.writeln('From: ${cargo.from}');
      buffer.writeln('To: ${cargo.to}');
      buffer.writeln('Status: ${cargo.status}');
      buffer.writeln('Created: ${cargo.createdAt}');
      buffer.writeln('Driver: ${cargo.driverId ?? 'N/A'}');
      buffer.writeln('---');
    }

    return await _saveToFile(buffer.toString(), 'cargo_export_${DateTime.now().millisecondsSinceEpoch}.txt');
  }

  /// Export client to TXT
  Future<String> _exportClientToTxt(List<ClientModel> clients) async {
    final buffer = StringBuffer();
    buffer.writeln('CLIENT EXPORT REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Clients: ${clients.length}');
    buffer.writeln('\n');
    
    for (final client in clients) {
      buffer.writeln('ID: ${client.id}');
      buffer.writeln('Name: ${client.name}');
      buffer.writeln('Phone: ${client.phone ?? 'N/A'}');
      buffer.writeln('Email: ${client.email ?? 'N/A'}');
      buffer.writeln('Company: ${client.company ?? 'N/A'}');
      buffer.writeln('Active: ${client.isActive}');
      buffer.writeln('Total Revenue: ${client.totalRevenue}');
      buffer.writeln('Total Orders: ${client.totalOrders}');
      buffer.writeln('Created: ${client.createdAt}');
      buffer.writeln('---');
    }

    return await _saveToFile(buffer.toString(), 'client_export_${DateTime.now().millisecondsSinceEpoch}.txt');
  }

  /// Export analytics to TXT
  Future<String> _exportAnalyticsToTxt(Map<String, dynamic> analytics) async {
    final buffer = StringBuffer();
    buffer.writeln('ANALYTICS EXPORT REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('\n');
    
    buffer.writeln('CARGO STATISTICS:');
    buffer.writeln('Total Cargos: ${analytics['cargo_stats']['total']}');
    buffer.writeln('Delivered: ${analytics['cargo_stats']['delivered']}');
    buffer.writeln('In Transit: ${analytics['cargo_stats']['in_transit']}');
    buffer.writeln('Delivery Rate: ${analytics['cargo_stats']['delivery_rate']}%');
    buffer.writeln('Total Revenue: ${analytics['cargo_stats']['total_revenue']}');
    buffer.writeln('\n');
    
    buffer.writeln('CLIENT STATISTICS:');
    buffer.writeln('Total Clients: ${analytics['client_stats']['total']}');
    buffer.writeln('Active: ${analytics['client_stats']['active']}');
    buffer.writeln('Inactive: ${analytics['client_stats']['inactive']}');
    buffer.writeln('Total Revenue: ${analytics['client_stats']['total_revenue']}');
    buffer.writeln('Average Revenue: ${analytics['client_stats']['average_revenue']}');

    return await _saveToFile(buffer.toString(), 'analytics_export_${DateTime.now().millisecondsSinceEpoch}.txt');
  }

  /// Export all data to TXT
  Future<String> _exportAllToTxt(List<CargoModel> cargos, List<ClientModel> clients) async {
    final buffer = StringBuffer();
    buffer.writeln('COMPLETE DATA EXPORT REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('\n');
    
    buffer.writeln('SUMMARY:');
    buffer.writeln('Total Cargos: ${cargos.length}');
    buffer.writeln('Total Clients: ${clients.length}');
    buffer.writeln('\n');
    
    buffer.writeln('CARGO DATA:');
    for (final cargo in cargos.take(10)) { // Limit to first 10 for demo
      buffer.writeln('${cargo.id}: ${cargo.title} - ${cargo.status}');
    }
    if (cargos.length > 10) {
      buffer.writeln('... and ${cargos.length - 10} more');
    }
    
    buffer.writeln('\nCLIENT DATA:');
    for (final client in clients.take(10)) { // Limit to first 10 for demo
      buffer.writeln('${client.id}: ${client.name} - ${client.isActive ? 'Active' : 'Inactive'}');
    }
    if (clients.length > 10) {
      buffer.writeln('... and ${clients.length - 10} more');
    }

    return await _saveToFile(buffer.toString(), 'full_export_${DateTime.now().millisecondsSinceEpoch}.txt');
  }

  /// Save data to file and return path
  Future<String> _saveToFile(String data, String filename) async {
    try {
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/$filename');
      await file.writeAsString(data);
      return file.path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      rethrow;
    }
  }

  /// Get export file info
  Map<String, dynamic> getExportFileInfo(String filePath) {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();
    final lastModified = file.lastModifiedSync();

    return {
      'name': fileName,
      'path': filePath,
      'size': fileSize,
      'last_modified': lastModified.toIso8601String(),
      'exists': file.existsSync(),
    };
  }
}
