// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  final size = 1024;
  final image = img.Image(width: size, height: size);

  // Fill with deep green (#1B5E20)
  final green = img.ColorRgba8(0x1B, 0x5E, 0x20, 0xFF);
  final gold = img.ColorRgba8(0xFF, 0xD7, 0x00, 0xFF);
  final white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);
  final darkGreen = img.ColorRgba8(0x0D, 0x3B, 0x0F, 0xFF);

  // Fill background with deep green
  img.fill(image, color: green);

  // Draw a circle in the center (lighter border)
  final cx = size ~/ 2;
  final cy = size ~/ 2;
  final radius = (size * 0.38).toInt();

  // Draw gold circle outline
  for (int angle = 0; angle < 3600; angle++) {
    final a = angle * 3.14159265 / 1800;
    for (int r = radius - 8; r <= radius + 8; r++) {
      final x = cx + (r * _cos(a)).toInt();
      final y = cy + (r * _sin(a)).toInt();
      if (x >= 0 && x < size && y >= 0 && y < size) {
        image.setPixel(x, y, gold);
      }
    }
  }

  // Draw crescent moon (Islamic symbol) - two overlapping circles 
  final moonCx = cx;
  final moonCy = cy - 30;
  final moonR = (size * 0.22).toInt();
  final moonOffset = (size * 0.07).toInt();

  // Draw outer moon circle in gold
  _fillCircle(image, moonCx, moonCy, moonR, gold);
  // Cut out inner circle (shift right) to create crescent
  _fillCircle(image, moonCx + moonOffset, moonCy - moonOffset ~/ 2, (moonR * 0.85).toInt(), green);

  // Draw star next to crescent
  final starCx = cx + moonR ~/ 2 + 10;
  final starCy = cy - moonR ~/ 2 - 20;
  _drawStar(image, starCx, starCy, (size * 0.05).toInt(), gold);

  // Draw "B" letter at the bottom
  final letterY = cy + (size * 0.15).toInt();
  _drawB(image, cx, letterY, (size * 0.12).toInt(), white);

  // Save
  final outputDir = Directory('assets/icon');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(image));
  print('Icon generated: assets/icon/icon.png');
}

double _cos(double a) => _cosApprox(a);
double _sin(double a) => _cosApprox(a - 1.5707963);

double _cosApprox(double x) {
  // Normalize x
  while (x > 3.14159265) {
    x -= 6.28318530;
  }
  while (x < -3.14159265) {
    x += 6.28318530;
  }
  final x2 = x * x;
  return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720 + x2 * x2 * x2 * x2 / 40320;
}

void _fillCircle(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (int y = cy - radius; y <= cy + radius; y++) {
    for (int x = cx - radius; x <= cx + radius; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        final dx = x - cx;
        final dy = y - cy;
        if (dx * dx + dy * dy <= radius * radius) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

void _drawStar(img.Image image, int cx, int cy, int size, img.Color color) {
  // Simple 5-pointed star using filled diamond
  _fillCircle(image, cx, cy, size ~/ 2, color);
}

void _drawB(img.Image image, int cx, int cy, int size, img.Color color) {
  // Draw a simple thick "B" using rectangles
  final halfW = size ~/ 3;
  final halfH = size ~/ 2;
  final thickness = size ~/ 6;

  // Vertical bar
  for (int y = cy - halfH; y <= cy + halfH; y++) {
    for (int x = cx - halfW; x <= cx - halfW + thickness; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, color);
      }
    }
  }

  // Top horizontal
  for (int y = cy - halfH; y <= cy - halfH + thickness; y++) {
    for (int x = cx - halfW; x <= cx + halfW; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, color);
      }
    }
  }

  // Middle horizontal
  for (int y = cy - thickness ~/ 2; y <= cy + thickness ~/ 2; y++) {
    for (int x = cx - halfW; x <= cx + halfW; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, color);
      }
    }
  }

  // Bottom horizontal
  for (int y = cy + halfH - thickness; y <= cy + halfH; y++) {
    for (int x = cx - halfW; x <= cx + halfW; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, color);
      }
    }
  }

  // Right top bump
  final bumpR = halfH ~/ 3;
  _fillCircle(image, cx + halfW, cy - halfH ~/ 2 + thickness ~/ 2, bumpR, color);
  // Right bottom bump
  _fillCircle(image, cx + halfW, cy + halfH ~/ 2 - thickness ~/ 2, bumpR, color);
}
