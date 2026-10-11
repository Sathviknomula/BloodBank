import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';

class HospitalProfileEdit extends StatefulWidget {
  final BloodBank hospital;

  const HospitalProfileEdit({super.key, required this.hospital});

  @override
  State<HospitalProfileEdit> createState() => _HospitalProfileEditState();
}

class _HospitalProfileEditState extends State<HospitalProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _hoursController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    final h = widget.hospital;
    _nameController = TextEditingController(text: h.name);
    _cityController = TextEditingController(text: h.city);
    _addressController = TextEditingController(text: h.address);
    _phoneController = TextEditingController(text: h.phone);
    _emergencyPhoneController = TextEditingController(text: h.emergencyPhone);
    _hoursController = TextEditingController(text: h.operatingHours);
    _latController = TextEditingController(text: h.latitude.toString());
    _lngController = TextEditingController(text: h.longitude.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _hoursController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim()) ?? widget.hospital.latitude;
    final lng = double.tryParse(_lngController.text.trim()) ?? widget.hospital.longitude;

    final updated = widget.hospital.copyWith(
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
      operatingHours: _hoursController.text.trim(),
      latitude: lat,
      longitude: lng,
    );

    context.read<AppStateProvider>().updateHospital(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hospital profile & contact details updated!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hospital Public Profile & Contacts',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'These details are displayed to customers for emergency calls & navigation.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hospital Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Hospital / Blood Centre Name',
                prefixIcon: Icon(Icons.domain),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City / Region',
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Full Street Address (India)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Primary Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Primary Contact / Helpline Phone (India)',
                prefixIcon: Icon(Icons.phone),
                hintText: '+91 98490 12345',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Emergency Helpline
            TextFormField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '24x7 Emergency Trauma Hotline',
                prefixIcon: Icon(Icons.phone_in_talk, color: AppColors.danger),
                hintText: '+91 40 2360 7777',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Operating Hours
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: 'Operating Hours',
                prefixIcon: Icon(Icons.access_time),
                hintText: 'e.g. 24/7 Open or 8:00 AM - 10:00 PM',
              ),
            ),
            const SizedBox(height: 14),

            // Coordinates Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.my_location),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.my_location),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Profile Updates'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
