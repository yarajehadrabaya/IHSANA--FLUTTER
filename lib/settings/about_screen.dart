import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
        children: [
          // ================= LOGO ONLY (HERO) =================
          Center(
            child: SvgPicture.asset(
              'assets/logo/ihsana_logo.svg',
              height: 260, // 🔥 لوجو كبير وواضح
            ),
          ),

         

          // ================= SHORT TAGLINE =================
          Text(
            'تطبيق لتقييم الإدراك المعرفي باللغة العربية',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[700]),
          ),


          // ================= DESCRIPTION =================
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Text(
                'إحسانا هو تطبيق يهدف إلى دعم تقييم الإدراك المعرفي '
                'من خلال اختبارات مبسطة باللغة العربية، '
                'بهدف المساعدة في الكشف المبكر والمتابعة المستمرة '
                'للحالة الإدراكية.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.8),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ================= INFO SECTION =================
          Text(
            'معلومات التطبيق',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.info_outline,
            title: 'الإصدار',
            value: '1.0.0',
          ),

          _infoCard(
            icon: Icons.school_outlined,
            title: 'نوع التطبيق',
            value: 'تطبيق بحثي / تعليمي',
          ),


          // ================= DISCLAIMER =================
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
                    'هذا التطبيق لا يُعد أداة تشخيصية طبية، '
                    'ويُستخدم لأغراض التقييم والمتابعة فقط، '
                    'ولا يُغني عن استشارة المختصين.',
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

  // ================= INFO CARD =================
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1.5,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          value,
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
