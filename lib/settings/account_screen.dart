import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('لا يوجد مستخدم مسجّل')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الحساب'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            children: [
              // ================= HEADER =================
              Column(
                children: [
                  Container(
                    width: 104, // 👈 كبّري الدائرة (مثلاً 112 أو 120)
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 56, // 👈 كبّري الأيقونة (60 / 64)
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data['originalName'] ?? '—',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 22, // 👈 كبّري اسم المستخدم
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ================= INFO =================
              _infoItem(
                icon: Icons.email_outlined,
                label: 'البريد الإلكتروني',
                value: user.email ?? '—',
              ),
              _infoItem(
                icon: Icons.cake_outlined,
                label: 'العمر',
                value: data['age']?.toString() ?? '—',
              ),
              _infoItem(
                icon: Icons.school_outlined,
                label: 'المستوى التعليمي',
                value: _mapEducation(data['educationLevel']),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= INFO ROW =================
  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28, // 👈 كبّري أيقونات الصفوف (30 / 32)
            color: Colors.blue,
          ),
          const SizedBox(width: 20), // 👈 زودي المسافة لو بدك
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16, // 👈 حجم التسمية (14 / 18)
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18, // 👈 حجم القيمة (20 / 22)
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= EDUCATION MAPPER =================
  String _mapEducation(dynamic value) {
    switch (value) {
      case 'less_than_secondary':
        return 'أقل من الثانوية';
      case 'secondary':
        return 'ثانوية';
      case 'university':
        return 'جامعة';
      default:
        return '—';
    }
  }
}
