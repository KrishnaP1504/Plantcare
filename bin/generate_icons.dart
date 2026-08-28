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
  final logo = img.decodeImage(rawBytes);
  if (logo == null) {
    print('Error: Failed to decode app_logo.png');
    return;
  }

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

    final resized = img.copyResize(logo, width: entry.value, height: entry.value);
    final pngBytes = Uint8List.fromList(img.encodePng(resized));

    File('${dir.path}/ic_launcher.png').writeAsBytesSync(pngBytes);
    File('${dir.path}/ic_launcher_round.png').writeAsBytesSync(pngBytes);
    print('Generated ${dir.path}/ic_launcher.png (${entry.value}x${entry.value})');
  }

  print('Launcher icons generated successfully!');
}
