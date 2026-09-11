// 探测 flutter test 环境是否支持 ImageFilter.shader（Impeller）。
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('probe ImageFilter.shader support', () async {
    // ignore: avoid_print
    print('isShaderFilterSupported=${ui.ImageFilter.isShaderFilterSupported}');

    final program = await ui.FragmentProgram.fromAsset(
      'lib/shared/shaders/pixelsmix/color_matrix.frag',
    );
    final shader = program.fragmentShader();

    // 恒等矩阵：tune 全 0 参数时 tuneMatrix 的期望值。
    final identity = <double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];
    for (var i = 0; i < 20; i++) {
      shader.setFloat(i + 2, identity[i]);
    }

    // 构造 4x4 已知像素图。
    const w = 4, h = 4;
    final pixels = Uint8List.fromList(List.generate(w * h * 4, (i) {
      final px = i ~/ 4 % w, py = i ~/ 4 ~/ w;
      if (i % 4 == 3) return 255;
      return ((px * 64 + py * 16) + i % 4) % 256;
    }));
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final src = await completer.future;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    canvas.saveLayer(rect, ui.Paint()..imageFilter = ui.ImageFilter.shader(shader));
    canvas.drawImage(src, ui.Offset.zero, ui.Paint());
    canvas.restore();
    final out = await recorder.endRecording().toImage(w, h);
    final data = await out.toByteData();

    // ignore: avoid_print
    print('output first pixel: ${data!.buffer.asUint8List().take(8).toList()}');
  });
}
