import '/features/pixelsmix_editor/models/shader_filter_state.dart';

/// Internationalization (i18n) settings for the Pixelsmix editor.
class I18nPixelsmixEditor {
  /// Creates an instance of [I18nPixelsmixEditor].
  const I18nPixelsmixEditor({
    Map<ShaderTool, String>? toolLabels,
    this.back = 'Back',
    this.done = 'Done',
    this.comingSoon = 'Coming soon',
  }) : toolLabels = toolLabels ?? _defaultToolLabels;

  /// 各工具的显示名称（底部入口与编辑页标题共用）。
  static const Map<ShaderTool, String> _defaultToolLabels = {
    ShaderTool.toneCurve: 'Curve',
    ShaderTool.hslMix: 'HSL',
    ShaderTool.colorBalance: 'Color Balance',
    ShaderTool.highlightShadowTint: 'Tint',
    ShaderTool.vibrance: 'Vibrance',
    ShaderTool.haze: 'Haze',
    ShaderTool.highlightShadow: 'Highlight',
    ShaderTool.sharpen: 'Sharpen',
    ShaderTool.noise: 'Noise',
    ShaderTool.vignette: 'Vignette',
    ShaderTool.colorMatrix: 'Color Matrix',
    ShaderTool.lut: 'LUT',
    ShaderTool.selectiveBlur: 'Blur',
    ShaderTool.tiltShiftBlur: 'Blur',
  };

  /// 各工具的显示名称。
  final Map<ShaderTool, String> toolLabels;

  /// Text for the "Back" button.
  final String back;

  /// Text for the "Done" button.
  final String done;

  /// Text shown for not-yet-implemented tools.
  final String comingSoon;

  /// Creates a copy with modified fields.
  I18nPixelsmixEditor copyWith({
    Map<ShaderTool, String>? toolLabels,
    String? back,
    String? done,
    String? comingSoon,
  }) {
    return I18nPixelsmixEditor(
      toolLabels: toolLabels ?? this.toolLabels,
      back: back ?? this.back,
      done: done ?? this.done,
      comingSoon: comingSoon ?? this.comingSoon,
    );
  }
}
