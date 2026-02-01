import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../session/session_context.dart';
import 'visuospatial/trail_making_screen.dart';

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
          builder: (_) => const TrailMakingScreen(),
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
                // ===== زر الرجوع =====
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 22,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== الكرت الرئيسي =====
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'أين أنت الآن؟',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 24),

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

                            const SizedBox(height: 32),

                            // ===== زر المتابعة (مصحّح) =====
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: !_canContinue || _loading
                                    ? null
                                    : _saveLocation,
                                style: ElevatedButton.styleFrom(
                                  alignment: Alignment.center,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'متابعة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: AppTheme.primary, // ✅ لون المشروع
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

