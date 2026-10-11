import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StockCounterTile extends StatelessWidget {
  final String bloodGroup;
  final int count;
  final ValueChanged<int> onDelta;
  final ValueChanged<int> onSetExact;

  const StockCounterTile({
    super.key,
    required this.bloodGroup,
    required this.count,
    required this.onDelta,
    required this.onSetExact,
  });

  void _showExactInputDialog(BuildContext context) {
    final controller = TextEditingController(text: count.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set $bloodGroup Sachet Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Number of Sachets',
            hintText: 'e.g. 25',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                onSetExact(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = count < 5;
    final isOut = count == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOut
              ? AppColors.danger.withAlpha(100)
              : isCritical
                  ? AppColors.warning.withAlpha(120)
                  : AppColors.border,
          width: isCritical ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Blood group badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOut
                    ? [Colors.grey.shade400, Colors.grey.shade600]
                    : isCritical
                        ? [AppColors.warning, Colors.deepOrange]
                        : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                bloodGroup,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Label and stock alert
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Group $bloodGroup',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (isOut)
                  const Text(
                    'Critical: Out of Stock',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (isCritical)
                  const Text(
                    'Warning: Low Stock (<5)',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Standard reserve',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Minus Button
          IconButton.filledTonal(
            onPressed: count > 0 ? () => onDelta(-1) : null,
            icon: const Icon(Icons.remove_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Counter display (Tappable)
          GestureDetector(
            onTap: () => _showExactInputDialog(context),
            child: Container(
              constraints: const BoxConstraints(minWidth: 46),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withAlpha(120),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isOut ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'sachets',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Plus Button
          IconButton.filled(
            onPressed: () => onDelta(1),
            icon: const Icon(Icons.add_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
