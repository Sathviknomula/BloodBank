import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/blood_bank.dart';
import '../services/route_service.dart';

class CityPreset {
  final String name;
  final LatLng coordinates;

  const CityPreset(this.name, this.coordinates);
}

class LocationProvider with ChangeNotifier {
  static const List<CityPreset> indianCityPresets = [
    CityPreset('Hyderabad', LatLng(17.4200, 78.4350)),
    CityPreset('Bengaluru', LatLng(12.9716, 77.5946)),
    CityPreset('Delhi NCR', LatLng(28.6139, 77.2090)),
    CityPreset('Mumbai', LatLng(18.9800, 72.8300)),
    CityPreset('Chennai', LatLng(13.0827, 80.2707)),
  ];

  LatLng _currentLocation = indianCityPresets[0].coordinates;
  Position? _currentPosition;
  String _currentCityName = indianCityPresets[0].name;

  bool _isLoading = false;
  bool _isUsingGps = false;
  bool _isTrackingActive = false;
  bool _isSimulatingLiveRoute = false;

  double? _gpsAccuracyMeters;
  double _currentSpeedKmh = 0.0;
  double _currentHeadingDegrees = 0.0;
  DateTime? _lastGpsTimestamp;
  String _gpsStatusMessage = 'Initializing GPS...';
  LocationPermission _permission = LocationPermission.unableToDetermine;

  Timer? _simulationTimer;
  StreamSubscription<Position>? _positionStreamSub;

  // Getters
  LatLng get currentLocation => _currentLocation;
  Position? get currentPosition => _currentPosition;
  String get currentCityName => _currentCityName;
  bool get isLoading => _isLoading;
  bool get isUsingGps => _isUsingGps;
  bool get isTrackingActive => _isTrackingActive;
  bool get isSimulatingLiveRoute => _isSimulatingLiveRoute;

  double? get gpsAccuracyMeters => _gpsAccuracyMeters;
  double get currentSpeedKmh => _currentSpeedKmh;
  double get currentHeadingDegrees => _currentHeadingDegrees;
  DateTime? get lastGpsTimestamp => _lastGpsTimestamp;
  String get gpsStatusMessage => _gpsStatusMessage;
  LocationPermission get permission => _permission;

  bool get hasAccurateFix =>
      _isUsingGps && _gpsAccuracyMeters != null && _gpsAccuracyMeters! <= 30.0;

  LocationProvider() {
    startLiveTracking();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _positionStreamSub?.cancel();
    super.dispose();
  }

  /// Sets manual city preset (for offline / testing)
  void setCityPreset(CityPreset preset) {
    _simulationTimer?.cancel();
    _isSimulatingLiveRoute = false;
    _currentLocation = preset.coordinates;
    _currentPosition = null;
    _currentCityName = preset.name;
    _isUsingGps = false;
    _gpsAccuracyMeters = null;
    _currentSpeedKmh = 0.0;
    _gpsStatusMessage = 'Manual City Preset: ${preset.name}';
    notifyListeners();
  }

  /// Starts continuous real-time high-accuracy live GPS location stream
  Future<void> startLiveTracking() async {
    _isLoading = true;
    _gpsStatusMessage = 'Acquiring high-precision satellite fix...';
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLoading = false;
        _isUsingGps = false;
        _gpsStatusMessage = 'Location Service (GPS) is turned OFF on device.';
        notifyListeners();
        return;
      }

