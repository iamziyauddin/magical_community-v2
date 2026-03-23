import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  // Create a simple wellness app icon
  print('Creating wellness app icon...');

  // We'll create the icon using a simple approach
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const size = 1024.0;

  // Background - Green wellness color
  final backgroundPaint = Paint()..color = const Color(0xFF67B437);
  canvas.drawRect(Rect.fromLTWH(0, 0, size, size), backgroundPaint);

  // Draw a large heart in the center
  final heartPaint = Paint()..color = const Color(0xFFE53E3E);

  // Simple heart using two circles and a triangle
  canvas.drawCircle(const Offset(412, 400), 100, heartPaint);
  canvas.drawCircle(const Offset(612, 400), 100, heartPaint);

  final trianglePath = Path();
  trianglePath.moveTo(312, 450);
  trianglePath.lineTo(512, 650);
  trianglePath.lineTo(712, 450);
  trianglePath.close();
  canvas.drawPath(trianglePath, heartPaint);

  final picture = recorder.endRecording();
  print('App icon concept created');
}
