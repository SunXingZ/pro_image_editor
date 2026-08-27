// Flutter imports:
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/models/editor_configs/pixelsmix_editor_configs.dart';
import '/core/models/i18n/i18n_pixelsmix_editor.dart';

import '../models/shader_filter_state.dart';
import 'tools/blur_tool_view.dart';
import 'tools/color_balance_tool_view.dart';
import 'tools/color_matrix_tool_view.dart';
import 'tools/curve_tool_view.dart';
import 'tools/highlight_shadow_tint_tool_view.dart';
import 'tools/hsl_band_colors.dart';
import 'tools/hsl_tool_view.dart';
import 'tools/lut_tool_view.dart';
import 'tools/restorable_curve_panel.dart';
import 'tools/slider_tool_view.dart';

/// Pixelsmix 编辑器的底部工具条。
///
/// 承载当前工具对应的调节面板（曲线 / HSL / 色彩平衡等），
/// 外层结构与其它子编辑器一致。
class PixelsmixEditorBottombar extends StatelessWidget {
  /// Creates a [PixelsmixEditorBottombar].
  const PixelsmixEditorBottombar({
    super.key,
    required this.configs,
    required this.i18n,
    required this.tool,
    required this.params,
    required this.onChanged,
    this.current,
    this.onShaderStateChanged,
    this.curveController,
    this.previewSource,
  });

  /// Pixelsmix 编辑器配置。
  final PixelsmixEditorConfigs configs;

  /// 本地化文案。
  final I18nPixelsmixEditor i18n;

  /// 当前工具。
  final ShaderTool tool;

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 源图就绪通知器（供颜色矩阵预设展示当前图片缩略图）。
  final ValueListenable<ui.Image?>? previewSource;

  /// 当前生效的完整效果状态（模糊工具需要）。
  final ShaderFilterState? current;

  /// 完整状态变化回调（模糊工具在切换类型时改变工具）。
  final ValueChanged<ShaderFilterState>? onShaderStateChanged;

  /// 曲线画布 / 操作区的共享控制器（toneCurve 工具使用）。
  final CurveEditorController? curveController;

  @override
  Widget build(BuildContext context) {
    final textColor = configs.style.bottomBarInactiveItemColor;
    return Container(
      color: configs.style.bottomBarBackground,
      padding: const EdgeInsets.only(top: 5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: SingleChildScrollView(
          child: _buildToolView(textColor),
        ),
      ),
    );
  }

  Widget _buildToolView(Color textColor) {
    switch (tool) {
      case ShaderTool.toneCurve:
        return CurveToolView(
          params: params,
          onChanged: onChanged,
          curveHeight: 220,
          controller: curveController!,
          i18n: i18n,
        );

      case ShaderTool.hslMix:
        return HslToolView(
          params: params,
          onChanged: onChanged,
          i18n: i18n,
        );

      case ShaderTool.colorBalance:
        return ColorBalanceToolView(
          params: params,
          onChanged: onChanged,
          i18n: i18n,
        );

      case ShaderTool.highlightShadowTint:
        return HighlightShadowTintToolView(
          params: params,
          onChanged: onChanged,
          i18n: i18n,
        );

      case ShaderTool.colorMatrix:
        return ColorMatrixToolView(
          params: params,
          onChanged: onChanged,
          previewSource: previewSource,
          i18n: i18n,
        );

      case ShaderTool.lut:
        return LutToolView(
          params: params,
          onChanged: onChanged,
          onPickLut: configs.lutFilePicker,
          i18n: i18n,
        );

      case ShaderTool.selectiveBlur:
      case ShaderTool.tiltShiftBlur:
        if (onShaderStateChanged == null) {
          return _comingSoon(textColor);
        }
        return BlurToolView(
          current: current,
          onChanged: onShaderStateChanged!,
          i18n: i18n,
        );

      case ShaderTool.vibrance:
        return SliderToolView(
          params: params,
          onChanged: onChanged,
          textColor: textColor,
          items: [
            // RN ImageColors Vibrance：HSL 色带渐变轨道 + 中点吸附
            SliderToolItem(
              key: 'vibrance',
              label: i18n.toolLabels[ShaderTool.vibrance]!,
              initial: 50,
              snapToMiddle: true,
              trackColors: kHslBandColors,
            ),
          ],
        );

      case ShaderTool.haze:
        return SliderToolView(
          params: params,
          onChanged: onChanged,
          textColor: textColor,
          items: [
            SliderToolItem(
              key: 'haze',
              label: i18n.toolLabels[ShaderTool.haze]!,
            ),
          ],
        );

      case ShaderTool.highlightShadow:
        return SliderToolView(
          params: params,
          onChanged: onChanged,
          textColor: textColor,
          items: [
            // RN ImageColors Tone：阴影 灰→白、高光 白→灰 渐变轨道
            SliderToolItem(
              key: 'shadows',
              label: i18n.shadows,
              trackColors: const [Color(0xFF4D4D4D), Colors.white],
            ),
            SliderToolItem(
              key: 'highlights',
              label: i18n.highlights,
              trackColors: const [Colors.white, Color(0xFF4D4D4D)],
            ),
          ],
        );

      case ShaderTool.sharpen:
        return SliderToolView(
          params: params,
          onChanged: onChanged,
          textColor: textColor,
          items: [
            SliderToolItem(
              key: 'sharpen',
              label: i18n.toolLabels[ShaderTool.sharpen]!,
            ),
          ],
        );

      case ShaderTool.noise:
        return SliderToolView(
          params: params,
          onChanged: onChanged,
          textColor: textColor,
          items: [
            SliderToolItem(
              key: 'noise',
              label: i18n.toolLabels[ShaderTool.noise]!,
            ),
          ],
        );

      case ShaderTool.vignette:
        return SliderToolView(
          params: params,
          onChanged: onChanged,
          textColor: textColor,
          items: [
            SliderToolItem(
              key: 'vignette',
              label: i18n.toolLabels[ShaderTool.vignette]!,
            ),
          ],
        );
    }
  }

  Widget _comingSoon(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Text(
          i18n.comingSoon,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: textColor),
        ),
      ),
    );
  }
}
