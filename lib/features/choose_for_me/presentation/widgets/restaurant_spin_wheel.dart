import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';

/// A spin wheel with [segmentCount] segments and labels. [rotation] is in radians
/// (parent drives this from an animation). [highlightSegmentIndex] is drawn with
/// emphasis when the wheel has stopped (e.g. winner).
class RestaurantSpinWheel extends StatelessWidget {
  const RestaurantSpinWheel({
    super.key,
    required this.labels,
    required this.rotation,
    this.highlightSegmentIndex,
    this.size = 280,
  });

  final List<String> labels;
  final double rotation;
  final int? highlightSegmentIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: Size(size, size),
              painter: _WheelPainter(
                labels: labels,
                highlightIndex: highlightSegmentIndex,
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _Pointer(),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.labels, this.highlightIndex});

  final List<String> labels;
  final int? highlightIndex;

  static const int _segmentCount = 8;
  static const double _strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final n = math.min(_segmentCount, labels.isNotEmpty ? labels.length : 1);
    final sweepAngle = 2 * math.pi / n;
    // So segment 0 is at top (12 o'clock): start at -pi/2.
    const startAngle = -math.pi / 2;

    for (int i = 0; i < n; i++) {
      final isHighlight = highlightIndex != null && i == highlightIndex;
      final color = isHighlight
          ? AppTheme.specGold
          : (i.isEven ? AppTheme.specNavy : AppTheme.specNavy.withValues(alpha: 0.85));
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle + i * sweepAngle, sweepAngle, true, paint);

      final borderPaint = Paint()
        ..color = AppTheme.specWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth;
      canvas.drawArc(rect, startAngle + i * sweepAngle, sweepAngle, true, borderPaint);

      final label = i < labels.length ? labels[i] : '?';
      final segmentMidAngle = startAngle + (i + 0.5) * sweepAngle;
      _drawSegmentLabel(canvas, center, radius * 0.72, segmentMidAngle, label, isHighlight);
    }

    final centerCirclePaint = Paint()
      ..color = AppTheme.specWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.12, centerCirclePaint);
    final centerBorderPaint = Paint()
      ..color = AppTheme.specGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.12, centerBorderPaint);
  }

  void _drawSegmentLabel(Canvas canvas, Offset center, double radius, double angle, String text, bool highlight) {
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);
    final labelCenter = center + Offset(dx, dy);

    canvas.save();
    canvas.translate(labelCenter.dx, labelCenter.dy);
    canvas.rotate(angle + math.pi / 2);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text.length > 12 ? '${text.substring(0, 11)}…' : text,
        style: TextStyle(
          fontSize: highlight ? 15 : 13,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          color: AppTheme.specWhite,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 80);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}

class _Pointer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 24),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppTheme.specGold);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.specNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
