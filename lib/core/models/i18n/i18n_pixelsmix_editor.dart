import '/features/pixelsmix_editor/models/shader_filter_state.dart';

/// Internationalization (i18n) settings for the Pixelsmix editor.
class I18nPixelsmixEditor {
  /// Creates an instance of [I18nPixelsmixEditor].
  const I18nPixelsmixEditor({
    Map<ShaderTool, String>? toolLabels,
    this.back = 'Back',
    this.done = 'Done',
    this.comingSoon = 'Coming soon',
    this.intensity = 'Intensity',
    this.enable = 'Enable',
    this.selectFile = 'Select file',
    this.lutNotConfigured = 'LUT picker not configured',
    this.filterOriginal = 'Original',
    this.circular = 'Circular',
    this.linear = 'Linear',
    this.shadows = 'Shadows',
    this.midtones = 'Midtones',
    this.highlights = 'Highlights',
    this.shadow = 'Shadow',
    this.highlight = 'Highlight',
    this.hue = 'Hue',
    this.saturation = 'Saturation',
    this.lightness = 'Lightness',
    this.resetCurve = 'Reset curve',
    this.toggleGrid = 'Show/Hide grid',
    this.toggleCurveCanvas = 'Show/Hide curve canvas',
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
    ShaderTool.filter: 'Filter',
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

  /// Label of the intensity slider used by LUT / blur tools.
  final String intensity;

  /// Label of the enable switch used by the LUT tool.
  final String enable;

  /// Label of the "select file" button used by the LUT tool.
  final String selectFile;

  /// Text shown when no LUT file picker is configured.
  final String lutNotConfigured;

  /// Label of the circular blur type.
  final String circular;

  /// Label of the linear blur type.
  final String linear;

  /// Label of the shadows band (color balance / highlight-shadow).
  final String shadows;

  /// Label of the midtones band (color balance).
  final String midtones;

  /// Label of the highlights band (color balance / highlight-shadow).
  final String highlights;

  /// Label of the shadow tint row (highlight-shadow-tint tool).
  final String shadow;

  /// Label of the highlight tint row (highlight-shadow-tint tool).
  final String highlight;

  /// Label of the hue channel (HSL tool).
  final String hue;

  /// Label of the saturation channel (HSL tool).
  final String saturation;

  /// Label of the lightness channel (HSL tool).
  final String lightness;

  /// Label of the "original / no filter" chip in the filter tool.
  final String filterOriginal;

  /// Tooltip of the "reset curve" button.
  final String resetCurve;

  /// Tooltip of the "show/hide grid" button.
  final String toggleGrid;

  /// Tooltip of the "show/hide curve canvas" button.
  final String toggleCurveCanvas;

  /// Creates a copy with modified fields.
  I18nPixelsmixEditor copyWith({
    Map<ShaderTool, String>? toolLabels,
    String? back,
    String? done,
    String? comingSoon,
    String? intensity,
    String? enable,
    String? selectFile,
    String? lutNotConfigured,
    String? circular,
    String? linear,
    String? shadows,
    String? midtones,
    String? highlights,
    String? shadow,
    String? highlight,
    String? hue,
    String? saturation,
    String? lightness,
    String? filterOriginal,
    String? resetCurve,
    String? toggleGrid,
    String? toggleCurveCanvas,
  }) {
    return I18nPixelsmixEditor(
      toolLabels: toolLabels ?? this.toolLabels,
      back: back ?? this.back,
      done: done ?? this.done,
      comingSoon: comingSoon ?? this.comingSoon,
      intensity: intensity ?? this.intensity,
      enable: enable ?? this.enable,
      selectFile: selectFile ?? this.selectFile,
      lutNotConfigured: lutNotConfigured ?? this.lutNotConfigured,
      circular: circular ?? this.circular,
      linear: linear ?? this.linear,
      shadows: shadows ?? this.shadows,
      midtones: midtones ?? this.midtones,
      highlights: highlights ?? this.highlights,
      shadow: shadow ?? this.shadow,
      highlight: highlight ?? this.highlight,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      lightness: lightness ?? this.lightness,
      filterOriginal: filterOriginal ?? this.filterOriginal,
      resetCurve: resetCurve ?? this.resetCurve,
      toggleGrid: toggleGrid ?? this.toggleGrid,
      toggleCurveCanvas: toggleCurveCanvas ?? this.toggleCurveCanvas,
    );
  }
}
