import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'barchart.dart';
import 'singleton.dart';
import 'theme/app_theme.dart';
import 'widgets/modern_card.dart';
import 'utils/haptic_utils.dart';

class LineChartSample1 extends StatefulWidget {
  const LineChartSample1({super.key});

  @override
  State<StatefulWidget> createState() => LineChartSample1State();
}

class LineChartSample1State extends State<LineChartSample1>
    with SingleTickerProviderStateMixin {
  late List<FlSpot> pointList;
  double lineBarY = 0;
  String chosenTime = "Month";
  final singleton = Singleton();
  late int symptomLength;
  List<String> time = ["Month", "Year"];
  late List<List<String>> log;

  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> month = [
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
    'December'
  ];

  Map<String, double> symptomsPerMonth = {
    'January': 0,
    'February': 0,
    'March': 0,
    'April': 0,
    'May': 0,
    'June': 0,
    'July': 0,
    'August': 0,
    'September': 0,
    'October': 0,
    'November': 0,
    'December': 0
  };

  List<String> year = ['2023', '2024', '2025', '2026', '2027', '2028'];

  void incrementMonth(m) {
    symptomsPerMonth[m] = symptomsPerMonth[m]! + 1;
  }

  List<FlSpot> createPoints() {
    double t = 0;
    List<FlSpot> points = [];

    for (int i = 0; i < log.length; i++) {
      if (chosenTime == "Month") {
        t = (month.indexOf(log[i][0].split(' ')[2])) / 1;
      } else {
        t = (year.indexOf(log[i][0].split(' ')[3])) / 1;
      }

      switch (t.floor()) {
        case 0:
          incrementMonth("January");
          break;
        case 1:
          incrementMonth("February");
          break;
        case 2:
          incrementMonth("March");
          break;
        case 3:
          incrementMonth("April");
          break;
        case 4:
          incrementMonth("May");
          break;
        case 5:
          incrementMonth("June");
          break;
        case 6:
          incrementMonth("July");
          break;
        case 7:
          incrementMonth("August");
          break;
        case 8:
          incrementMonth("September");
          break;
        case 9:
          incrementMonth("October");
          break;
        case 10:
          incrementMonth("November");
          break;
        case 11:
          incrementMonth("December");
          break;
      }
    }

    for (int i = 0; i < 12; i++) {
      points.add(FlSpot(i / 1, symptomsPerMonth[month[i]]!));
      if (symptomsPerMonth[month[i]]! > lineBarY) {
        lineBarY = symptomsPerMonth[month[i]]!;
      }
    }
    return points;
  }

  @override
  void initState() {
    super.initState();
    log = singleton.log;
    pointList = createPoints();
    symptomLength = pointList.length;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData1,
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData1,
        minX: 0,
        maxX: 12,
        maxY: lineBarY + 1,
        minY: 0,
      );

  LineTouchData get lineTouchData1 {
    final colors = context.colors;
    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => colors.surface,
        tooltipRoundedRadius: 12,
        tooltipPadding: const EdgeInsets.all(12),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              '${spot.y.toInt()} symptoms',
              TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_3,
      ];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    final colors = context.colors;
    TextStyle style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: colors.textSecondary,
    );
    String text = value.toInt().toString();

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 1,
        reservedSize: 32,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final colors = context.colors;
    TextStyle style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: colors.textSecondary,
    );
    late Widget text;
    if (chosenTime == "Month") {
      switch (value.toInt()) {
        case 0:
          text = Text('Jan', style: style);
          break;
        case 3:
          text = Text('Apr', style: style);
          break;
        case 6:
          text = Text('Jul', style: style);
          break;
        case 9:
          text = Text('Oct', style: style);
          break;
        default:
          text = const Text('');
          break;
      }
    } else {
      switch (value.toInt()) {
        case 1:
          text = Text('2023', style: style);
          break;
        case 3:
          text = Text('2024', style: style);
          break;
        case 5:
          text = Text('2025', style: style);
          break;
        case 7:
          text = Text('2026', style: style);
          break;
        case 9:
          text = Text('2027', style: style);
          break;
        case 11:
          text = Text('2028', style: style);
          break;
        default:
          text = const Text('');
          break;
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  FlGridData get gridData {
    final colors = context.colors;
    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: colors.divider.withValues(alpha: 0.5),
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
    );
  }

  FlBorderData get borderData {
    final colors = context.colors;
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: colors.divider, width: 1),
        left: BorderSide(color: colors.divider, width: 1),
        right: const BorderSide(color: Colors.transparent),
        top: const BorderSide(color: Colors.transparent),
      ),
    );
  }

  LineChartBarData get lineChartBarData1_3 {
    final colors = context.colors;
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.3,
      color: colors.chartLine,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: colors.chartLine,
            strokeWidth: 2,
            strokeColor: colors.surface,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.chartLine.withValues(alpha: 0.3),
            colors.chartLine.withValues(alpha: 0.0),
          ],
        ),
      ),
      spots: pointList,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          FadeTransition(
            opacity: _animation,
            child: Text(
              'Welcome back, ${singleton.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          FadeTransition(
            opacity: _animation,
            child: Text(
              'Here\'s your health overview',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick stats row
          FadeTransition(
            opacity: _animation,
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    colors,
                    Icons.favorite_rounded,
                    '${singleton.log.length}',
                    'Symptoms logged',
                    colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    colors,
                    Icons.medication_rounded,
                    '${singleton.schedule.length}',
                    'Medications',
                    colors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Symptom chart
          ModernCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.chartLine.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.show_chart_rounded,
                            color: colors.chartLine,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Symptoms',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: chosenTime,
                          isDense: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                          dropdownColor: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          onChanged: (String? newValue) {
                            HapticUtils.selectionClick();
                            setState(() {
                              chosenTime = newValue!;
                            });
                          },
                          items: time.map<DropdownMenuItem<String>>((String item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return LineChart(
                        sampleData1,
                        duration: const Duration(milliseconds: 300),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Medication chart
          ModernCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.chartBar.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        color: colors.chartBar,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Weekly Medications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const BarChartSample3(),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    AppColors colors,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
