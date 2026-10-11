import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';

class AddHospitalDialog extends StatefulWidget {
  const AddHospitalDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AddHospitalDialog(),
    );
  }

  @override
  State<AddHospitalDialog> createState() => _AddHospitalDialogState();
}

class _AddHospitalDialogState extends State<AddHospitalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Hyderabad');
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+91 ');
  final _emergencyCtrl = TextEditingController(text: '+91 ');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'pass123');
  final _latCtrl = TextEditingController(text: '17.4300');
  final _lngCtrl = TextEditingController(text: '78.4300');

  final Map<String, TextEditingController> _stockCtrls = {
    for (var g in BloodBank.standardBloodGroups) g: TextEditingController(text: '15')
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    for (var c in _stockCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final initialStock = <String, int>{};
    for (var entry in _stockCtrls.entries) {
      initialStock[entry.key] = int.tryParse(entry.value.text.trim()) ?? 10;
    }

    final newBank = BloodBank(
      id: 'bb_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      emergencyPhone: _emergencyCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text.trim()) ?? 17.4300,
      longitude: double.tryParse(_lngCtrl.text.trim()) ?? 78.4300,
      operatingHours: '24/7 Open',
      managerEmail: _emailCtrl.text.trim(),
      managerPassword: _passCtrl.text.trim(),
      stock: initialStock,
    );

    context.read<AppStateProvider>().addHospital(newBank);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newBank.name} registered successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_business_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text('Add New Blood Bank', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Hospital Name *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(labelText: 'City *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Contact Phone *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Street Address *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Manager Email *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(labelText: 'Password *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(labelText: 'Longitude'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initial Blood Stock (Sachets):',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BloodBank.standardBloodGroups.map((g) {
                    return SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _stockCtrls[g],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: g,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Register Hospital'),
        ),
      ],
    );
  }
}
