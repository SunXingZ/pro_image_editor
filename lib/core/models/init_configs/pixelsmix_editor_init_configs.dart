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
    this.tools = const [],
    this.expandTuneParams = false,
    this.appliedShaderFilters = const [],
  });

  /// 当前编辑的工具类型。
  final ShaderTool tool;

  /// 工具组（分组编辑时传入的有序工具列表，底部渲染横向 tab）。
  ///
  /// 为空时回退为单工具（仅 [tool]），保持原有行为。
  final List<ShaderTool> tools;

  /// 是否把基础调节（tune）展开为参数级 tab（亮度/对比度/…/褪色各一项），
  /// 与组内其余工具平铺在底部 tab 栏（对齐 MIX/醒图的「调节」页交互）。
  ///
  /// 仅配合 [tools] 多工具模式使用；false 时 tune 作为单个工具 tab。
  final bool expandTuneParams;

  /// 主编辑器已应用的 shader 效果（用于初始化当前参数）。
  final List<ShaderFilterState> appliedShaderFilters;
}
