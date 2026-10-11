import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/blood_bank.dart';
import '../../providers/location_provider.dart';
import '../../services/route_service.dart';
import '../../theme/app_colors.dart';

class RouteTrackingScreen extends StatefulWidget {
  final BloodBank hospital;
  final String bloodGroup;

  const RouteTrackingScreen({
    super.key,
    required this.hospital,
    required this.bloodGroup,
  });

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _showTurnSteps = false;
  bool _followUser = true; // Auto-center camera on live user location
  bool _showGpsTelemetry = false;

  List<LatLng> _liveRoutePoints = [];
  bool _isLoadingRoute = true;
  LatLng? _lastCalculatedUserPos;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial route calculation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateRoute();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    final locProvider = context.read<LocationProvider>();
    final userPos = locProvider.currentLocation;
    final destPos = LatLng(widget.hospital.latitude, widget.hospital.longitude);

    _lastCalculatedUserPos = userPos;
    setState(() => _isLoadingRoute = true);

    final points = await RouteService.fetchRealRouteCoordinates(userPos, destPos);
    if (mounted) {
      setState(() {
        _liveRoutePoints = points;
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _callHospital(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _recenterMap(LatLng userPos, LatLng hospitalPos) {
    setState(() => _followUser = false);
    final centerLat = (userPos.latitude + hospitalPos.latitude) / 2.0;
    final centerLng = (userPos.longitude + hospitalPos.longitude) / 2.0;
    _mapController.move(LatLng(centerLat, centerLng), 13.5);
  }

  void _centerOnUser(LatLng userPos) {
    setState(() => _followUser = true);
    _mapController.move(userPos, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProvider>();
    final userPos = locProvider.currentLocation;
    final hospitalPos = LatLng(widget.hospital.latitude, widget.hospital.longitude);

    final distanceKm = locProvider.getDistanceKm(widget.hospital);
    final travelTimeStr = locProvider.formatTravelTime(widget.hospital);
    final etaClock = locProvider.getEtaClockTime(widget.hospital);
    final accuracyMeters = locProvider.gpsAccuracyMeters;
    final speedKmh = locProvider.currentSpeedKmh;
    final heading = locProvider.currentHeadingDegrees;

    // If user moves more than 40 meters from last route start, recalculate road path
    if (_lastCalculatedUserPos != null) {
      final diff = (userPos.latitude - _lastCalculatedUserPos!.latitude).abs() +
          (userPos.longitude - _lastCalculatedUserPos!.longitude).abs();
      if (diff > 0.0004 && !_isLoadingRoute) {
        _calculateRoute();
      }
    }

    // Auto-center camera if follow mode is active
    if (_followUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(userPos, _mapController.camera.zoom);
        }
      });
    }

    final routePoints = _liveRoutePoints.isNotEmpty
        ? _liveRoutePoints
        : RouteService.generateRouteCoordinates(userPos, hospitalPos);

    final navSteps = RouteService.generateNavigationSteps(
      userPos,
      hospitalPos,
      widget.hospital.name,
      distanceKm,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route to ${widget.hospital.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locProvider.isUsingGps ? Colors.green : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    locProvider.isUsingGps
                        ? 'Accurate GPS Active (±${(accuracyMeters ?? 5.0).toStringAsFixed(1)}m)'
                        : 'Simulated / Manual Location',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: locProvider.isUsingGps ? Colors.green.shade800 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _followUser ? 'Camera Following You' : 'Follow User Location',
            icon: Icon(
              _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _followUser ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => _centerOnUser(userPos),
          ),
          IconButton(
            tooltip: 'View Full Route',
            icon: const Icon(Icons.zoom_out_map_rounded, color: AppColors.accent),
            onPressed: () => _recenterMap(userPos, hospitalPos),
          ),
          IconButton(
            tooltip: 'Call Emergency Hotline',
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.danger),
            onPressed: () => _callHospital(widget.hospital.emergencyPhone),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. FlutterMap with OpenStreetMap tiles & Accurate Road Polyline
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                (userPos.latitude + hospitalPos.latitude) / 2.0,
                (userPos.longitude + hospitalPos.longitude) / 2.0,
              ),
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _followUser) {
                  // User panned manually, release follow mode
                  setState(() => _followUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bloodbank.app',
              ),

              // Accuracy Circle around User (reflecting true satellite precision radius)
              if (accuracyMeters != null && accuracyMeters > 0)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: userPos,
                      radius: accuracyMeters.clamp(5.0, 60.0),
                      useRadiusInMeter: true,
                      color: AppColors.accent.withAlpha(28),
                      borderColor: AppColors.accent.withAlpha(120),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Polyline Layer for the route
              PolylineLayer(
                polylines: [
                  // Outer soft glow
                  Polyline(
                    points: routePoints,
                    strokeWidth: 8.0,
                    color: AppColors.primary.withAlpha(50),
                  ),
                  // Core road polyline
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4.5,
                    color: AppColors.primary,
                  ),
                ],
              ),

              // Marker Layer for User & Hospital
              MarkerLayer(
                markers: [
                  // Real-time True User Location Marker with Directional Heading
                  Marker(
                    point: userPos,
                    width: 64,
                    height: 64,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (ctx, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse Halo
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withAlpha(45),
                            ),
                          ),
                          // Directional arrow if moving/heading available
                          if (heading > 0)
                            Transform.rotate(
                              angle: heading * (pi / 180.0),
                              child: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.topCenter,
                                child: Icon(
                                  Icons.navigation_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          // Core GPS Marker Dot
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(35),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Destination Hospital Marker
                  Marker(
                    point: hospitalPos,
                    width: 140,
                    height: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(35),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.hospital.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 38,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Live Tracking Status & Mode Bar
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(245),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(16),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: locProvider.isSimulatingLiveRoute
                          ? Colors.orange
                          : locProvider.isUsingGps
                              ? Colors.green
                              : AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              locProvider.isSimulatingLiveRoute
                                  ? 'Demo Simulation Running'
                                  : locProvider.isUsingGps
                                      ? 'True Live GPS Satellite Tracking'
                                      : 'Tracking Initialized',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          locProvider.isSimulatingLiveRoute
                              ? 'Previewing drive route to hospital'
                              : 'Real-time continuous location updates from device',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Telemetry toggle
                  IconButton(
                    tooltip: 'View Live GPS Precision & Speed',
                    icon: Icon(
                      _showGpsTelemetry ? Icons.info : Icons.info_outline,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showGpsTelemetry = !_showGpsTelemetry),
                  ),
                  // Simulation toggle for testing
                  TextButton.icon(
                    onPressed: () {
                      if (locProvider.isSimulatingLiveRoute) {
                        locProvider.stopNavigationSimulation();
                      } else {
                        locProvider.startNavigationSimulation(widget.hospital);
                      }
                    },
                    icon: Icon(
                      locProvider.isSimulatingLiveRoute
                          ? Icons.stop_circle_outlined
                          : Icons.play_arrow_rounded,
                      size: 17,
                      color: locProvider.isSimulatingLiveRoute
                          ? AppColors.danger
                          : AppColors.primary,
                    ),
                    label: Text(
                      locProvider.isSimulatingLiveRoute ? 'Stop' : 'Simulate',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: locProvider.isSimulatingLiveRoute
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Live GPS Telemetry Overlay (True coordinates, speed, accuracy)
          if (_showGpsTelemetry)
            Positioned(
              top: 76,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(250),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.satellite_alt_rounded, size: 16, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text(
                              'Live GPS Telemetry & Accuracy',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => locProvider.refreshGpsLocation(),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 14, color: AppColors.accent),
                                SizedBox(width: 3),
                                Text(
                                  'Rescan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTelemetryItem(
                          'Latitude',
                          '${userPos.latitude.toStringAsFixed(5)}°',
                        ),
                        _buildTelemetryItem(
                          'Longitude',
                          '${userPos.longitude.toStringAsFixed(5)}°',
                        ),
                        _buildTelemetryItem(
                          'Precision',
                          accuracyMeters != null ? '±${accuracyMeters.toStringAsFixed(1)}m' : 'Calibrating',
                          highlight: accuracyMeters != null && accuracyMeters <= 15.0,
                        ),
                        _buildTelemetryItem(
                          'Speed',
                          '${speedKmh.toStringAsFixed(1)} km/h',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 4. Step-by-Step Guidance overlay if expanded
          if (_showTurnSteps)
            Positioned(
              top: _showGpsTelemetry ? 166 : 76,
              left: 14,
              right: 14,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: navSteps.length,
                  separatorBuilder: (_, index) => const Divider(height: 12),
                  itemBuilder: (ctx, i) {
                    final step = navSteps[i];
                    return Row(
                      children: [
                        Icon(
                          step.iconType == 'arrive'
                              ? Icons.local_hospital
                              : step.iconType == 'turn_right'
                                  ? Icons.turn_right_rounded
                                  : step.iconType == 'turn_left'
                                      ? Icons.turn_left_rounded
                                      : Icons.straight_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.instruction,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${step.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // 5. Bottom Floating HUD Card with Travel Time & Hospital Contact
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Time, Distance & ETA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                travelTimeStr,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ETA $etaClock',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$distanceKm km total distance via live route',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        tooltip: 'View Turn Steps',
                        onPressed: () => setState(() => _showTurnSteps = !_showTurnSteps),
                        icon: Icon(
                          _showTurnSteps ? Icons.expand_less : Icons.alt_route_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Row 2: Hospital Contact & Call Actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hospital.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Phone: ${widget.hospital.phone}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Direct call button
                      ElevatedButton.icon(
                        onPressed: () => _callHospital(widget.hospital.phone),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call Hospital'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: highlight ? Colors.green.shade700 : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
