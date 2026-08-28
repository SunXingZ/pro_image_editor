/// 内置 LUT 滤镜目录模型（宿主应用注入给滤镜工具）。
///
/// 宿主负责：
/// - 提供 [LutFilterCategory.name]（已按当前语言本地化的分类名，满足 i18n）；
/// - 提供每条预设的 [LutFilterPreset.asset]（PNG asset 路径，须在 pubspec 声明）。
///
/// 滤镜名（如「森系文艺胶片」）按项目国际化规范视为品牌风格名，不翻译。
library;

/// 一条内置 LUT 滤镜预设。
class LutFilterPreset {
  /// Creates a [LutFilterPreset].
  const LutFilterPreset({
    required this.id,
    required this.name,
    required this.asset,
    required this.size,
  });

  /// 稳定标识（写入编辑器历史参数 `preset`）。
  final String id;

  /// 展示名（品牌风格名，不译）。
  final String name;

  /// 3D LUT PNG 的 asset 路径（宽 = size*size、高 = size 的横条）。
  final String asset;

  /// 3D LUT 尺寸（决定采样网格与纹理布局）。
  final int size;
}

/// 一个内置 LUT 滤镜分类。
class LutFilterCategory {
  /// Creates a [LutFilterCategory].
  const LutFilterCategory({
    required this.key,
    required this.name,
    required this.filters,
  });

  /// 稳定分类 key（仅作 UI 选中态，不用于展示）。
  final String key;

  /// 分类显示名（宿主已按当前语言本地化）。
  final String name;

  /// 该分类下的滤镜列表。
  final List<LutFilterPreset> filters;
}
