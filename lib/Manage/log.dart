import 'package:flutter/material.dart';

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

class _LogScreenState extends State<LogScreen> {
  final singleton = Singleton();
  late List<List<String>> log;

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
    // Data is loaded from local database via singleton
    log = singleton.log;
    if (log.isNotEmpty) sortTime();
  }

  void _showLogDetails(int index) {
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
                  'Symptom Details',
                  style: Theme.of(c).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  time(index),
                  style: Theme.of(c).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
                const SizedBox(height: 20),
                
                // Details
                _DetailRow(
                  label: 'Symptom',
                  value: symptom(index),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Severity',
                  value: severity(index),
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
                        singleton.deleteEntireList(index, "logs");
                        Navigator.pop(c);
                        Navigator.pushNamed(context, '/logScreen');
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
        title: const Text('Symptom Log'),
      ),
      body: singleton.log.isEmpty
          ? _buildEmptyState(colors)
          : _buildLogList(colors),
      floatingActionButton: ModernFAB(
        icon: Icons.add,
        onPressed: () {
          Navigator.popAndPushNamed(context, '/editLogScreen');
        },
        extended: true,
        label: 'Add Log',
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
              Icons.favorite_outline,
              size: 40,
              color: colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No symptoms logged',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your symptoms to monitor your health over time.',
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

  Widget _buildLogList(AppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: singleton.log.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LogCard(
            time: time(index),
            symptom: symptom(index),
            severity: severity(index),
            onTap: () => _showLogDetails(index),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.favorite_outline,
            color: colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom.isEmpty ? 'Symptom' : symptom,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
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
          Text(
            severity.isEmpty ? 'N/A' : severity,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
          const SizedBox(width: 8),
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
