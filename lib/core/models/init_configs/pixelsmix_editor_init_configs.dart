// Project imports:
import '/features/pixelsmix_editor/models/shader_filter_state.dart';
import 'editor_init_configs.dart';

/// Configuration class for initializing the Pixelsmix editor.
///
/// 在 [EditorInitConfigs] 基础上增加当前工具类型与已应用的 shader 效果。
class PixelsmixEditorInitConfigs extends EditorInitConfigs {
  /// Creates a new instance of [PixelsmixEditorInitConfigs].
  const PixelsmixEditorInitConfigs({
    super.transformConfigs,
    super.configs,
    super.callbacks,
    super.mainImageSize,
    super.mainBodySize,
    super.layers,
    super.appliedFilters,
    super.appliedTuneAdjustments,
    super.appliedBlurFactor,
    super.convertToUint8List,
    required super.theme,
    required this.tool,
    this.appliedShaderFilters = const [],
  });

  /// 当前编辑的工具类型。
  final ShaderTool tool;

  /// 主编辑器已应用的 shader 效果（用于初始化当前参数）。
  final List<ShaderFilterState> appliedShaderFilters;
}
