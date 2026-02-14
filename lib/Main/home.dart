import 'package:flutter/material.dart';

import '../linechart.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final singleton = Singleton();
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    if (_isSyncing || singleton.isSyncInProgress) return;
    setState(() => _isSyncing = true);
    HapticUtils.lightImpact();

    final synced = await singleton.syncNow();
    if (!mounted) return;

    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'Data synced successfully'
              : 'Sync unavailable. Your local data is still available.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showSyncCard = singleton.isCloudConfigured;

    return Column(
      children: [
        const SizedBox(height: 6),
        if (showSyncCard)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: ModernCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderRadius: 14,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: singleton.isOnline
                          ? colors.success.withValues(alpha: 0.12)
                          : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      singleton.isOnline
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_outlined,
                      color: singleton.isOnline
                          ? colors.success
                          : colors.textTertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          singleton.isOnline
                              ? 'Last sync: ${singleton.lastSyncDisplay}'
                              : 'Sync when online',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (singleton.connectivityLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            singleton.connectivityLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textTertiary,
                                      fontSize: 12,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ModernButton(
                    text: 'Sync',
                    isLoading: _isSyncing || singleton.isSyncInProgress,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    onPressed: _syncNow,
                  ),
                ],
              ),
            ),
          ),
        if (showSyncCard) const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: ModernCard(
                  margin: EdgeInsets.zero,
                  onTap: () => Navigator.pushNamed(context, '/editLogScreen'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_chart_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log symptom',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernCard(
                  margin: EdgeInsets.zero,
                  onTap: () =>
                      Navigator.pushNamed(context, '/editScheduleScreen'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_alarm_rounded,
                          color: colors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add medication',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Expanded(
          child: LineChartSample1(),
        ),
      ],
    );
  }
}
