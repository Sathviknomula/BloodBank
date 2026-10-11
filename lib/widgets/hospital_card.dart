import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/blood_bank.dart';
import '../theme/app_colors.dart';

class HospitalCard extends StatelessWidget {
  final BloodBank hospital;
  final String selectedBloodGroup;
  final double distanceKm;
  final String travelTime;
  final String etaClock;
  final VoidCallback onTrackRoute;
  final VoidCallback onRequestBlood;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.selectedBloodGroup,
    required this.distanceKm,
    required this.travelTime,
    required this.etaClock,
    required this.onTrackRoute,
    required this.onRequestBlood,
  });

  Future<void> _makeCall(String phoneNumber) async {
    // Sanitize phone for tel: scheme
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = selectedBloodGroup != 'All';
    final sachetCount = hasFilter ? hospital.getSachets(selectedBloodGroup) : hospital.totalUnits;
    final isAvailable = sachetCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable ? AppColors.border : Colors.red.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Hospital Name & Verification
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hospital.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hospital.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Middle Bar: Stock Indicator & Distance/ETA in India
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceVariant.withAlpha(100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stock Availability Badge
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailable ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasFilter
                          ? '$sachetCount Sachets ($selectedBloodGroup)'
                          : '$sachetCount Units Total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isAvailable ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),

                // Distance and ETA pill
                Row(
                  children: [
                    const Icon(Icons.navigation_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '$distanceKm km',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        travelTime,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contact Details in India & Action Buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Phone number info row
                Row(
                  children: [
                    const Icon(Icons.call_rounded, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Helpline: ${hospital.phone}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _makeCall(hospital.phone),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Call Hospital',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons: Track Route & Request Blood
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: OutlinedButton.icon(
                        onPressed: onTrackRoute,
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('Track Route'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: isAvailable ? onRequestBlood : null,
                        icon: const Icon(Icons.bloodtype_rounded, size: 18),
                        label: const Text('Request Blood'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
