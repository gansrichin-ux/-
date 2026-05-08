import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/map_service.dart';
import '../core/providers/location_providers.dart';
import '../models/cargo_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  final CargoModel? cargo;

  const MapScreen({super.key, this.cargo});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService.instance;

  @override
  Widget build(BuildContext context) {
    final currentPosition = ref.watch(currentPositionProvider);
    final isTracking = ref.watch(locationTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cargo != null ? 'Маршрут груза' : 'Карта'),
        actions: [
          IconButton(
            icon: Icon(
              isTracking ? Icons.location_on : Icons.location_off,
              color: isTracking ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              ref.read(locationTrackingProvider.notifier).toggleTracking();
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(55.7558, 37.6173), // Moscow
          initialZoom: 13.0,
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.logist_app',
          ),
          MarkerLayer(
            markers: _buildMarkers(currentPosition),
          ),
          PolylineLayer(
            polylines: _buildPolylines(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _centerOnCurrentPosition(currentPosition),
        child: const Icon(Icons.my_location),
      ),
    );
  }

  List<Marker> _buildMarkers(AsyncValue<Position> currentPosition) {
    final markers = <Marker>[];

    // Current position marker
    currentPosition.when(
      data: (position) {
        markers.add(_mapService.createMarker(
          point: LatLng(position.latitude, position.longitude),
          label: 'Ваше местоположение',
          color: const Color(0xFF3B82F6),
        ));
      },
      loading: () => null,
      error: (error, stackTrace) => null,
    );

    // Add cargo route if provided
    if (widget.cargo != null) {
      final cargo = widget.cargo!;

      // For now, use default coordinates for demo
      // In real app, you would geocode addresses
      final startPoint = const LatLng(55.7558, 37.6173); // Moscow
      final endPoint = const LatLng(59.9343, 30.3351); // St. Petersburg

      markers.add(_mapService.createMarker(
        point: startPoint,
        label: 'Откуда: ${cargo.from}',
        color: const Color(0xFF22C55E),
      ));

      markers.add(_mapService.createMarker(
        point: endPoint,
        label: 'Куда: ${cargo.to}',
        color: const Color(0xFFF59E0B),
      ));

      // Fit map to show entire route
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final routePoints = _mapService.createRoutePoints(startPoint, endPoint);
        final bounds = _mapService.calculateBounds(routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      });
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // Add cargo route if provided
    if (widget.cargo != null) {
      // For now, use default coordinates for demo
      final startPoint = const LatLng(55.7558, 37.6173); // Moscow
      final endPoint = const LatLng(59.9343, 30.3351); // St. Petersburg

      // Add route polyline
      final routePoints = _mapService.createRoutePoints(startPoint, endPoint);
      polylines.add(_mapService.createPolyline(
        points: routePoints,
        color: const Color(0xFF3B82F6),
      ));
    }

    return polylines;
  }

  void _centerOnCurrentPosition(AsyncValue<Position> currentPosition) {
    currentPosition.when(
      data: (position) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      },
      loading: () => null,
      error: (error, stackTrace) => null,
    );
  }
}
