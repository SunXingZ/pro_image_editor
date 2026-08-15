import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '/core/models/editor_image.dart';

/// 将 [EditorImage] 解码为 [ui.Image]，供需要源图的 shader 工具
/// （如圆形/线性模糊）使用。
///
/// 解码是异步的；完成前 [builder] 收到 `null`，相关效果暂不生效。
class SourceImageLoader extends StatefulWidget {
  /// Creates a [SourceImageLoader].
  const SourceImageLoader({
    super.key,
    required this.image,
    required this.builder,
  });

  /// 需要解码的图像；为空（如视频编辑器）时 [builder] 恒收到 `null`。
  final EditorImage? image;

  /// 解码结果构建回调。
  final Widget Function(ui.Image? image) builder;

  @override
  State<SourceImageLoader> createState() => _SourceImageLoaderState();
}

class _SourceImageLoaderState extends State<SourceImageLoader> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant SourceImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _image = null;
      _decode();
    }
  }

  Future<void> _decode() async {
    final image = widget.image;
    if (image == null) return;
    try {
      final bytes = await image.safeByteArray(context);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _image = frame.image);
    } catch (_) {
      // 解码失败则忽略，相关效果不生效。
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_image);
}
