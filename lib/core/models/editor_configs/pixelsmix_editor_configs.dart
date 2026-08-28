import '/features/pixelsmix_editor/models/lut_filter_catalog.dart';
import '/shared/utils/lut/lut_parser.dart';

import '../custom_widgets/pixelsmix_editor_widgets.dart';
import '../icons/pixelsmix_editor_icons.dart';
import '../styles/pixelsmix_editor_style.dart';
import 'utils/base_sub_editor_configs.dart';
import 'utils/editor_safe_area.dart';

export '/features/pixelsmix_editor/models/lut_filter_catalog.dart';
export '../custom_widgets/pixelsmix_editor_widgets.dart';
export '../icons/pixelsmix_editor_icons.dart';
export '../styles/pixelsmix_editor_style.dart';

/// A configuration class for the Pixelsmix editor.
class PixelsmixEditorConfigs implements BaseSubEditorConfigs {
  /// Creates a [PixelsmixEditorConfigs] instance.
  const PixelsmixEditorConfigs({
    this.enableGesturePop = true,
    this.showLayers = true,
    this.safeArea = const EditorSafeArea(),
    this.style = const PixelsmixEditorStyle(),
    this.icons = const PixelsmixEditorIcons(),
    this.widgets = const PixelsmixEditorWidgets(),
    this.lutFilePicker,
    this.filterCategories,
  });

  /// {@macro enableGesturePop}
  @override
  final bool enableGesturePop;

  /// Specifies whether the layers should be visible in the editor.
  final bool showLayers;

  /// Defines the safe area configuration for the editor.
  final EditorSafeArea safeArea;

  /// Style configuration for the editor.
  final PixelsmixEditorStyle style;

  /// Icons used in the editor.
  final PixelsmixEditorIcons icons;

  /// Widgets associated with the editor.
  final PixelsmixEditorWidgets widgets;

  /// LUT 文件选择回调：由宿主应用实现（通常用文件选择器挑选 .cube/.csp
  /// 并解析），返回解析后的 LUT 数据列表；为空时 LUT 工具不显示「选择文件」入口。
  final Future<List<LutData>> Function()? lutFilePicker;

  /// 内置 LUT 滤镜分类目录（宿主注入，分类名须已按当前语言本地化）；
  /// 为空时滤镜工具退化为仅「原图」入口。
  final List<LutFilterCategory>? filterCategories;

  /// Creates a copy of this [PixelsmixEditorConfigs] object.
  PixelsmixEditorConfigs copyWith({
    bool? enableGesturePop,
    bool? showLayers,
    EditorSafeArea? safeArea,
    PixelsmixEditorStyle? style,
    PixelsmixEditorIcons? icons,
    PixelsmixEditorWidgets? widgets,
    Future<List<LutData>> Function()? lutFilePicker,
    List<LutFilterCategory>? filterCategories,
  }) {
    return PixelsmixEditorConfigs(
      enableGesturePop: enableGesturePop ?? this.enableGesturePop,
      showLayers: showLayers ?? this.showLayers,
      safeArea: safeArea ?? this.safeArea,
      style: style ?? this.style,
      icons: icons ?? this.icons,
      widgets: widgets ?? this.widgets,
      lutFilePicker: lutFilePicker ?? this.lutFilePicker,
      filterCategories: filterCategories ?? this.filterCategories,
    );
  }
}
