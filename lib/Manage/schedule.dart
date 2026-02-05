import 'package:flutter/material.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final singleton = Singleton();

  String name(int index) => singleton.schedule[index][0];
  String detail(int index) => singleton.schedule[index][1];
  String time(int index) => singleton.schedule[index][2];

  @override
  void initState() {
    super.initState();
    // Data is loaded from local database via singleton
  }

  void _showMedicationDetails(int index) {
    final colors = context.colors;
    HapticUtils.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext c) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Text(
                  name(index),
                  style: Theme.of(c).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Medication Schedule',
                  style: Theme.of(c).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
                const SizedBox(height: 20),
                
                // Details
                _DetailRow(
                  label: 'Details',
                  value: detail(index),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Schedule',
                  value: time(index),
                  colors: colors,
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        text: 'Close',
                        isOutlined: true,
                        onPressed: () => Navigator.pop(c),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ModernIconButton(
                      icon: Icons.delete_outline,
                      backgroundColor: colors.error,
                      onPressed: () {
                        HapticUtils.lightImpact();
                        singleton.deleteEntireList(index, "schedules");
                        Navigator.pop(c);
                        Navigator.pushNamed(context, '/scheduleScreen');
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colors.textPrimary,
            size: 22,
          ),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pushNamed(context, '/');
          },
        ),
        title: const Text('Medications'),
      ),
      body: singleton.schedule.isEmpty
          ? _buildEmptyState(colors)
          : _buildScheduleList(colors),
      floatingActionButton: ModernFAB(
        icon: Icons.add,
        onPressed: () {
          Navigator.popAndPushNamed(context, '/editScheduleScreen');
        },
        extended: true,
        label: 'Add Medication',
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 40,
              color: colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No medications added',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your medications to keep track of your schedule.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(AppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: singleton.schedule.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ScheduleCard(
            name: name(index),
            detail: detail(index),
            schedule: time(index),
            onTap: () => _showMedicationDetails(index),
          ),
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String name;
  final String detail;
  final String schedule;
  final VoidCallback onTap;

  const _ScheduleCard({
    required this.name,
    required this.detail,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.medication_outlined,
            color: colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Medication' : name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  schedule,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: colors.textTertiary,
            size: 20,
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

  const _DetailRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not specified' : value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
