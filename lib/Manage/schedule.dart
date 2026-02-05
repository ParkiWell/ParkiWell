import 'package:flutter/material.dart';

import '../Firebase/firebase_cloud.dart';
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

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();

  late AnimationController _animationController;
  late Animation<double> _animation;

  String name(int index) => singleton.schedule[index][0];
  String detail(int index) => singleton.schedule[index][1];
  String time(int index) => singleton.schedule[index][2];

  @override
  void initState() {
    super.initState();
    FirebaseCloud().idList(false);

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
    super.dispose();
  }

  void _showMedicationDetails(int index) {
    final colors = context.colors;
    HapticUtils.cardTap();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext c) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        color: colors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name(index),
                            style: Theme.of(c).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Medication Schedule',
                            style: Theme.of(c).textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Details
                _DetailRow(
                  label: 'Details',
                  value: detail(index),
                  icon: Icons.description_outlined,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Schedule',
                  value: time(index),
                  icon: Icons.schedule_rounded,
                  colors: colors,
                ),
                const SizedBox(height: 32),
                
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
                    const SizedBox(width: 16),
                    ModernIconButton(
                      icon: Icons.delete_outline_rounded,
                      backgroundColor: colors.error,
                      onPressed: () {
                        HapticUtils.heavyImpact();
                        singleton.deleteEntireList(index, "schedules");
                        Navigator.pop(c);
                        Navigator.pushNamed(context, '/scheduleScreen');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
            Navigator.pushNamed(context, '/');
          },
        ),
        title: const Text('Medications'),
      ),
      body: singleton.schedule.isEmpty
          ? _buildEmptyState(colors)
          : _buildScheduleList(colors),
      floatingActionButton: ModernFAB(
        icon: Icons.add_rounded,
        onPressed: () {
          Navigator.popAndPushNamed(context, '/editScheduleScreen');
        },
        extended: true,
        label: 'Add Medication',
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return FadeTransition(
      opacity: _animation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_outlined,
                  size: 48,
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Medications Added',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your medications to keep track of your schedule.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList(AppColors colors) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: singleton.schedule.length,
      itemBuilder: (BuildContext context, int index) {
        return FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index / singleton.schedule.length) * 0.5,
                1.0,
                curve: Curves.easeOutCubic,
              ),
            )),
            child: _ScheduleCard(
              name: name(index),
              detail: detail(index),
              schedule: time(index),
              onTap: () => _showMedicationDetails(index),
            ),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_rounded,
              color: colors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Medication' : name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppColors colors;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
                Text(
                  value.isEmpty ? 'Not specified' : value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
