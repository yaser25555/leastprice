import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'package:leastprice/data/models/price_snapshot.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PriceSnapshot> snapshots;
  final String currency;

  const PriceHistoryChart({
    super.key,
    required this.snapshots,
    this.currency = 'SAR',
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.length < 2) {
      return _emptyState(context);
    }

    final prices = snapshots.map((s) => s.price).toList();
    final minPrice = prices.reduce(min) as double;
    final maxPrice = prices.reduce(max) as double;
    final priceRange = maxPrice - minPrice;
    final yAxisMin = (minPrice - priceRange * 0.1).clamp(0, double.infinity);
    final yAxisMax = maxPrice + priceRange * 0.1;

    final spots = snapshots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.price);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: yAxisMin,
              maxY: yAxisMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: priceRange > 0
                    ? priceRange / 4
                    : maxPrice * 0.25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: max(1, (snapshots.length / 5).floor()).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= snapshots.length) {
                        return const SizedBox.shrink();
                      }
                      final date = snapshots[idx].recordedAt;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.month}/${date.day}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(0)} $currency',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppPalette.comparisonEmerald,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: snapshots.length <= 30,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: AppPalette.comparisonEmerald,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppPalette.comparisonEmerald.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.spotIndex;
                      final snapshot = snapshots[idx];
                      final date =
                          '${snapshot.recordedAt.year}-${snapshot.recordedAt.month.toString().padLeft(2, '0')}-${snapshot.recordedAt.day.toString().padLeft(2, '0')}';
                      return LineTooltipItem(
                        '$date\n${formatAmount(spot.y)} $currency',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statChip(
              context,
              tr('أقل سعر', 'Lowest'),
              '${formatAmount(minPrice)} $currency',
              AppPalette.comparisonEmerald,
            ),
            const SizedBox(width: 12),
            _statChip(
              context,
              tr('أعلى سعر', 'Highest'),
              '${formatAmount(maxPrice)} $currency',
              AppPalette.dealsRed,
            ),
            const SizedBox(width: 12),
            _statChip(
              context,
              tr('عدد القراءات', 'Readings'),
              '${snapshots.length}',
              Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.show_chart, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            tr(
              'سجل الأسعار قيد التجميع...',
              'Price history is being collected...',
            ),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String formatAmount(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
