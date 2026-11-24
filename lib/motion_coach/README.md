# Motion Coach

Camera-coached exercise for ParkiWell. The engine
([packages/motion_engine](../../packages/motion_engine/), vendored from the
motion-coach-cv repo) measures movement from pose landmarks; everything in
this directory adapts the camera, assets, and app around it.

## Purpose

Two product modes, per the engine repo's design docs:

1. Realtime coaching: while the person moves, count repetitions, score each
   one (range, tempo, smoothness, symmetry), and deliver short allowlisted
   cues by text, speech, and haptics.
2. Evidence-based feedback: after a session, show what was measured, per
   movement, against the exercise reference, without invented judgment.

## Architecture invariants

- The engine decides; the app delivers. Every score, threshold, cue string,
  and summary sentence comes from `motion_engine` or from a template it
  validated. UI code never invents a measurement or rewords a cue.
- Templates and routines are generated assets. `assets/motion/` is written
  by `scripts/sync-motion-assets.py` from the engine repo and read by
  `MotionReferenceLibrary`; live thresholds are derived from the template so
  the app cannot drift from the engine's references.
- One session path. A single-exercise practice is a one-step routine
  (`singleExerciseRoutine`), so routines and practice share the
  `RoutineSession` engine path, one evaluation schema, and one history
  format.
- Guided sessions record nothing. The camera stream is measured frame by
  frame and discarded. Only derived numbers (scores, rep measurements,
  allowlisted sentences) are stored in encrypted history and can be deleted
  in the app. Signed-in users can back up these results. The separate
  motion check flow (`MotionCoachScreen`) records video at the user's
  explicit request and keeps it on device.
- Per-frame work stays off the widget tree. Controllers notify only when
  something renderable changed; per-frame pose data flows through a
  dedicated `ValueNotifier` to the small skeleton overlay canvas.

## Map

| File | Role |
| --- | --- |
| `motion_reference_library.dart` | Loads template/routine/demonstration assets; the engine's IO adapter |
| `motion_exercise_catalog.dart` | App-facing exercise copy; must cover exactly the engine's registry |
| `motion_routine_catalog.dart` | Routine descriptions for the committed `routine.v1` assets |
| `motion_capture_driver.dart` | Camera + pose bridge; detects persistent detector failure |
| `motion_pose_bridge.dart` | Platform channel to the MediaPipe pose landmarker |
| `motion_coach_session.dart` | Framing checks and single-capture live coaching state |
| `motion_routine_controller.dart` | Adapts camera samples into the engine `RoutineSession` |
| `motion_routine_screen.dart` | Guided session UI: preview, overlay, guide, cues, rests |
| `motion_skeleton_overlay.dart` | Live tracking overlay on the camera preview |
| `motion_demonstration_view.dart` | Stick-figure reference loop; honors reduce-motion |
| `motion_session_intro_sheet.dart` | Demonstration-first intro before the camera opens |
| `motion_routine_results_screen.dart` | Evaluation rendering incl. per-movement evidence |
| `motion_session_history.dart` | Encrypted session store, backup reconciliation, trends, streaks |
| `motion_progress_screen.dart` | History, per-exercise trends, drill-down, delete |
| `motion_coach_preferences.dart` | Spoken cues, haptics, result backup, and AI summary preferences |
| `motion_coach_home_screen.dart` | Entry point: routines, practice, progress, preferences |
| `motion_analysis.dart` | Offline detailed analysis (arm raise only; engine limit) |
| `motion_coach_screen.dart` | Record-and-analyze motion check used from exercise videos |
| `motion_cue_speaker.dart` | Best-effort on-device TTS for cues |

The native pose bridges switch to CPU inference when the GPU delegate fails
to initialize or process a frame. The replacement still uses the bundled model.

Home and Recovery link to the coach on Android and iOS. Guided sessions with
at least one assessed exercise count toward the weekly physical goal. New
Recovery history entries share an ID with the coach result, so users can open
that result from either history while it is available on the device.

## Boundaries that are intentional

- Pausing or backgrounding a guided session releases the camera and holds
  completed movements in memory. Resuming rechecks framing and discards any
  movement that straddled the pause. Save and end keeps measured work in
  history when finishing early. An app process restart ends an unsaved run.
- Camera frames, recordings, and landmarks stay on the device. Account
  backup applies to derived results. An optional AI summary uses a bounded
  set of measurements and requires separate opt-in.
- Clinical thresholds, device performance, and PT approval remain unverified
  externally; templates carry `review.status: draft`.
