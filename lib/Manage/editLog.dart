import 'package:flutter/material.dart';
import 'package:levio/Firebase/firebase_cloud.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_input.dart';
import '../widgets/modern_card.dart';

class EditLogScreen extends StatefulWidget {
  const EditLogScreen({super.key});

  @override
  State<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends State<EditLogScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  final _severityController = TextEditingController();
  final _symptomController = TextEditingController();
  
  String month = 'January';
  String day = '01';
  String year = '2024';
  String hour = '01';
  String minute = '00';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
  List<String> minutes = List.generate(60, (i) => i.toString().padLeft(2, '0'));
  List<String> days = List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));

  List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<String> years = List.generate(10, (i) => (2024 + i).toString());

  void calcDate() {
    int d = 31;
    if (month == 'February') {
      d = int.parse(year) % 4 == 0 ? 29 : 28;
    } else if (['April', 'June', 'September', 'November'].contains(month)) {
      d = 30;
    }

    setState(() {
      days = List.generate(d, (i) => (i + 1).toString().padLeft(2, '0'));
      if (!days.contains(day)) {
        day = days.last;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Set current date/time as default
    final now = DateTime.now();
    month = months[now.month - 1];
    day = now.day.toString().padLeft(2, '0');
    year = now.year.toString();
    hour = now.hour.toString().padLeft(2, '0');
    minute = now.minute.toString().padLeft(2, '0');
    calcDate();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _severityController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _submitLog() async {
    if (_symptomController.text.trim().isEmpty) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a symptom description'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticUtils.mediumImpact();

    try {
      String time = "$hour:$minute, $day $month $year";
      singleton.addLogList(time, _symptomController.text.trim(), _severityController.text.trim());
      await FirebaseCloud().createLogs(
        time,
        _symptomController.text.trim(),
        _severityController.text.trim(),
      );

      HapticUtils.success();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      HapticUtils.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving log: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    final colors = context.colors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Symptom Logged',
                style: Theme.of(c).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your symptom has been recorded successfully.',
                style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      text: 'Add Another',
                      isOutlined: true,
                      onPressed: () {
                        Navigator.pop(c);
                        _severityController.clear();
                        _symptomController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernButton(
                      text: 'View Logs',
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.pushNamed(context, '/logScreen');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.popAndPushNamed(context, '/logScreen');
          },
        ),
        title: const Text('Log Symptom'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_animation),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Symptom Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record your symptoms to track patterns over time',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Symptom input
            _buildAnimatedSection(
              delay: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What symptom did you experience?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ModernTextField(
                    controller: _symptomController,
                    hint: 'e.g., Tremor, Stiffness, Balance issues',
                    prefixIcon: Icons.description_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Severity input
            _buildAnimatedSection(
              delay: 0.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Severity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ModernTextField(
                    controller: _severityController,
                    hint: 'e.g., Mild, Moderate, Severe',
                    prefixIcon: Icons.speed_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date & Time
            _buildAnimatedSection(
              delay: 0.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When did it occur?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ModernCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: colors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                value: month,
                                items: months,
                                onChanged: (v) {
                                  setState(() => month = v!);
                                  calcDate();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                value: day,
                                items: days,
                                onChanged: (v) => setState(() => day = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                value: year,
                                items: years,
                                onChanged: (v) {
                                  setState(() => year = v!);
                                  calcDate();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: colors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                value: hour,
                                items: hours,
                                onChanged: (v) => setState(() => hour = v!),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                ':',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Expanded(
                              child: _buildDropdown(
                                value: minute,
                                items: minutes,
                                onChanged: (v) => setState(() => minute = v!),
                              ),
                            ),
                            const SizedBox(width: 50),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            _buildAnimatedSection(
              delay: 0.4,
              child: SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: 'Save Symptom',
                  icon: Icons.check_rounded,
                  isLoading: _isLoading,
                  onPressed: _submitLog,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required double delay, required Widget child}) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
        )),
        child: child,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          dropdownColor: colors.surface,
          borderRadius: BorderRadius.circular(12),
          onChanged: (v) {
            HapticUtils.selectionClick();
            onChanged(v);
          },
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
