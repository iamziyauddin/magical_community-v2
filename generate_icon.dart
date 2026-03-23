import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// This is a script to generate the app icon
// Run this with: dart run generate_icon.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 1024, 1024));

  // Background - Green wellness color
  final backgroundPaint = Paint()..color = const Color(0xFF67B437);
  canvas.drawRect(Rect.fromLTWH(0, 0, 1024, 1024), backgroundPaint);

  // Wellness Green Circle
  final greenCirclePaint = Paint()
    ..color = const Color(0xFF4CAF50)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(const Offset(512, 512), 400, greenCirclePaint);

  // Heart Shape
  final heartPaint = Paint()..color = const Color(0xFFE53E3E);

  // Draw heart using path
  final heartPath = Path();
  // Left curve
  heartPath.addOval(
    Rect.fromCircle(center: const Offset(412, 350), radius: 80),
  );
  // Right curve
  heartPath.addOval(
    Rect.fromCircle(center: const Offset(612, 350), radius: 80),
  );
  // Bottom triangle
  heartPath.moveTo(332, 380);
  heartPath.lineTo(512, 550);
  heartPath.lineTo(692, 380);
  heartPath.close();

  canvas.drawPath(heartPath, heartPaint);

  // Pulse line
  final pulsePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 8
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final pulsePath = Path();
  pulsePath.moveTo(150, 512);
  pulsePath.lineTo(300, 512);
  pulsePath.lineTo(330, 480);
  pulsePath.lineTo(360, 540);
  pulsePath.lineTo(390, 490);
  pulsePath.lineTo(420, 530);
  pulsePath.lineTo(450, 512);
  pulsePath.lineTo(574, 512);
  pulsePath.lineTo(604, 480);
  pulsePath.lineTo(634, 540);
  pulsePath.lineTo(664, 490);
  pulsePath.lineTo(694, 530);
  pulsePath.lineTo(724, 512);
  pulsePath.lineTo(874, 512);

  canvas.drawPath(pulsePath, pulsePaint);

  // Add "MC" text
  final textPainter = TextPainter(
    text: const TextSpan(
      text: 'MC',
      style: TextStyle(
        fontSize: 100,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(canvas, const Offset(462, 700));

  final picture = recorder.endRecording();
  final img = await picture.toImage(1024, 1024);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Save the file
  final file = File('assets/icons/app_icon.png');
  await file.writeAsBytes(pngBytes);

  print('App icon generated at: ${file.path}');
}
