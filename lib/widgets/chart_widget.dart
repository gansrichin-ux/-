import 'package:flutter/material.dart';
import '../core/providers/cargo_providers.dart';

class CargoStatusChart extends StatelessWidget {
  final CargoStats stats;

  const CargoStatusChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = [
      ChartData('Новые', stats.newCount, const Color(0xFF3B82F6)),
      ChartData('В пути', stats.inTransit, const Color(0xFFF59E0B)),
      ChartData('Доставлено', stats.completed, const Color(0xFF22C55E)),
      ChartData('Отменено', stats.cancelled, const Color(0xFFEF4444)),
    ];

    final total = data.fold(0, (sum, item) => sum + item.value);
    
    if (total == 0) {
      return const Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 120,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomPaint(
                  painter: PieChartPainter(data),
                  child: const Center(),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((item) {
                    if (item.value == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.label} (${item.value})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        // Percentage bars
        const SizedBox(height: 16),
        ...data.map((item) {
          if (item.value == 0) return const SizedBox.shrink();
          final percentage = (item.value / total * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: item.value / total,
                  backgroundColor: const Color(0xFF334155),
                  valueColor: AlwaysStoppedAnimation<Color>(item.color),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class ChartData {
  final String label;
  final int value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}

class PieChartPainter extends CustomPainter {
  final List<ChartData> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    final total = data.fold(0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -pi / 2;

    for (final item in data) {
      if (item.value == 0) continue;
      
      final sweepAngle = (item.value / total) * 2 * pi;
      
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const double pi = 3.1415926535897932;
