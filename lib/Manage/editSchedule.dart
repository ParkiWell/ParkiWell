import 'package:flutter/material.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_input.dart';
import '../widgets/modern_card.dart';

class EditScheduleScreen extends StatefulWidget {
  const EditScheduleScreen({super.key});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();

  List<String> selectedDays = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
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
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _toggleDay(String day) {
    HapticUtils.selectionClick();
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  void _selectAllDays() {
    HapticUtils.lightImpact();
    setState(() {
      if (selectedDays.length == daysOfWeek.length) {
        selectedDays.clear();
      } else {
        selectedDays = List.from(daysOfWeek);
      }
    });
  }

  String _formatDays() {
    if (selectedDays.isEmpty) return '';
    if (selectedDays.length == 7) return 'Everyday';
    return selectedDays.map((d) => d.substring(0, 3)).join(', ');
  }

  Future<void> _submitSchedule() async {
    if (_nameController.text.trim().isEmpty) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter medication name'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (selectedDays.isEmpty) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one day'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticUtils.mediumImpact();

    try {
      String days = selectedDays.length == 7
          ? 'Everyday'
          : 'Every ${selectedDays.join(", ")}';

      // Save to local database
      final saved = await singleton.saveSchedule(
        _nameController.text.trim(),
        _detailsController.text.trim(),
        days,
      );
      if (!saved) {
        throw Exception('Unable to save medication schedule');
      }

      HapticUtils.success();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      HapticUtils.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medication: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.error,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                'Medication Added',
                style: Theme.of(c).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your medication schedule has been saved.',
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
                        _nameController.clear();
                        _detailsController.clear();
                        setState(() => selectedDays.clear());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernButton(
                      text: 'View All',
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.pushNamed(context, '/scheduleScreen');
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
            Navigator.popAndPushNamed(context, '/scheduleScreen');
          },
        ),
        title: const Text('Add Medication'),
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
                      'Medication Details',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a medication to track your schedule',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Name input
            _buildAnimatedSection(
              delay: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medication Name',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ModernTextField(
                    controller: _nameController,
                    hint: 'e.g., Levodopa, Carbidopa',
                    prefixIcon: Icons.medication_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details input
            _buildAnimatedSection(
              delay: 0.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details (Optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ModernTextField(
                    controller: _detailsController,
                    hint: 'e.g., Dosage, instructions',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Day selection
            _buildAnimatedSection(
              delay: 0.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedule',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextButton(
                        onPressed: _selectAllDays,
                        child: Text(
                          selectedDays.length == 7 ? 'Clear All' : 'Every Day',
                          style: TextStyle(color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ModernCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: daysOfWeek.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return GestureDetector(
                              onTap: () => _toggleDay(day),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.secondary
                                      : colors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.secondary
                                        : colors.border,
                                  ),
                                ),
                                child: Text(
                                  day.substring(0, 3),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: isSelected
                                            ? colors.textOnPrimary
                                            : colors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (selectedDays.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: colors.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDays(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colors.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  text: 'Save Medication',
                  icon: Icons.check_rounded,
                  isLoading: _isLoading,
                  onPressed: _submitSchedule,
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
}
