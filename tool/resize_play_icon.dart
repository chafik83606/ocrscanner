import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const input = 'assets/icon/app_icon.png';
  const output = 'assets/icon/play_store_icon_512.png';
  const size = 512;

  final bytes = File(input).readAsBytesSync();
  final source = img.decodeImage(bytes);
  if (source == null) {
    stderr.writeln('Impossible de lire $input');
    exit(1);
  }

  stdout.writeln('Source: ${source.width}x${source.height}');

  final side = source.width < source.height ? source.width : source.height;
  final x = (source.width - side) ~/ 2;
  final y = (source.height - side) ~/ 2;
  final square = img.copyCrop(source, x: x, y: y, width: side, height: side);
  final resized = img.copyResize(square, width: size, height: size);
  File(output).writeAsBytesSync(img.encodePng(resized));

  stdout.writeln('Créé: $output (${resized.width}x${resized.height})');
}
