import 'package:flutter/material.dart';
import 'package:parkinson/Firebase/firebase_cloud.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  late List<List<String>> log;

  late AnimationController _animationController;
  late Animation<double> _animation;

  String time(int index) => log[index][0];
  String symptom(int index) => log[index][1];
  String severity(int index) => log[index][2];

  Map<String, String> monthMap = {
    'January': "01",
    'February': "02",
    'March': "03",
    'April': "04",
    'May': "05",
    'June': "06",
    'July': "07",
    'August': "08",
    'September': "09",
    'October': "10",
    'November': "11",
    'December': "12"
  };

  void sortTime() {
    List<List<String>> dTime = [];
    for (int i = 0; i < log.length; i++) {
      List<String> time = log[i][0].split(' ');
      dTime.add([
        "${time[3]}-${monthMap[time[2]]}-${time[1]} ${time[0].substring(0, time[0].length - 1)}:00",
        '$i'
      ]);
    }
    dTime.sort((a, b) {
      DateTime dateTimeA = DateTime.parse(a[0]);
      DateTime dateTimeB = DateTime.parse(b[0]);
      return dateTimeA.compareTo(dateTimeB);
    });

    sortLog(dTime.reversed.toList());
  }

  void sortLog(t) {
    List<List<String>> tempList = [];
    tempList.addAll(log);
    setState(() {
      log.clear();
      for (int i = 0; i < tempList.length; i++) {
        log.add(tempList[int.parse(t[i][1])]);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    FirebaseCloud().idList(true);
    log = singleton.log;
    if (log.isNotEmpty) sortTime();

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

  void _showLogDetails(int index) {
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
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Symptom Log',
                            style: Theme.of(c).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            time(index),
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
                  label: 'Symptom',
                  value: symptom(index),
                  icon: Icons.description_outlined,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Severity',
                  value: severity(index),
                  icon: Icons.speed_rounded,
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
                        singleton.deleteEntireList(index, "logs");
                        Navigator.pop(c);
                        Navigator.pushNamed(context, '/logScreen');
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
        title: const Text('Symptom Log'),
      ),
      body: singleton.log.isEmpty
          ? _buildEmptyState(colors)
          : _buildLogList(colors),
      floatingActionButton: ModernFAB(
        icon: Icons.add_rounded,
        onPressed: () {
          Navigator.popAndPushNamed(context, '/editLogScreen');
        },
        extended: true,
        label: 'Add Log',
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
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 48,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Symptoms Logged',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your symptoms to monitor your health over time.',
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

  Widget _buildLogList(AppColors colors) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: singleton.log.length,
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
                (index / singleton.log.length) * 0.5,
                1.0,
                curve: Curves.easeOutCubic,
              ),
            )),
            child: _LogCard(
              time: time(index),
              symptom: symptom(index),
              severity: severity(index),
              onTap: () => _showLogDetails(index),
            ),
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
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom.isEmpty ? 'Symptom' : symptom,
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
                        time,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getSeverityColor(severity, colors).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              severity.isEmpty ? 'N/A' : severity,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getSeverityColor(severity, colors),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity, AppColors colors) {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('high') ||
        lowerSeverity.contains('severe') ||
        lowerSeverity.contains('10') ||
        lowerSeverity.contains('9')) {
      return colors.error;
    } else if (lowerSeverity.contains('medium') ||
        lowerSeverity.contains('moderate')) {
      return colors.warning;
    }
    return colors.success;
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
          Column(
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
        ],
      ),
    );
  }
}
