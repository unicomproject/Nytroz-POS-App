import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_dashboard.dart';

class SalesThisWeekCard extends StatefulWidget {
  const SalesThisWeekCard({
    super.key,
    required this.salesSummary,
    this.showTrend = true,
    this.showReportsLink = false,
  });

  final TenantDashboardSalesSummary? salesSummary;
  final bool showTrend;
  final bool showReportsLink;

  @override
  State<SalesThisWeekCard> createState() => _SalesThisWeekCardState();
}

class _SalesThisWeekCardState extends State<SalesThisWeekCard> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.navy,
                ),
              ),
              Row(
                children: [
                  _buildTab(0, 'Today'),
                  const SizedBox(width: 8),
                  _buildTab(1, 'This Week'),
                  const SizedBox(width: 8),
                  _buildTab(2, 'This Month'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LKR 125,450.00',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.navy,
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, color: TenantAdminColors.success, size: 16),
                    SizedBox(width: 2),
                    Text(
                      '12.6%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TenantAdminColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'vs Yesterday (LKR 111,400.00)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: _buildChart(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFFFF7A00), 'Today', isDashed: false),
              const SizedBox(width: 24),
              _buildLegendItem(TenantAdminColors.mutedText, 'Yesterday', isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7A00) : TenantAdminColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFFFF7A00) : TenantAdminColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TenantAdminColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5000,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: TenantAdminColors.border,
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                );
                Widget text;
                switch (value.toInt()) {
                  case 0: text = const Text('12 AM', style: style); break;
                  case 4: text = const Text('4 AM', style: style); break;
                  case 8: text = const Text('8 AM', style: style); break;
                  case 12: text = const Text('12 PM', style: style); break;
                  case 16: text = const Text('4 PM', style: style); break;
                  case 20: text = const Text('8 PM', style: style); break;
                  case 24: text = const Text('12 AM', style: style); break;
                  default: text = const Text('', style: style); break;
                }
                return SideTitleWidget(
                  meta: meta,
                  child: text,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5000,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${(value / 1000).toInt()}K',
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: 25000,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 0),
              FlSpot(3, 0),
              FlSpot(4, 2000),
              FlSpot(5, 5000),
              FlSpot(6, 8000),
              FlSpot(7, 7500),
              FlSpot(8, 10000),
              FlSpot(9, 13000),
              FlSpot(10, 16000),
              FlSpot(11, 19000),
              FlSpot(12, 21000),
              FlSpot(13, 19000),
              FlSpot(14, 18500),
              FlSpot(15, 16000),
              FlSpot(16, 17000),
              FlSpot(17, 15000),
              FlSpot(18, 14000),
              FlSpot(19, 13000),
              FlSpot(20, 12000),
              FlSpot(21, 17000),
              FlSpot(22, 17500),
              FlSpot(23, 17000),
            ],
            isCurved: true,
            color: const Color(0xFFFF7A00),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF7A00).withValues(alpha: 0.3),
                  const Color(0xFFFF7A00).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
