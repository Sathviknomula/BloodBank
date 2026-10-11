import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/blood_group_chip.dart';
import '../../widgets/emergency_ambulance_fab.dart';
import '../../widgets/hospital_card.dart';
import 'customer_profile_modal.dart';
import 'request_blood_dialog.dart';
import 'route_tracking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  double? _selectedMaxDistance; // null = all nearby

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCitySelectorSheet(BuildContext context) {
    final locProvider = context.read<LocationProvider>();
    final accuracy = locProvider.gpsAccuracyMeters;
    final pos = locProvider.currentLocation;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Live Device Location & GPS Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                locProvider.gpsStatusMessage,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // True GPS Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: locProvider.isUsingGps ? AppColors.accentLight : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: locProvider.isUsingGps ? AppColors.accent.withAlpha(80) : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          locProvider.isUsingGps ? Icons.gps_fixed : Icons.gps_off,
                          color: locProvider.isUsingGps ? AppColors.accent : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          locProvider.isUsingGps
                              ? 'True Hardware GPS Fix'
                              : 'GPS Not Locked',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: locProvider.isUsingGps ? AppColors.accent : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (locProvider.isUsingGps && accuracy != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '±${accuracy.toStringAsFixed(1)}m',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coordinates: ${pos.latitude.toStringAsFixed(5)}°, ${pos.longitude.toStringAsFixed(5)}°',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              locProvider.refreshGpsLocation();
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Scan True GPS', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            locProvider.openLocationSettings();
                          },
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('GPS Settings', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Or Test with City Presets:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              ...LocationProvider.indianCityPresets.map((city) {
                final isSel = !locProvider.isUsingGps && locProvider.currentCityName == city.name;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    Icons.location_city_rounded,
                    color: isSel ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(
                    city.name,
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      color: isSel ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSel ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    locProvider.setCityPreset(city);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final locProvider = context.watch<LocationProvider>();
    final profile = appState.customerProfile;

    // Filter and sort hospitals by proximity
    final allFiltered = appState.filteredBloodBanks;
    final sortedHospitals = List<BloodBank>.from(allFiltered);
    sortedHospitals.sort((a, b) {
      final distA = locProvider.getDistanceKm(a);
      final distB = locProvider.getDistanceKm(b);
      return distA.compareTo(distB);
    });

    // Apply distance radius filter if selected
    final nearbyHospitals = _selectedMaxDistance == null
        ? sortedHospitals
        : sortedHospitals.where((h) => locProvider.getDistanceKm(h) <= _selectedMaxDistance!).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Nearby Blood Banks',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // City/Location pill with pleasant styling
          InkWell(
            onTap: () => _showCitySelectorSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: locProvider.isUsingGps ? Colors.green : AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    locProvider.isUsingGps
                        ? 'Live GPS (±${(locProvider.gpsAccuracyMeters ?? 4.0).toStringAsFixed(0)}m)'
                        : locProvider.currentCityName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await locProvider.refreshGpsLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Customer Recipient Profile Card (Pleasant Soft Rose Gradient)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE57373), Color(0xFFD9534F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(45),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Blood Group Circle Badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          profile.bloodGroup,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Customer Name & Mobile
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile.name.isEmpty ? 'Customer Recipient' : profile.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Ready',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Mobile: ${profile.phone}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(220),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit Profile Button
                    IconButton.filled(
                      tooltip: 'Edit Recipient Details',
                      onPressed: () => CustomerProfileModal.show(context),
                      icon: const Icon(Icons.edit_rounded, size: 17),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Search Field
              TextField(
                controller: _searchController,
                onChanged: (val) => appState.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search hospital, locality or city...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            appState.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),

              // 3. Proximity Radius Chips Filter
              Row(
                children: [
                  const Icon(Icons.near_me_rounded, size: 15, color: AppColors.accent),
                  const SizedBox(width: 6),
                  const Text(
                    'Proximity Distance:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDistanceFilterChip(null, 'All Nearby'),
                          _buildDistanceFilterChip(5.0, '< 5 km'),
                          _buildDistanceFilterChip(10.0, '< 10 km'),
                          _buildDistanceFilterChip(25.0, '< 25 km'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Blood Group Filter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Blood Group Needed',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (appState.selectedBloodGroupFilter != 'All')
                    TextButton(
                      onPressed: () => appState.setBloodGroupFilter('All'),
                      child: const Text('Show All', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Blood Group Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    BloodGroupChip(
                      label: 'All Groups',
                      isSelected: appState.selectedBloodGroupFilter == 'All',
                      onTap: () => appState.setBloodGroupFilter('All'),
                    ),
                    ...BloodBank.standardBloodGroups.map((group) {
                      return BloodGroupChip(
                        label: group,
                        isSelected: appState.selectedBloodGroupFilter == group,
                        onTap: () => appState.setBloodGroupFilter(group),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 5. Hospitals List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hospitals in Nearby Proximity (${nearbyHospitals.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.sort_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Closest First',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 6. Hospital Cards
              if (nearbyHospitals.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No Blood Banks in This Distance',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No hospitals matching your radius or blood group filter were found. Try selecting "All Nearby" or choosing another city.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedMaxDistance = null);
                          appState.setBloodGroupFilter('All');
                          _searchController.clear();
                          appState.setSearchQuery('');
                        },
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ...nearbyHospitals.map((hospital) {
                  final dist = locProvider.getDistanceKm(hospital);
                  final timeStr = locProvider.formatTravelTime(hospital);
                  final etaClock = locProvider.getEtaClockTime(hospital);
                  final targetBloodGroup = appState.selectedBloodGroupFilter != 'All'
                      ? appState.selectedBloodGroupFilter
                      : profile.bloodGroup;

                  return HospitalCard(
                    hospital: hospital,
                    selectedBloodGroup: appState.selectedBloodGroupFilter,
                    distanceKm: dist,
                    travelTime: timeStr,
                    etaClock: etaClock,
                    onTrackRoute: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteTrackingScreen(
                            hospital: hospital,
                            bloodGroup: targetBloodGroup,
                          ),
                        ),
                      );
                    },
                    onRequestBlood: () {
                      RequestBloodDialog.show(context, hospital, targetBloodGroup);
                    },
                  );
                }),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: const EmergencyAmbulanceFab(),
    );
  }

  Widget _buildDistanceFilterChip(double? distance, String label) {
    final isSelected = _selectedMaxDistance == distance;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.accentLight,
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: 1.2,
        ),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
        onSelected: (val) {
          if (val) setState(() => _selectedMaxDistance = distance);
        },
      ),
    );
  }
}
