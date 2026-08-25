import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Estado visual de una planta, derivado de qué tan vencido está su riego.
enum PlantHealth { healthy, thirsty, critical }

/// Animación de una planta "respirando" hecha en Flutter puro.
///
/// Sirve como reemplazo temporal de una animación Rive: una vez tengamos
/// un archivo `.riv` (editor de Rive) con un state machine para los tres
/// estados de [PlantHealth], este widget se puede intercambiar por un
/// `RiveWidget` sin tocar quienes lo consumen (mismo constructor).
class PlantHealthAnimation extends StatefulWidget {
  const PlantHealthAnimation({
    super.key,
    this.health = PlantHealth.healthy,
    this.size = 96,
  });

  final PlantHealth health;
  final double size;

  @override
  State<PlantHealthAnimation> createState() => _PlantHealthAnimationState();
}

class _PlantHealthAnimationState extends State<PlantHealthAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _PlantPainter(
            progress: _controller.value,
            health: widget.health,
          ),
        );
      },
    );
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter({required this.progress, required this.health});

  final double progress;
  final PlantHealth health;

  Color get _leafColor => switch (health) {
        PlantHealth.healthy => const Color(0xFF3FA26B),
        PlantHealth.thirsty => const Color(0xFF8FA83F),
        PlantHealth.critical => const Color(0xFFB08340),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final sway = math.sin(progress * math.pi * 2) * 0.06;
    final bob = math.sin(progress * math.pi * 2) * size.height * 0.015;

    final potPaint = Paint()..color = const Color(0xFFC97B4A);
    final potRect = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.72,
      size.width * 0.44,
      size.height * 0.24,
    );
    final potPath = Path()
      ..moveTo(potRect.left + potRect.width * 0.1, potRect.top)
      ..lineTo(potRect.right - potRect.width * 0.1, potRect.top)
      ..lineTo(potRect.right, potRect.bottom)
      ..lineTo(potRect.left, potRect.bottom)
      ..close();
    canvas.drawPath(potPath, potPaint);

    final leafPaint = Paint()..color = _leafColor;
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D5B)
      ..strokeWidth = size.width * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(size.width / 2, potRect.top + bob);
    canvas.rotate(sway);

    final stemTop = Offset(0, -size.height * 0.42);
    canvas.drawLine(Offset.zero, stemTop, stemPaint);

    void drawLeaf(Offset origin, double angle, double scale) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      final leafRect = Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.34 * scale,
        height: size.width * 0.2 * scale,
      );
      canvas.drawOval(leafRect, leafPaint);
      canvas.restore();
    }

    drawLeaf(Offset(stemTop.dx, stemTop.dy + size.height * 0.06),
        -math.pi / 5 + sway, 1);
    drawLeaf(Offset(stemTop.dx, stemTop.dy + size.height * 0.06),
        math.pi / 5 + sway, 1);
    drawLeaf(stemTop, sway, 1.15);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.health != health;
  }
}
