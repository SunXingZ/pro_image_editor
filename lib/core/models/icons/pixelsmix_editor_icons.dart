// Flutter imports:
import 'package:flutter/material.dart';

import '/features/pixelsmix_editor/models/shader_filter_state.dart';

/// A configuration class for defining icons used in the Pixelsmix editor.
class PixelsmixEditorIcons {
  /// Creates a [PixelsmixEditorIcons] instance.
  const PixelsmixEditorIcons({
    Map<ShaderTool, IconData>? tools,
    this.bottomNavBar = Icons.auto_fix_high,
    this.backButton = Icons.arrow_back,
    this.applyChanges = Icons.done,
  }) : tools = tools ?? _defaultTools;

  /// 各工具对应的底部入口图标。
  static const Map<ShaderTool, IconData> _defaultTools = {
    ShaderTool.toneCurve: Icons.show_chart,
    ShaderTool.hslMix: Icons.palette_outlined,
    ShaderTool.colorBalance: Icons.tonality,
    ShaderTool.toneSeparation: Icons.gradient,
    ShaderTool.vibrance: Icons.auto_awesome,
    ShaderTool.haze: Icons.blur_on,
    ShaderTool.highlightShadow: Icons.brightness_6,
    ShaderTool.sharpen: Icons.highlight,
    ShaderTool.noise: Icons.grain,
    ShaderTool.vignette: Icons.center_focus_strong,
    ShaderTool.filter: Icons.photo_filter,
    ShaderTool.lut: Icons.grid_view,
    ShaderTool.selectiveBlur: Icons.blur_circular,
    ShaderTool.tiltShiftBlur: Icons.blur_linear,
  };

  /// 各工具对应的底部入口图标。
  final Map<ShaderTool, IconData> tools;

  /// Icon for the bottom navigation bar item that opens the Pixelsmix editor.
  final IconData bottomNavBar;

  /// The icon for the back button.
  final IconData backButton;

  /// The icon for applying changes in the editor.
  final IconData applyChanges;

  /// Creates a copy with modified fields.
  PixelsmixEditorIcons copyWith({
    Map<ShaderTool, IconData>? tools,
    IconData? bottomNavBar,
    IconData? backButton,
    IconData? applyChanges,
  }) {
    return PixelsmixEditorIcons(
      tools: tools ?? this.tools,
      bottomNavBar: bottomNavBar ?? this.bottomNavBar,
      backButton: backButton ?? this.backButton,
      applyChanges: applyChanges ?? this.applyChanges,
    );
  }
}
