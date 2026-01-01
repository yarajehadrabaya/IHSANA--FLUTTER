import 'package:flutter/material.dart';
import '../widgets/app_background.dart';
import '../theme/app_theme.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _displayNameController =
      TextEditingController();

  int _age = 65;
  String? _gender; // male | female

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🧠 Title
                    Text(
                      'إعداد الملف الشخصي',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'نحتاج هذه المعلومات لتقديم تجربة مناسبة لك',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // 👤 Display Name
                    TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم المعروض',
                        helperText: 'مثال: محمد، أبو أحمد',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🎂 Age Stepper
                    NumberStepper(
                      label: 'العمر',
                      value: _age,
                      min: 40,
                      max: 100,
                      onIncrement: () =>
                          setState(() => _age++),
                      onDecrement: () =>
                          setState(() => _age--),
                    ),

                    const SizedBox(height: 24),

                    // 🚻 Gender Selection
                    Text(
                      'الجنس',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: GenderOption(
                            label: 'ذكر',
                            icon: Icons.male,
                            selected: _gender == 'male',
                            onTap: () =>
                                setState(() => _gender = 'male'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GenderOption(
                            label: 'أنثى',
                            icon: Icons.female,
                            selected: _gender == 'female',
                            onTap: () =>
                                setState(() => _gender = 'female'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ▶️ Continue
                    ElevatedButton(
                      onPressed: () {
                        final String displayName =
                            _displayNameController.text.isEmpty
                                ? 'أهلاً بك'
                                : _displayNameController.text;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(
                              username: displayName,
                            ),
                          ),
                        );
                      },
                      child: const Text('متابعة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================================================= */
/* ===================== NUMBER STEPPER ==================== */
/* ========================================================= */

class NumberStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: value > min ? onDecrement : null,
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style:
                      Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: value < max ? onIncrement : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ========================================================= */
/* ===================== GENDER OPTION ===================== */
/* ========================================================= */

class GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const GenderOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          color: selected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.transparent,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        AppTheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: selected
                  ? AppTheme.primary
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppTheme.primary
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
