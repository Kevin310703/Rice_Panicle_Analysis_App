import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/widgets/custom_textfield.dart';

class HillDialogResult {
  final String label;
  final String note;

  const HillDialogResult({
    required this.label,
    required this.note,
  });
}

class CreateHillDialog extends StatefulWidget {
  const CreateHillDialog({super.key});

  @override
  State<CreateHillDialog> createState() => _CreateHillDialogState();

  static Future<HillDialogResult?> show(BuildContext context) {
    return showDialog<HillDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateHillDialog(),
    );
  }
}

class _CreateHillDialogState extends State<CreateHillDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.create_new_folder_rounded,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Create new hill',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Enter a name for your new hill',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Input fields
            CustomTextfield(
              label: 'Hill name',
              prefixIcon: Icons.folder_outlined,
              controller: _labelController,
            ),
            const SizedBox(height: 13),
            CustomTextfield(
              label: 'Note',
              prefixIcon: Icons.notes_outlined,
              controller: _noteController,
            ),

            const SizedBox(height: 28),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final name = _labelController.text.trim();
                    final note = _noteController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(
                      context,
                      HillDialogResult(label: name, note: note),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create hill',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}