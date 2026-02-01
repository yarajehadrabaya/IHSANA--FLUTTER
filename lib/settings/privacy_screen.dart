import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخصوصية'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        children: [
          _sectionTitle(context, 'سياسة الخصوصية'),

          _infoCard(
            icon: Icons.lock_outline,
            text:
                'نلتزم في تطبيق إحسانا بحماية خصوصية المستخدمين وعدم مشاركة أي بيانات شخصية مع أطراف خارجية.',
          ),

          _infoCard(
            icon: Icons.storage_outlined,
            text:
                'يتم استخدام البيانات المدخلة فقط لأغراض التقييم والمتابعة، ويتم تخزينها بشكل آمن.',
          ),

          const SizedBox(height: 24),

          _sectionTitle(context, 'استخدام البيانات'),

          _infoCard(
            icon: Icons.analytics_outlined,
            text:
                'تُستخدم نتائج الاختبارات لأغراض البحث العلمي وتحسين جودة التطبيق، دون ربطها بهوية المستخدم.',
          ),

          _infoCard(
            icon: Icons.person_outline,
            text:
                'لا يتم استخدام البيانات لأغراض تجارية أو إعلانية بأي شكل من الأشكال.',
          ),

          const SizedBox(height: 32),

          // ===== DISCLAIMER =====
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'باستخدامك لهذا التطبيق، فإنك توافق على سياسة الخصوصية واستخدام البيانات كما هو موضح أعلاه.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Section Title =====
  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  // ===== Info Card =====
  Widget _infoCard({
    required IconData icon,
    required String text,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style:
                    const TextStyle(height: 1.6, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
