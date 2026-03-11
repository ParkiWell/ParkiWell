import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../singleton.dart';
import '../services/tutorial_targets.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_input.dart';
import '../widgets/tutorial_overlay.dart';

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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _severityOptions.map((severity) {
            final isSelected = _selectedSeverity == severity;
            final chipColor = _severityColor(severity, colors);

            return _SeverityChip(
              label: severity,
              selected: isSelected,
              chipColor: chipColor,
              onTap: () {
                HapticUtils.selectionClick();
                setState(() => _selectedSeverity = severity);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickDateAndTime() async {
    HapticUtils.selectionClick();
    if (!mounted) return;
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DateTimePickerSheet(
        initial: _selectedDateTime,
        months: _months,
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedDateTime = result);
    }
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
        ModernCard(
          onTap: _pickDateAndTime,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDisplayDate(_selectedDateTime),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDisplayTime(_selectedDateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_calendar_rounded,
                  color: colors.textTertiary, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TutorialOverlay(
      steps: const [],
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
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
          title: Text('Symptom Log',
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                        KeyedSubtree(
                          key: TutorialTargets.symptomInputKey,
                          child: ModernTextField(
                            controller: _symptomController,
                            hint: 'e.g., Tremor in left hand after lunch',
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSeveritySelector(colors),
                        const SizedBox(height: 14),
                        _buildDateTimeSection(colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$_selectedSeverity · ${_formatDisplayDate(_selectedDateTime)} at ${_formatDisplayTime(_selectedDateTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: KeyedSubtree(
                      key: TutorialTargets.saveSymptomButtonKey,
                      child: ModernButton(
                        text: 'Save Symptom',
                        icon: Icons.check_rounded,
                        isLoading: _isLoading,
                        onPressed: _submitLog,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom date & time picker bottom sheet.
/// Date: horizontal scrollable date chips (Today, Yesterday, past 30 days).
/// Time: iOS-style scroll wheels for hour, minute, and AM/PM.
class _DateTimePickerSheet extends StatefulWidget {
  final DateTime initial;
  final List<String> months;

  const _DateTimePickerSheet({
    required this.initial,
    required this.months,
  });

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _date;
  late int _hour12;
  late int _minute;
  late bool _isPm;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _amPmController;
  late final ScrollController _dateScrollController;

  /// Generate the list of dates: past 30 days through today.
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _date =
        DateTime(widget.initial.year, widget.initial.month, widget.initial.day);
    final h = widget.initial.hour;
    _hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    _minute = widget.initial.minute;
    _isPm = widget.initial.hour >= 12;

    // Generate dates from 30 days ago to today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dates = List<DateTime>.generate(31, (i) {
      return today.subtract(Duration(days: 30 - i));
    });

    // Initialize scroll controllers at the correct positions
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _amPmController = FixedExtentScrollController(initialItem: _isPm ? 1 : 0);
    _dateScrollController = ScrollController();

    // Scroll date list to the selected date after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = _dates.indexWhere((d) =>
          d.year == _date.year && d.month == _date.month && d.day == _date.day);
      if (idx >= 0 && _dateScrollController.hasClients) {
        // Each chip is 68 wide + 8 gap = 76
        final offset = (idx * 76.0) - 40;
        _dateScrollController.animateTo(
          offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _amPmController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  DateTime get _result {
    final hour24 = _isPm
        ? (_hour12 == 12 ? 12 : _hour12 + 12)
        : (_hour12 == 12 ? 0 : _hour12);
    return DateTime(_date.year, _date.month, _date.day, hour24, _minute);
  }

  bool _isSpecialDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dt = DateTime(d.year, d.month, d.day);
    return dt == today || dt == yesterday;
  }

  String _specialLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dt = DateTime(d.year, d.month, d.day);
    if (dt == today) return 'Today';
    if (dt == yesterday) return 'Yest.';
    return '';
  }

  String _weekdayShort(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, safeBottom + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.schedule_rounded,
                        size: 20, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Date & time',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── DATE SECTION ───
              Text(
                'Date',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  controller: _dateScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final d = _dates[i];
                    final isSelected = _date.year == d.year &&
                        _date.month == d.month &&
                        _date.day == d.day;
                    final isSpecial = _isSpecialDate(d);

                    return GestureDetector(
                      onTap: () {
                        HapticUtils.selectionClick();
                        setState(() => _date = d);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 68,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : colors.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.border.withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSpecial) ...[
                              Text(
                                _specialLabel(d),
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colors.textOnPrimary
                                          .withValues(alpha: 0.8)
                                      : colors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ] else ...[
                              Text(
                                _weekdayShort(d),
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? colors.textOnPrimary
                                          .withValues(alpha: 0.8)
                                      : colors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              '${d.day}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? colors.textOnPrimary
                                    : colors.textPrimary,
                              ),
                            ),
                            Text(
                              widget.months[d.month - 1].substring(0, 3),
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? colors.textOnPrimary
                                        .withValues(alpha: 0.8)
                                    : colors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ─── TIME SECTION ───
              Text(
                'Time',
                style: textTheme.labelLarge?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Scroll wheel time picker
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: colors.border.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  children: [
                    // Selection highlight band
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Hour wheel
                        Expanded(
                          flex: 3,
                          child: CupertinoPicker(
                            scrollController: _hourController,
                            itemExtent: 40,
                            diameterRatio: 1.2,
                            squeeze: 1.0,
                            selectionOverlay: const SizedBox.shrink(),
                            onSelectedItemChanged: (index) {
                              HapticUtils.selectionClick();
                              setState(() => _hour12 = index + 1);
                            },
                            children: List.generate(12, (i) {
                              final hour = i + 1;
                              final isSelected = hour == _hour12;
                              return Center(
                                child: Text(
                                  '$hour',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.textSecondary
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // Colon separator
                        Text(
                          ':',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textTertiary,
                          ),
                        ),
                        // Minute wheel
                        Expanded(
                          flex: 3,
                          child: CupertinoPicker(
                            scrollController: _minuteController,
                            itemExtent: 40,
                            diameterRatio: 1.2,
                            squeeze: 1.0,
                            selectionOverlay: const SizedBox.shrink(),
                            onSelectedItemChanged: (index) {
                              HapticUtils.selectionClick();
                              setState(() => _minute = index);
                            },
                            children: List.generate(60, (i) {
                              final isSelected = i == _minute;
                              return Center(
                                child: Text(
                                  i.toString().padLeft(2, '0'),
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.textSecondary
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // AM/PM wheel
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            scrollController: _amPmController,
                            itemExtent: 40,
                            diameterRatio: 1.2,
                            squeeze: 1.0,
                            selectionOverlay: const SizedBox.shrink(),
                            onSelectedItemChanged: (index) {
                              HapticUtils.selectionClick();
                              setState(() => _isPm = index == 1);
                            },
                            children: ['AM', 'PM'].map((label) {
                              final isSelected = (label == 'AM' && !_isPm) ||
                                  (label == 'PM' && _isPm);
                              return Center(
                                child: Text(
                                  label,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.textSecondary
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── DONE BUTTON ───
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    HapticUtils.selectionClick();
                    Navigator.of(context).pop(_result);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color chipColor;
  final VoidCallback onTap;

  const _SeverityChip({
    required this.label,
    required this.selected,
    required this.chipColor,
    required this.onTap,
  });

  @override
  State<_SeverityChip> createState() => _SeverityChipState();
}

class _SeverityChipState extends State<_SeverityChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? widget.chipColor.withValues(alpha: 0.12)
                : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? widget.chipColor : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? widget.chipColor : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
