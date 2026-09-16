import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Diagramme IN / OUT / FILET. La légende répète toujours couleur + texte +
/// valeur : jamais d'information uniquement portée par la couleur (§26).
class ResultPieChart extends StatelessWidget {
  final int inCount;
  final int outCount;
  final int netCount;

  const ResultPieChart({super.key, required this.inCount, required this.outCount, required this.netCount});

  @override
  Widget build(BuildContext context) {
    final total = inCount + outCount + netCount;
    return Row(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 26,
              sections: [
                if (inCount > 0)
                  PieChartSectionData(value: inCount.toDouble(), color: AppColors.success, showTitle: false, radius: 26),
                if (outCount > 0)
                  PieChartSectionData(value: outCount.toDouble(), color: AppColors.error, showTitle: false, radius: 26),
                if (netCount > 0)
                  PieChartSectionData(value: netCount.toDouble(), color: AppColors.warning, showTitle: false, radius: 26),
                if (total == 0)
                  PieChartSectionData(value: 1, color: AppColors.border, showTitle: false, radius: 26),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendRow(color: AppColors.success, icon: Icons.check_circle, label: 'IN', value: inCount),
              const SizedBox(height: 8),
              _LegendRow(color: AppColors.error, icon: Icons.cancel, label: 'OUT', value: outCount),
              const SizedBox(height: 8),
              _LegendRow(color: AppColors.warning, icon: Icons.block, label: 'FILET', value: netCount),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final int value;

  const _LegendRow({required this.color, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text('$value', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// Histogramme générique (zones, types de service, trajectoires, directions).
class CategoryBarChart extends StatelessWidget {
  final List<String> labels;
  final List<int> values;
  final Color color;

  const CategoryBarChart({super.key, required this.labels, required this.values, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    final chartMax = (maxValue < 4 ? 4 : maxValue).toDouble();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    color: values[i] == 0 ? AppColors.border : color,
                    width: 22,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
