import 'package:flutter/material.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final singleton = Singleton();
  static const List<String> _severityOptions = <String>[
    'Very Mild',
    'Mild',
    'Moderate',
    'Severe',
    'Very Severe',
  ];

  String time(int index) => singleton.log[index][0];
  String symptom(int index) => singleton.log[index][1];
  String severity(int index) => singleton.log[index][2];
  DateTime? _parseStorageTime(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final timePart = parts.first.trim().split(':');
    final datePart = parts.last.trim().split(' ');
    if (timePart.length != 2 || datePart.length != 3) return null;

    final hour = int.tryParse(timePart[0]);
    final minute = int.tryParse(timePart[1]);
    final day = int.tryParse(datePart[0]);
    final month = singleton.monthMap[datePart[1]];
    final year = int.tryParse(datePart[2]);
    if (hour == null ||
        minute == null ||
        day == null ||
        month == null ||
        year == null) {
      return null;
    }
    return DateTime(year, int.parse(month), day, hour, minute);
  }

  String _formatStorageTime(DateTime value) {
    const monthNames = <String>[
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
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = monthNames[value.month - 1];
    return '$hour:$minute, $day $month ${value.year}';
  }

  String _formatDisplayTime(String value) {
    final parsed = _parseStorageTime(value);
    if (parsed == null) return value;
    final hour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    const monthNames = <String>[
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
    return '$hour12:$minute $suffix, ${parsed.day} ${monthNames[parsed.month - 1]} ${parsed.year}';
  }

  Color _severityColor(String value, AppColors colors) {
    final text = value.toLowerCase();
    if (text.contains('mild')) return colors.success;
    if (text.contains('moderate')) return colors.warning;
    if (text.contains('severe')) return colors.error;
    return colors.info;
  }

  void _showLogDetails(int index) {
    final colors = context.colors;
    HapticUtils.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext c) {
        final sevColor = _severityColor(severity(index), colors);
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ModernCard(
                  backgroundColor: colors.surfaceVariant,
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.9),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.insights_rounded, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Logged at ${_formatDisplayTime(time(index))}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailRow(
                    label: 'Symptom', value: symptom(index), colors: colors),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Severity',
                  value: severity(index),
                  colors: colors,
                  badgeColor: sevColor,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        text: 'Close',
                        isOutlined: true,
                        onPressed: () => Navigator.pop(c),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ModernIconButton(
                      icon: Icons.edit_outlined,
                      backgroundColor: colors.secondary,
                      onPressed: () async {
                        Navigator.pop(c);
                        await _showEditLogDialog(index);
                      },
                    ),
                    const SizedBox(width: 10),
                    ModernIconButton(
                      icon: Icons.delete_outline_rounded,
                      backgroundColor: colors.error,
                      onPressed: () async {
                        HapticUtils.lightImpact();
                        await singleton.deleteEntireList(index, 'logs');
                        if (!mounted || !c.mounted) return;
                        Navigator.pop(c);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditLogDialog(int index) async {
    if (index < 0 || index >= singleton.log.length) return;
    final colors = context.colors;
    final symptomController = TextEditingController(text: symptom(index));
    var selectedSeverity = severity(index);
    var selectedDateTime = _parseStorageTime(time(index)) ?? DateTime.now();

    Future<void> pickDateTime(StateSetter setModalState) async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDateTime,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (pickedDate == null) return;
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );
      if (pickedTime == null) return;
      setModalState(() {
        selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext c) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Symptom Log',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: symptomController,
                      decoration: const InputDecoration(labelText: 'Symptom'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSeverity,
                      decoration: const InputDecoration(labelText: 'Severity'),
                      items: _severityOptions
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedSeverity = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => pickDateTime(setModalState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          _formatDisplayTime(
                              _formatStorageTime(selectedDateTime)),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ModernButton(
                            text: 'Cancel',
                            isOutlined: true,
                            onPressed: () => Navigator.pop(c),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ModernButton(
                            text: 'Save',
                            onPressed: () async {
                              if (symptomController.text.trim().isEmpty) return;
                              await singleton.updateLogEntry(
                                index,
                                _formatStorageTime(selectedDateTime),
                                symptomController.text.trim(),
                                selectedSeverity,
                              );
                              if (!mounted || !c.mounted) return;
                              Navigator.pop(c);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    symptomController.dispose();
  }

  Widget _buildSummary(AppColors colors) {
    final total = singleton.log.length;
    final latest = total > 0 ? _formatDisplayTime(time(0)) : 'No entries yet';

    return ModernCard(
      backgroundColor: colors.cardBackground,
      border: Border.all(color: colors.border),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Symptom overview',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$total symptom logs',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Latest: $latest',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pushNamed(context, '/');
          },
        ),
        title: Text('Symptom Log',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: Container(
        color: colors.background,
        child: singleton.log.isEmpty
            ? _buildEmptyState(colors)
            : _buildLogList(colors),
      ),
      floatingActionButton: ModernFAB(
        icon: Icons.add,
        backgroundColor: colors.primaryDark,
        onPressed: () => Navigator.popAndPushNamed(context, '/editLogScreen'),
        extended: true,
        label: 'Add Log',
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: ModernCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_outline_rounded,
                  color: colors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text('No symptoms logged',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Track symptoms consistently to identify trends and share progress with your care team.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: 'Create First Log',
                  icon: Icons.add_rounded,
                  onPressed: () =>
                      Navigator.popAndPushNamed(context, '/editLogScreen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogList(AppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
      itemCount: singleton.log.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSummary(colors),
          );
        }

        final row = index - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LogCard(
            time: _formatDisplayTime(time(row)),
            symptom: symptom(row),
            severity: severity(row),
            onTap: () => _showLogDetails(row),
          ),
        );
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  final String time;
  final String symptom;
  final String severity;
  final VoidCallback onTap;

  const _LogCard({
    required this.time,
    required this.symptom,
    required this.severity,
    required this.onTap,
  });

  Color _severityColor(String value, AppColors colors) {
    final text = value.toLowerCase();
    if (text.contains('mild')) return colors.success;
    if (text.contains('moderate')) return colors.warning;
    if (text.contains('severe')) return colors.error;
    return colors.info;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sevColor = _severityColor(severity, colors);

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom.isEmpty ? 'Symptom' : symptom,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              severity.isEmpty ? 'N/A' : severity,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: sevColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final Color? badgeColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.colors,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not specified' : value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor!.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                value,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
