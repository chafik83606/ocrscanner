import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const w = 1024;
  const h = 500;
  const output = 'assets/icon/play_store_feature_1024x500.png';
  const iconPath = 'assets/icon/play_store_icon_512.png';

  final banner = img.Image(width: w, height: h);
  _fillGradient(banner, 0xFF0D47A1, 0xFF1565C0, 0xFF1976D2);

  // Soft decorative circles
  _drawCircle(banner, 880, 80, 140, 0x33FFFFFF);
  _drawCircle(banner, 950, 420, 180, 0x22FFFFFF);
  _drawCircle(banner, 120, 430, 100, 0x18FFFFFF);

  final iconBytes = File(iconPath).readAsBytesSync();
  final icon = img.decodeImage(iconBytes);
  if (icon == null) {
    stderr.writeln('Icon introuvable: $iconPath');
    exit(1);
  }

  _keyWhiteToTransparent(icon, threshold: 248);

  const iconSize = 320;
  final iconResized = img.copyResize(icon, width: iconSize, height: iconSize);
  final iconX = 72;
  final iconY = (h - iconSize) ~/ 2;
  img.compositeImage(banner, iconResized, dstX: iconX, dstY: iconY);

  const textX = 430;
  img.drawString(
    banner,
    'OCR Scanner',
    font: img.arial48,
    x: textX,
    y: 155,
    color: img.ColorRgb8(255, 255, 255),
  );
  img.drawString(
    banner,
    'Scannez. Extrayez le texte.',
    font: img.arial24,
    x: textX,
    y: 230,
    color: img.ColorRgb8(227, 242, 253),
  );
  img.drawString(
    banner,
    'OCR local sur votre telephone',
    font: img.arial24,
    x: textX,
    y: 275,
    color: img.ColorRgb8(187, 222, 251),
  );

  // Accent line
  for (var x = textX; x < textX + 120; x++) {
    for (var y = 318; y < 324; y++) {
      banner.setPixel(x, y, img.ColorRgb8(16, 185, 129));
    }
  }

  File(output).writeAsBytesSync(img.encodePng(banner));
  stdout.writeln('Créé: $output (${banner.width}x${banner.height})');
}

void _keyWhiteToTransparent(img.Image image, {required int threshold}) {
  for (final p in image) {
    if (p.r > threshold && p.g > threshold && p.b > threshold) {
      p.a = 0;
    }
  }
}

void _fillGradient(img.Image image, int c1, int c2, int c3) {
  for (var y = 0; y < image.height; y++) {
    final t = y / (image.height - 1);
    final left = _lerpColor(c1, c2, t * 0.6);
    final right = _lerpColor(c2, c3, t);
    for (var x = 0; x < image.width; x++) {
      final u = x / (image.width - 1);
      final color = _lerpColor(left, right, u);
      image.setPixel(x, y, img.ColorInt8.rgb(
        (color >> 16) & 0xFF,
        (color >> 8) & 0xFF,
        color & 0xFF,
      ));
    }
  }
}

int _lerpColor(int a, int b, double t) {
  final ar = (a >> 16) & 0xFF;
  final ag = (a >> 8) & 0xFF;
  final ab = a & 0xFF;
  final br = (b >> 16) & 0xFF;
  final bg = (b >> 8) & 0xFF;
  final bb = b & 0xFF;
  return (((ar + (br - ar) * t).round()) << 16) |
      (((ag + (bg - ag) * t).round()) << 8) |
      ((ab + (bb - ab) * t).round());
}

void _drawCircle(img.Image image, int cx, int cy, int r, int colorArgb) {
  final a = (colorArgb >> 24) & 0xFF;
  final cr = (colorArgb >> 16) & 0xFF;
  final cg = (colorArgb >> 8) & 0xFF;
  final cb = colorArgb & 0xFF;
  for (var y = math.max(0, cy - r); y < math.min(image.height, cy + r); y++) {
    for (var x = math.max(0, cx - r); x < math.min(image.width, cx + r); x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= r * r) {
        final existing = image.getPixel(x, y);
        final er = existing.r.toInt();
        final eg = existing.g.toInt();
        final eb = existing.b.toInt();
        final t = a / 255.0;
        image.setPixel(
          x,
          y,
          img.ColorRgb8(
            (er * (1 - t) + cr * t).round(),
            (eg * (1 - t) + cg * t).round(),
            (eb * (1 - t) + cb * t).round(),
          ),
        );
      }
    }
  }
}
