import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../models/customer_profile.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';

class CustomerProfileModal extends StatefulWidget {
  const CustomerProfileModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomerProfileModal(),
    );
  }

  @override
  State<CustomerProfileModal> createState() => _CustomerProfileModalState();
}

class _CustomerProfileModalState extends State<CustomerProfileModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedGroup;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppStateProvider>().customerProfile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone);
    _selectedGroup = profile.bloodGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppStateProvider>();
    final newProfile = CustomerProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bloodGroup: _selectedGroup,
    );

    appState.updateCustomerProfile(newProfile);
    appState.setBloodGroupFilter(_selectedGroup);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer details saved successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Recipient Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'No login required • Saved on your device',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Customer Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer / Patient Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter your name';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Mobile Number in India (+91)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (India)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+91 98765 43210',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter your mobile number';
                  if (val.trim().length < 8) return 'Enter a valid mobile number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Blood Group Selection
              const Text(
                'Required Blood Group:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BloodBank.standardBloodGroups.map((group) {
                  final isSelected = _selectedGroup == group;
                  return ChoiceChip(
                    label: Text(group),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedGroup = group);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save & Find Blood Banks', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
