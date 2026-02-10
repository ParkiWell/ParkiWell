import 'package:flutter/material.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_input.dart';

class EditLogScreen extends StatefulWidget {
  const EditLogScreen({super.key});

  @override
  State<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends State<EditLogScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  final _symptomController = TextEditingController();

  static const List<String> _severityOptions = <String>[
    'Very Mild',
    'Mild',
    'Moderate',
    'Severe',
    'Very Severe',
  ];

  final List<String> _months = const <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  DateTime _selectedDateTime = DateTime.now();
  String _selectedSeverity = 'Moderate';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  Color _severityColor(String severity, AppColors colors) {
    if (severity == 'Very Mild' || severity == 'Mild') {
      return colors.success;
    }
    if (severity == 'Moderate') {
      return colors.warning;
    }
    return colors.error;
  }

  String _formatDisplayDate(DateTime dateTime) {
    return '${_months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatDisplayTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatStorageTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _months[dateTime.month - 1];
    final year = dateTime.year;
    return '$hour:$minute, $day $month $year';
  }

  Future<void> _pickDate() async {
    HapticUtils.selectionClick();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2038),
      helpText: 'Select Symptom Date',
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    HapticUtils.selectionClick();

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: 'Select Symptom Time',
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _submitLog() async {
    if (_symptomController.text.trim().isEmpty) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a symptom description'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticUtils.mediumImpact();

    try {
      final saved = await singleton.saveLog(
        _formatStorageTime(_selectedDateTime),
        _symptomController.text.trim(),
        _selectedSeverity,
      );
      if (!saved) {
        throw Exception('Unable to save symptom log');
      }

      HapticUtils.success();
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      HapticUtils.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving symptom: $e'),
          backgroundColor: context.colors.error,
        ),
      );
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.success,
                      colors.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 42),
              ),
              const SizedBox(height: 18),
              Text(
                'Symptom Saved',
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your symptom log has been recorded with timestamp and severity.',
                textAlign: TextAlign.center,
                style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      text: 'Add More',
                      isOutlined: true,
                      onPressed: () {
                        Navigator.pop(c);
                        _symptomController.clear();
                        setState(() {
                          _selectedSeverity = 'Moderate';
                          _selectedDateTime = DateTime.now();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
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

  Widget _buildHeader(AppColors colors) {
    return ModernCard(
      backgroundColor: colors.cardBackground,
      border: Border.all(
        color: colors.border,
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.monitor_heart_rounded,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Symptom',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture symptom details quickly and track changes over time.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severity',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _severityOptions.map((severity) {
            final isSelected = _selectedSeverity == severity;
            final chipColor = _severityColor(severity, colors);

            return GestureDetector(
              onTap: () {
                HapticUtils.selectionClick();
                setState(() => _selectedSeverity = severity);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.16)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? chipColor.withValues(alpha: 0.8)
                        : colors.border,
                  ),
                ),
                child: Text(
                  severity,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected ? chipColor : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When did it occur?',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ModernCard(
                onTap: _pickDate,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            _formatDisplayDate(_selectedDateTime),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: colors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ModernCard(
                onTap: _pickTime,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: colors.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            _formatDisplayTime(_selectedDateTime),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: colors.textTertiary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final severityColor = _severityColor(_selectedSeverity, colors);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
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
        title: const Text('Symptom Log'),
      ),
      body: FadeTransition(
        opacity: _animation,
        child: Container(
          color: colors.background,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors),
                const SizedBox(height: 16),
                ModernCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What symptom did you experience?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      ModernTextField(
                        controller: _symptomController,
                        hint: 'e.g., Tremor in left hand after lunch',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _buildSeveritySelector(colors),
                      const SizedBox(height: 14),
                      _buildDateTimeSection(colors),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ModernCard(
                  showBorder: false,
                  backgroundColor: severityColor.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.insights_rounded,
                          color: severityColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Logging as $_selectedSeverity at ${_formatDisplayTime(_selectedDateTime)} on ${_formatDisplayDate(_selectedDateTime)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: severityColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ModernButton(
                    text: 'Save Symptom',
                    icon: Icons.check_rounded,
                    isLoading: _isLoading,
                    onPressed: _submitLog,
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
