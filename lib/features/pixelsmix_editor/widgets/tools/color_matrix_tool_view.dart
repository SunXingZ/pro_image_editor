import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';
import '/shared/utils/color_matrix_presets.dart';

/// 颜色矩阵工具面板（对齐 RN `ImageLens`）。
///
/// RN 端颜色矩阵实际上是一组调好的滤镜，这里以预设网格形式展示：
/// 顶部按分类切换（全部 / 推荐 / 暖 / 冷 / 黑白），下方排布预设。
/// 每个预设使用 [previewSource]（当前编辑图片）渲染真实缩略图；
/// 源图未就绪时回退为色点预览。
/// 参数结构：`{'matrix': [16 doubles], 'preset': String}`。
class ColorMatrixToolView extends StatefulWidget {
  /// Creates a [ColorMatrixToolView].
  const ColorMatrixToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.i18n,
    this.previewSource,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 本地化文案（分类标签）。
  final I18nPixelsmixEditor i18n;

  /// 源图就绪通知器（当前编辑图片）。
  final ValueListenable<ui.Image?>? previewSource;

  @override
  State<ColorMatrixToolView> createState() => _ColorMatrixToolViewState();
}

class _ColorMatrixToolViewState extends State<ColorMatrixToolView> {
  /// 分类 key + 显示名（全部 / 推荐 / 暖 / 冷 / 黑白）。
  List<(String, String)> get _classifies => [
        ('all', widget.i18n.colorMatrixAll),
        ('recommend', widget.i18n.colorMatrixRecommended),
        ('warm', widget.i18n.colorMatrixWarm),
        ('cool', widget.i18n.colorMatrixCool),
        ('bw', widget.i18n.colorMatrixBw),
      ];

  String _classify = 'all';

  String get _preset => widget.params['preset'] as String? ?? '';

  List<ColorMatrixPreset> get _visible => _classify == 'all'
      ? colorMatrixPresets
      : colorMatrixPresets.where((p) => p.classify == _classify).toList();

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 分类切换
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (key, label) in _classifies)
                GestureDetector(
                  onTap: () => setState(() => _classify = key),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _classify == key
                            ? const Color(0xFFFFD700)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color:
                            _classify == key ? const Color(0xFFFFD700) : color,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 预设网格
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 130),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in _visible)
                    GestureDetector(
                      onTap: () => widget.onChanged({
                        ...widget.params,
                        'matrix': preset.matrix,
                        'preset': preset.name,
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _preset == preset.name
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _preset == preset.name
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF333333),
                            width: _preset == preset.name ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildThumbnail(preset),
                            const SizedBox(height: 4),
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: _preset == preset.name
                                    ? const Color(0xFFFFD700)
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 预设缩略图：使用当前编辑图片 + 颜色矩阵滤镜；源图未就绪时回退色点。
  Widget _buildThumbnail(ColorMatrixPreset preset) {
    const size = 44.0;
    final notifier = widget.previewSource;
    if (notifier != null) {
      return ValueListenableBuilder<ui.Image?>(
        valueListenable: notifier,
        builder: (context, image, child) {
          if (image == null) {
            return _fallbackDot(preset, size);
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_matrix20(preset)),
              child: RawImage(
                image: image,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }
    return _fallbackDot(preset, size);
  }

  Widget _fallbackDot(ColorMatrixPreset preset, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _previewColor(preset),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// 把 16 值矩阵还原为 4x5（补 0 offset），供 [ColorFilter.matrix] 使用。
  List<double> _matrix20(ColorMatrixPreset preset) {
    final m = preset.matrix;
    return [
      m[0], m[1], m[2], m[3], 0, //
      m[4], m[5], m[6], m[7], 0, //
      m[8], m[9], m[10], m[11], 0, //
      m[12], m[13], m[14], m[15], 0, //
    ];
  }

  /// 用矩阵对红色基准色近似取色，作为未加载源图时的色点预览。
  Color _previewColor(ColorMatrixPreset preset) {
    final m = preset.matrix;
    double apply(int i, double v) =>
        (m[i] * v + m[i + 1] * 0 + m[i + 2] * 0).clamp(0.0, 1.0);
    return Color.fromARGB(
      255,
      (apply(0, 1) * 255).round(),
      (apply(4, 1) * 255).round(),
      (apply(8, 1) * 255).round(),
    );
  }
}
