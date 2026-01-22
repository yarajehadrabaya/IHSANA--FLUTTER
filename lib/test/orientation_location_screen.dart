import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ihsana/test/naming/naming_lion_screen.dart';
import 'package:ihsana/test/visuospatial/trail_making_screen.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../session/session_context.dart';
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
  bool _loading = false;

  bool get _canContinue =>
      _cityController.text.isNotEmpty &&
      _placeController.text.isNotEmpty;

  Future<void> _saveLocation() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final sessionId = SessionContext.sessionId!;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'city_before': _cityController.text,
        'place_before': _placeController.text,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CubeCopyScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ أثناء حفظ الموقع')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text('أين أنت الآن؟',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),

                _LargeInputField(
                  controller: _cityController,
                  label: 'المدينة',
                  icon: Icons.location_city,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 20),

                _LargeInputField(
                  controller: _placeController,
                  label: 'المكان',
                  icon: Icons.place,
                  onChanged: () => setState(() {}),
                ),
                const Spacer(),

                ElevatedButton(
                  onPressed:
                      !_canContinue || _loading ? null : _saveLocation,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text('متابعة'),
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

/* ================= Large Input Field ================= */

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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
