import '../custom_widgets/pixelsmix_editor_widgets.dart';
import '../icons/pixelsmix_editor_icons.dart';
import '../styles/pixelsmix_editor_style.dart';
import 'utils/base_sub_editor_configs.dart';
import 'utils/editor_safe_area.dart';

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

  /// Creates a copy of this [PixelsmixEditorConfigs] object.
  PixelsmixEditorConfigs copyWith({
    bool? enableGesturePop,
    bool? showLayers,
    EditorSafeArea? safeArea,
    PixelsmixEditorStyle? style,
    PixelsmixEditorIcons? icons,
    PixelsmixEditorWidgets? widgets,
  }) {
    return PixelsmixEditorConfigs(
      enableGesturePop: enableGesturePop ?? this.enableGesturePop,
      showLayers: showLayers ?? this.showLayers,
      safeArea: safeArea ?? this.safeArea,
      style: style ?? this.style,
      icons: icons ?? this.icons,
      widgets: widgets ?? this.widgets,
    );
  }
}
