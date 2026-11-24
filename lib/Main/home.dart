import 'package:flutter/material.dart';

import '../linechart.dart';
import '../widgets/motion_coach_entry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 760,
        child: Padding(
          padding: EdgeInsets.only(top: 12),
          child: LineChartSample1(
            leading: MotionCoachEntry(
              description: 'Movement exercises with camera feedback.',
              margin: EdgeInsets.only(bottom: 16),
            ),
          ),
        ),
      ),
    );
  }
}
