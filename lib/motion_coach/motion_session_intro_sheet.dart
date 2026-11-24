import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion_engine/motion_engine.dart';

import '../services/app_logger.dart';
import '../theme/app_theme.dart';
import 'motion_coach_layout.dart';
import 'motion_demo_video_view.dart';
import 'motion_demonstration_view.dart';
import 'motion_exercise_catalog.dart';
import 'motion_reference_library.dart';
import 'motion_routine_catalog.dart';

/// Shows the movements and camera setup before the user starts a session.
Future<bool> showMotionSessionIntro(
  BuildContext context, {
  required MotionRoutineDescription description,
  required RoutineDefinition routine,
  required MotionReferenceLibrary library,
}) async {
  final bool? start = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.background,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (context) => _MotionSessionIntroSheet(
      description: description,
      routine: routine,
      library: library,
    ),
  );
  return start ?? false;
}

class _MotionSessionIntroSheet extends StatefulWidget {
  _MotionSessionIntroSheet({
    required this.description,
    required this.routine,
    required this.library,
  }) : exercises = [
         for (final step in routine.steps) motionExerciseById(step.exerciseId),
       ];

  final MotionRoutineDescription description;
  final RoutineDefinition routine;
  final List<MotionExerciseDefinition> exercises;
  final MotionReferenceLibrary library;

  @override
  State<_MotionSessionIntroSheet> createState() =>
      _MotionSessionIntroSheetState();
}

class _MotionSessionIntroSheetState extends State<_MotionSessionIntroSheet> {
  MotionDemonstrationLoop? _loop;
  int _previewIndex = 0;
  int _previewRequest = 0;
  bool _loading = true;
  final GlobalKey _previewAnchor = GlobalKey();

  final Set<String> _videoUnavailable = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreview(0));
  }

  Future<void> _loadPreview(int index) async {
    final int request = ++_previewRequest;
    try {
      final loop = await widget.library.loadDemonstration(
        widget.exercises[index].exerciseId,
      );
      if (!mounted || _previewRequest != request) return;
      setState(() {
        _loop = loop;
        _loading = false;
      });
    } on Object catch (error, stackTrace) {
      AppLogger().warning('Intro demonstration failed', error, stackTrace);
      if (!mounted || _previewRequest != request) return;
      setState(() => _loading = false);
    }
  }

  void _selectPreview(int index) {
    if (index == _previewIndex) return;
    setState(() {
      _previewIndex = index;
      _loop = null;
      _loading = true;
    });
    unawaited(_loadPreview(index));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final previewed = widget.exercises[_previewIndex];
    final videoAsset = _videoUnavailable.contains(previewed.exerciseId)
        ? null
        : previewed.demoVideoAsset;
    final loop = _loop;
    final multipleSteps = widget.exercises.length > 1;
    final description = widget.description;

    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.6,
      maxChildSize: 1,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    description.title,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${description.durationLabel} · '
                  '${multipleSteps ? '${widget.exercises.length} exercises' : previewed.postureLabel}'
                  '${multipleSteps && description.requiresStanding ? ' · Includes standing' : ''}',
                  style: text.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                MotionSectionTitle(
                  key: _previewAnchor,
                  title: multipleSteps ? previewed.title : 'Movement preview',
                ),
                if (multipleSteps)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Exercise ${_previewIndex + 1} of ${widget.exercises.length}',
                          style: text.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Previous exercise preview',
                        onPressed: _previewIndex > 0
                            ? () => _selectPreview(_previewIndex - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        tooltip: 'Next exercise preview',
                        onPressed: _previewIndex < widget.exercises.length - 1
                            ? () => _selectPreview(_previewIndex + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 172,
                    child: videoAsset != null
                        ? MotionDemoVideoView(
                            key: ValueKey(videoAsset),
                            assetPath: videoAsset,
                            onUnavailable: () {
                              if (mounted) {
                                setState(
                                  () => _videoUnavailable.add(
                                    previewed.exerciseId,
                                  ),
                                );
                              }
                            },
                          )
                        : loop != null
                        ? Semantics(
                            image: true,
                            label:
                                'Movement demonstration for ${previewed.title}',
                            child: MotionDemonstrationView(
                              key: ValueKey(loop.exerciseId),
                              loop: loop,
                              color: colors.navSelected,
                            ),
                          )
                        : Center(
                            child: _loading
                                ? const CircularProgressIndicator(
                                    semanticsLabel: 'Loading demonstration',
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'The demonstration is unavailable. Follow the instructions below.',
                                      textAlign: TextAlign.center,
                                      style: text.bodyMedium,
                                    ),
                                  ),
                          ),
                  ),
                ),
                if (videoAsset != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      demoVideoCreditLine,
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  previewed.instructions,
                  style: text.bodyMedium?.copyWith(height: 1.45),
                ),
                if (!multipleSteps) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${widget.routine.steps.first.targetRepetitions} movements',
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const MotionSectionTitle(title: 'Set up your space'),
                const SizedBox(height: 6),
                Text(
                  previewed.setupHint,
                  style: text.bodyMedium?.copyWith(height: 1.45),
                ),
                if (multipleSteps && description.requiresStanding) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Use a stable chair and leave room around it for the standing exercise.',
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Move within a comfortable range and stop if you feel unwell. '
                  'Camera frames are processed on this device during guided practice.',
                  style: text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (multipleSteps) ...[
                  const SizedBox(height: 24),
                  const MotionSectionTitle(title: 'Movements in this routine'),
                  const SizedBox(height: 6),
                  for (var index = 0; index < widget.exercises.length; index++)
                    _ExerciseIntroRow(
                      index: index,
                      exercise: widget.exercises[index],
                      repetitions:
                          widget.routine.steps[index].targetRepetitions,
                      selected: index == _previewIndex,
                      onTap: () {
                        _selectPreview(index);
                        final previewContext = _previewAnchor.currentContext;
                        if (previewContext != null) {
                          unawaited(Scrollable.ensureVisible(previewContext));
                        }
                      },
                    ),
                ],
              ],
            ),
          ),
          MotionActionBar(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.videocam_outlined),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
              label: const Text('Open camera and begin'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseIntroRow extends StatelessWidget {
  const _ExerciseIntroRow({
    required this.index,
    required this.exercise,
    required this.repetitions,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final MotionExerciseDefinition exercise;
  final int repetitions;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedColor: colors.navSelected,
      selectedTileColor: colors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: onTap,
      leading: Text('${index + 1}', style: text.labelLarge),
      title: Text(exercise.title),
      subtitle: Text(
        '${exercise.postureLabel} · $repetitions movements',
        style: text.bodySmall?.copyWith(color: colors.textSecondary),
      ),
      trailing: Icon(
        selected ? Icons.play_circle_filled_rounded : Icons.play_circle_outline,
      ),
    );
  }
}
