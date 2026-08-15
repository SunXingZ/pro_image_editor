import '/core/enums/editor_mode.dart';

import '../models/shader_filter_state.dart';

/// 将 [SubEditorMode] 映射为对应的 [ShaderTool]。
///
/// 非 Pixelsmix 工具返回 `null`。
ShaderTool? shaderToolOf(SubEditorMode mode) => switch (mode) {
      SubEditorMode.pixelsmixCurve => ShaderTool.toneCurve,
      SubEditorMode.pixelsmixHsl => ShaderTool.hslMix,
      SubEditorMode.pixelsmixColorBalance => ShaderTool.colorBalance,
      SubEditorMode.pixelsmixHighlightShadowTint =>
        ShaderTool.highlightShadowTint,
      SubEditorMode.pixelsmixVibrance => ShaderTool.vibrance,
      SubEditorMode.pixelsmixHaze => ShaderTool.haze,
      SubEditorMode.pixelsmixHighlightShadow => ShaderTool.highlightShadow,
      SubEditorMode.pixelsmixSharpen => ShaderTool.sharpen,
      SubEditorMode.pixelsmixNoise => ShaderTool.noise,
      SubEditorMode.pixelsmixVignette => ShaderTool.vignette,
      SubEditorMode.pixelsmixColorMatrix => ShaderTool.colorMatrix,
      SubEditorMode.pixelsmixLut => ShaderTool.lut,
      SubEditorMode.pixelsmixBlur => ShaderTool.selectiveBlur,
      _ => null,
    };
