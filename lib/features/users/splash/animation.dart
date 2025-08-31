import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

class FitBuddy3DWidget extends StatelessWidget {
  const FitBuddy3DWidget({super.key, this.size = const Size(360, 500)});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: FitBuddy3DPainter(),
    );
  }
}

class FitBuddy3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 30);

    // --- BODY GLOW ---
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xAFA3FF3F),
          Color(0x00A3FF3F),
        ],
        stops: const [0.1, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 180));
    canvas.drawCircle(center, 170, glowPaint);

    // --- BODY (OVAL WITH GRADIENT) ---
    final bodyRect = Rect.fromCenter(center: center, width: 220, height: 260);
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - 100),
        Offset(center.dx, center.dy + 130),
        [
          const Color(0xFFBEFF80),
          const Color(0xFFA3FF3F),
          const Color(0xFF74D32E),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawOval(bodyRect, bodyPaint);

    // --- SHADOW UNDER BODY ---
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, 135), width: 110, height: 28),
      shadowPaint,
    );

    // --- HEADBAND ---
    final headbandPaint = Paint()..color = const Color(0xFF1D7874);
    final bandRect = Rect.fromCenter(
        center: center + Offset(0, -80), width: 140, height: 32);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, const Radius.circular(20)),
        headbandPaint);

    // --- CHEEKS ---
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: 0.8);
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(-48, -10), width: 30, height: 18),
        cheekPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(48, -10), width: 30, height: 18),
        cheekPaint);

    // --- EYES ---
    final eyeWhite = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(-36, -42), width: 32, height: 40),
        eyeWhite);
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(36, -42), width: 32, height: 40),
        eyeWhite);

    // Pupils
    final pupilPaint = Paint()..color = const Color(0xFF192615);
    canvas.drawCircle(center + Offset(-36, -35), 13, pupilPaint);
    canvas.drawCircle(center + Offset(36, -35), 13, pupilPaint);

    // Eye highlight
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center + Offset(-41, -39), 4, highlight);
    canvas.drawCircle(center + Offset(31, -39), 4, highlight);

    // --- MOUTH (OVAL) ---
    final mouthPaint = Paint()..color = const Color(0xFF993300);
    canvas.drawOval(
        Rect.fromCenter(center: center + Offset(0, 14), width: 38, height: 23),
        mouthPaint);

    // --- TONGUE ---
    final tonguePaint = Paint()..color = const Color(0xFFFFA27B);
    canvas.drawOval(
        Rect.fromCenter(center: center + Offset(0, 23), width: 18, height: 10),
        tonguePaint);

    // --- ARMS (plush, 3D) ---
    final armPaint = Paint()
      ..shader = ui.Gradient.linear(
        center + Offset(-105, 30),
        center + Offset(-150, 75),
        [const Color(0xFFCCFF80), const Color(0xFFA3FF3F)],
      );
    // Left
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(-115, 40), width: 38, height: 62),
        armPaint);
    // Right (waving)
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(115, 25), width: 38, height: 62),
        armPaint);

    // --- LEGS (plush, 3D) ---
    final legPaint = Paint()
      ..shader = ui.Gradient.linear(
        center + Offset(-45, 118),
        center + Offset(-45, 160),
        [const Color(0xFFA3FF3F), const Color(0xFF74D32E)],
      );
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(-42, 120), width: 32, height: 48),
        legPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(42, 120), width: 32, height: 48),
        legPaint);

    final shirtPaint = Paint()..color = const Color(0xFF1D7874);
    final shirtRect =
        Rect.fromCenter(center: center + Offset(0, 48), width: 160, height: 82);
    canvas.drawRRect(
        RRect.fromRectAndRadius(shirtRect, const Radius.circular(34)),
        shirtPaint);

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 30,
      fontWeight: FontWeight.bold,
      fontFamily: 'Sans',
    );
    final textSpan = TextSpan(text: 'Fit Buddy', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: 150);
    textPainter.paint(canvas, center + Offset(-75, 30));

    // --- DUMBBELL (LEFT HAND) ---
    final dumbbellPaint = Paint()..color = const Color(0xFFFF9500);
    // Handle
    canvas.drawRect(
        Rect.fromCenter(
            center: center + Offset(-140, 70), width: 34, height: 12),
        dumbbellPaint);
    // Ends
    canvas.drawCircle(center + Offset(-124, 70), 18, dumbbellPaint);
    canvas.drawCircle(center + Offset(-156, 70), 18, dumbbellPaint);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
