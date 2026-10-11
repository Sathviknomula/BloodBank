import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blood_bank.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';

class RequestBloodDialog extends StatefulWidget {
  final BloodBank hospital;
  final String bloodGroup;

  const RequestBloodDialog({
    super.key,
    required this.hospital,
    required this.bloodGroup,
  });

  static Future<void> show(BuildContext context, BloodBank hospital, String bloodGroup) {
    return showDialog(
      context: context,
      builder: (_) => RequestBloodDialog(hospital: hospital, bloodGroup: bloodGroup),
    );
  }

  @override
  State<RequestBloodDialog> createState() => _RequestBloodDialogState();
}

class _RequestBloodDialogState extends State<RequestBloodDialog> {
  int _units = 1;
  String _urgency = 'Immediate Emergency';
  final _notesController = TextEditingController();

  final List<String> _urgencyOptions = [
    'Immediate Emergency',
    'Within 4 Hours',
    'Normal / Scheduled',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final profile = appState.customerProfile;
    final maxAvailable = widget.hospital.getSachets(widget.bloodGroup);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bloodtype_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Blood Sachets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  widget.hospital.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 20),

            // Patient details banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name.isEmpty ? 'Recipient' : profile.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          profile.phone,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.bloodGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Number of units/sachets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity (Sachets):',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Max available: $maxAvailable units',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _units > 1 ? () => setState(() => _units--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_units',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton.outlined(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _units < maxAvailable ? () => setState(() => _units++) : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Urgency
            const Text(
              'Urgency Level:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _urgencyOptions.map((opt) {
                final isSel = _urgency == opt;
                final isEmergency = opt.contains('Emergency');
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSel,
                  selectedColor: isEmergency ? AppColors.danger : AppColors.accent,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSel ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _urgency = opt);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Medical Notes / Hospital Ward
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Hospital Ward / Patient Notes (Optional)',
                hintText: 'e.g. ICU Bed 4, Emergency Surgery',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await appState.createBloodRequest(
              hospitalId: widget.hospital.id,
              hospitalName: widget.hospital.name,
              bloodGroup: widget.bloodGroup,
              unitsCount: _units,
              urgencyLevel: _urgency,
              notes: _notesController.text.trim(),
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Order for $_units sachet(s) of ${widget.bloodGroup} sent to ${widget.hospital.name}!',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text('Confirm Request'),
        ),
      ],
    );
  }
}