      _permission = await Geolocator.checkPermission();
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
        if (_permission == LocationPermission.denied) {
          _isLoading = false;
          _isUsingGps = false;
          _gpsStatusMessage = 'Location permission denied by user.';
          notifyListeners();
          return;
        }
      }

      if (_permission == LocationPermission.deniedForever) {
        _isLoading = false;
        _isUsingGps = false;
        _gpsStatusMessage = 'Location permission permanently denied. Open app settings to enable.';
        notifyListeners();
        return;
      }

      // Step 1: Check last known position for instant zero-lag placement
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _currentLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
          _currentPosition = lastKnown;
          _gpsAccuracyMeters = lastKnown.accuracy;
          _isUsingGps = true;
          _currentCityName = 'Live Device Location';
          _gpsStatusMessage = 'Cached Fix: ±${lastKnown.accuracy.toStringAsFixed(1)}m';
          notifyListeners();
        }
      } catch (_) {}

      // Step 2: Acquire fresh high-accuracy satellite lock
      try {
        final freshPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _applyNewPosition(freshPos);
      } catch (_) {
        // If timeout, stream will continue to listen
      }

      // Step 3: Listen continuously to live position stream
      await _positionStreamSub?.cancel();
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1, // update every 1 meter of movement
      );

      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          if (!_isSimulatingLiveRoute) {
            _applyNewPosition(position);
          }
        },
        onError: (error) {
          _gpsStatusMessage = 'GPS Stream Error: $error';
          notifyListeners();
        },
      );

      _isTrackingActive = true;
    } catch (e) {
      _gpsStatusMessage = 'Location error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyNewPosition(Position pos) {
    _currentLocation = LatLng(pos.latitude, pos.longitude);
    _currentPosition = pos;
    _gpsAccuracyMeters = pos.accuracy;
    _currentSpeedKmh = pos.speed > 0 ? (pos.speed * 3.6) : 0.0;
    _currentHeadingDegrees = pos.heading;
    _lastGpsTimestamp = pos.timestamp;
    _isUsingGps = true;
    _currentCityName = 'Live Device Location';

    final accuracyDesc = pos.accuracy <= 10.0
        ? 'High Precision'
        : pos.accuracy <= 30.0
            ? 'Good Fix'
            : 'Coarse Fix';

    _gpsStatusMessage = 'Live GPS: ±${pos.accuracy.toStringAsFixed(1)}m ($accuracyDesc)';
    notifyListeners();
  }

  /// Forces an immediate fresh GPS lock
  Future<void> refreshGpsLocation() async {
    await startLiveTracking();
  }

  /// Opens system location settings if GPS is disabled
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Opens app settings if permissions permanently denied
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Distance in kilometers between current location and blood bank
  double getDistanceKm(BloodBank bank) {
    final distanceMeters = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      bank.latitude,
      bank.longitude,
    );
    return double.parse((distanceMeters / 1000.0).toStringAsFixed(1));
  }

  /// Estimated travel time in minutes based on real-time speed or realistic city traffic
  int getTravelTimeMinutes(BloodBank bank) {
    final distanceKm = getDistanceKm(bank);
    if (distanceKm <= 0.2) return 2;

    // If moving at > 12 km/h, use actual live speed!
    double effectiveSpeedKmh = 32.0;
    if (_currentSpeedKmh >= 12.0) {
      effectiveSpeedKmh = _currentSpeedKmh.clamp(12.0, 90.0);
    }

    final travelMinutes = ((distanceKm / effectiveSpeedKmh) * 60).round() + 2;
    return travelMinutes.clamp(2, 360);
  }

  String formatTravelTime(BloodBank bank) {
    final minutes = getTravelTimeMinutes(bank);
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return remainingMins > 0 ? '${hours}h ${remainingMins}m' : '${hours}h';
  }

  String getEtaClockTime(BloodBank bank) {
    final minutes = getTravelTimeMinutes(bank);
    final arrivalTime = DateTime.now().add(Duration(minutes: minutes));
    final hour = arrivalTime.hour > 12
        ? arrivalTime.hour - 12
        : (arrivalTime.hour == 0 ? 12 : arrivalTime.hour);
    final minute = arrivalTime.minute.toString().padLeft(2, '0');
    final period = arrivalTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Optional simulation mode for testing indoor/emulator without physical movement
  void startNavigationSimulation(BloodBank targetBank) {
    _simulationTimer?.cancel();
    final dest = LatLng(targetBank.latitude, targetBank.longitude);
    final routePoints = RouteService.generateRouteCoordinates(_currentLocation, dest);

    int currentPointIndex = 0;
    _isSimulatingLiveRoute = true;
    _currentSpeedKmh = 38.5; // simulated speed
    _gpsStatusMessage = 'Demo Simulation Active (Drive to ${targetBank.name})';
    notifyListeners();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (currentPointIndex < routePoints.length - 1) {
        currentPointIndex++;
        _currentLocation = routePoints[currentPointIndex];
        notifyListeners();
      } else {
        timer.cancel();
        _isSimulatingLiveRoute = false;
        _currentSpeedKmh = 0.0;
        _gpsStatusMessage = 'Arrived at ${targetBank.name}';
        notifyListeners();
      }
    });
  }

  void stopNavigationSimulation() {
    _simulationTimer?.cancel();
    _isSimulatingLiveRoute = false;
    _currentSpeedKmh = 0.0;
    if (_currentPosition != null) {
      _applyNewPosition(_currentPosition!);
    } else {
      _gpsStatusMessage = 'Live GPS Tracking Active';
      notifyListeners();
    }
  }
}
