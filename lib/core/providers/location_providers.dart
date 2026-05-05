import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

// Current position stream
final currentPositionProvider = StreamProvider<Position>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  
  // Start tracking when provider is first used
  ref.onDispose(() {
    locationService.stopLocationTracking();
  });

  return locationService.positionStream;
});

// Location permission status
final locationPermissionProvider = StateNotifierProvider<LocationPermissionNotifier, LocationPermissionStatus>((ref) {
  return LocationPermissionNotifier(ref);
});

// Location tracking state
final locationTrackingProvider = StateNotifierProvider<LocationTrackingNotifier, bool>((ref) {
  return LocationTrackingNotifier(ref);
});

class LocationPermissionNotifier extends StateNotifier<LocationPermissionStatus> {
  LocationPermissionNotifier(this.ref) : super(LocationPermissionStatus.unknown);
  final Ref ref;

  Future<void> checkPermission() async {
    state = LocationPermissionStatus.checking;
    
    final locationService = ref.read(locationServiceProvider);
    final hasPermission = await locationService.checkLocationPermission();
    
    state = hasPermission ? LocationPermissionStatus.granted : LocationPermissionStatus.denied;
  }

  Future<void> requestPermission() async {
    state = LocationPermissionStatus.checking;
    
    final locationService = ref.read(locationServiceProvider);
    final granted = await locationService.requestLocationPermission();
    
    state = granted ? LocationPermissionStatus.granted : LocationPermissionStatus.denied;
  }
}

class LocationTrackingNotifier extends StateNotifier<bool> {
  LocationTrackingNotifier(this.ref) : super(false);
  final Ref ref;

  void startTracking() async {
    if (state) return;
    
    final locationService = ref.read(locationServiceProvider);
    final hasPermission = await locationService.checkLocationPermission();
    
    if (hasPermission) {
      locationService.startLocationTracking();
      state = true;
    }
  }

  void stopTracking() {
    if (!state) return;
    
    final locationService = ref.read(locationServiceProvider);
    locationService.stopLocationTracking();
    state = false;
  }

  void toggleTracking() {
    if (state) {
      stopTracking();
    } else {
      startTracking();
    }
  }
}

enum LocationPermissionStatus {
  unknown,
  checking,
  granted,
  denied,
}
