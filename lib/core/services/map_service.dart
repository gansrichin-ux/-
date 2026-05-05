import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';

class MapService {
  MapService._();
  static final MapService instance = MapService._();

  // Default center (Moscow)
  static const LatLng defaultCenter = LatLng(55.7558, 37.6173);

  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final parts = [
          placemark.thoroughfare,
          placemark.subThoroughfare,
          placemark.locality,
        ].where((part) => part?.isNotEmpty == true);
        
        return parts.join(', ');
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  List<LatLng> createRoutePoints(LatLng start, LatLng end, {int numberOfPoints = 10}) {
    final points = <LatLng>[];
    
    for (int i = 0; i <= numberOfPoints; i++) {
      final fraction = i / numberOfPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }

  Marker createMarker({
    required LatLng point,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Polyline createPolyline({
    required List<LatLng> points,
    required Color color,
    double strokeWidth = 4.0,
  }) {
    return Polyline(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  CircleMarker createCircle({
    required LatLng point,
    required double radius,
    required Color color,
  }) {
    return CircleMarker(
      point: point,
      radius: radius,
      color: color.withOpacity(0.3),
      borderColor: color,
      borderStrokeWidth: 2.0,
    );
  }

  // Calculate bounds to fit all points
  LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(defaultCenter, defaultCenter);
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}
