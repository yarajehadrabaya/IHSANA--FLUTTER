import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'visuospatial/cube_copy_screen.dart';

class OrientationLocationScreen extends StatefulWidget {
  const OrientationLocationScreen({super.key});

  @override
  State<OrientationLocationScreen> createState() =>
      _OrientationLocationScreenState();
}

class _OrientationLocationScreenState
    extends State<OrientationLocationScreen> {
  final _cityController = TextEditingController();
  final _placeController = TextEditingController();

  bool get _canContinue =>
      _cityController.text.isNotEmpty &&
      _placeController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔴 Header
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أين أنت الآن؟',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.popUntil(
                            context, (r) => r.isFirst);
                      },
                      child: const Text(
                        'إنهاء الجلسة',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'يرجى إدخال المدينة والمكان الذي تتواجد فيه حالياً',
                  style:
                      Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // 🏙️ City Field
                _LargeInputField(
                  controller: _cityController,
                  label: 'المدينة',
                  icon: Icons.location_city,
                  onChanged: () => setState(() {}),
                ),

                const SizedBox(height: 20),

                // 📍 Place Field
                _LargeInputField(
                  controller: _placeController,
                  label: 'المكان',
                  icon: Icons.place,
                  onChanged: () => setState(() {}),
                ),

                const Spacer(),

                // ▶️ Continue
                ElevatedButton(
                  onPressed: _canContinue
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CubeCopyScreen(),
                            ),
                          );
                        }
                      : null,
                  child: const Text('متابعة'),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================================================== */
/* ================= Large Input Field ================= */
/* ===================================================== */

class _LargeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onChanged;

  const _LargeInputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
                horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
