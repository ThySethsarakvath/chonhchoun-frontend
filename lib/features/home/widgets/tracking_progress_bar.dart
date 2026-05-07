import 'package:flutter/material.dart';
import '../models/home_models.dart';

class TrackingProgressBar extends StatelessWidget {
  final List<TrackingPoint> checkpoints;

  const TrackingProgressBar({super.key, required this.checkpoints});

  @override
  Widget build(BuildContext context) {
    if (checkpoints.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: Row(
        children: List.generate(checkpoints.length * 2 - 1, (i) {
          if (i.isEven) {
            // Dot
            final index = i ~/ 2;
            final done = checkpoints[index].completed;
            return _Dot(completed: done);
          } else {
            // Connector line
            final leftIndex = i ~/ 2;
            final done = checkpoints[leftIndex].completed &&
                checkpoints[leftIndex + 1].completed;
            return Expanded(child: _Connector(completed: done));
          }
        }),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool completed;

  const _Dot({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? const Color(0xFF2C5F8A) : Colors.white,
        border: Border.all(
          color: completed ? const Color(0xFF2C5F8A) : const Color(0xFFBCC8D8),
          width: 2,
        ),
      ),
      child: completed
          ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
          : null,
    );
  }
}

class _Connector extends StatelessWidget {
  final bool completed;

  const _Connector({required this.completed});

  @override
  Widget build(BuildContext context) {
    return completed
        ? Container(height: 2.5, color: const Color(0xFF2C5F8A))
        : _DashedLine();
  }
}

class _DashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedPainter());
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBCC8D8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}