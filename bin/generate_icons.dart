import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('assets/images/app_logo.png');
  if (!logoFile.existsSync()) {
    print('Error: assets/images/app_logo.png not found');
    return;
  }

  final rawBytes = logoFile.readAsBytesSync();
  final logo = img.decodePng(rawBytes);
  if (logo == null) {
    print('Error: Failed to decode app_logo.png');
    return;
  }

  print('Original logo size: ${logo.width}x${logo.height}');

  // For launcher icons: create a square canvas with white background and logo centered with padding
  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final dir = Directory('android/app/src/main/res/${entry.key}');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final iconSize = entry.value;
    // Create white background canvas
    final canvas = img.Image(width: iconSize, height: iconSize, numChannels: 4);
    // Fill with white
    for (int y = 0; y < iconSize; y++) {
      for (int x = 0; x < iconSize; x++) {
        canvas.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }

    // Calculate logo area with 10% padding on each side
    final padding = (iconSize * 0.10).round();
    final logoArea = iconSize - (padding * 2);

    // Resize logo to fit inside the padded area, preserving aspect ratio
    final logoAspect = logo.width / logo.height;
    int resizedW, resizedH;
    if (logoAspect >= 1.0) {
      resizedW = logoArea;
      resizedH = (logoArea / logoAspect).round();
    } else {
      resizedH = logoArea;
      resizedW = (logoArea * logoAspect).round();
    }

    final resizedLogo = img.copyResize(logo, width: resizedW, height: resizedH);

    // Center the resized logo on the canvas
    final offsetX = ((iconSize - resizedW) / 2).round();
    final offsetY = ((iconSize - resizedH) / 2).round();

    img.compositeImage(canvas, resizedLogo, dstX: offsetX, dstY: offsetY);

    final pngBytes = Uint8List.fromList(img.encodePng(canvas));

    File('${dir.path}/ic_launcher.png').writeAsBytesSync(pngBytes);
    File('${dir.path}/ic_launcher_round.png').writeAsBytesSync(pngBytes);
    print('Generated ${dir.path}/ic_launcher.png (${iconSize}x${iconSize})');
  }

  print('All launcher icons generated successfully!');
}
