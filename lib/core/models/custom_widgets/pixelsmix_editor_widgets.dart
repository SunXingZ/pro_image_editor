// Project imports:
import '/features/pixelsmix_editor/pixelsmix_editor.dart';
import '/shared/widgets/reactive_widgets/reactive_custom_appbar.dart';
import '/shared/widgets/reactive_widgets/reactive_custom_widget.dart';
import 'utils/custom_widgets_standalone_editor.dart';
import 'utils/custom_widgets_typedef.dart';

/// Custom widget hooks for the Pixelsmix editor.
class PixelsmixEditorWidgets
    extends CustomWidgetsStandaloneEditor<PixelsmixEditorState> {
  /// Creates a [PixelsmixEditorWidgets].
  const PixelsmixEditorWidgets({
    super.appBar,
    super.bottomBar,
    super.bodyItems,
    super.bodyItemsRecorded,
  });

  /// Creates a copy with modified fields.
  @override
  PixelsmixEditorWidgets copyWith({
    ReactiveAppbar? Function(
      PixelsmixEditorState editorState,
      Stream<void> rebuildStream,
    )?
    appBar,
    ReactiveWidget? Function(
      PixelsmixEditorState editorState,
      Stream<void> rebuildStream,
    )?
    bottomBar,
    CustomBodyItems<PixelsmixEditorState>? bodyItems,
    CustomBodyItems<PixelsmixEditorState>? bodyItemsRecorded,
  }) {
    return PixelsmixEditorWidgets(
      appBar: appBar ?? this.appBar,
      bottomBar: bottomBar ?? this.bottomBar,
      bodyItems: bodyItems ?? this.bodyItems,
      bodyItemsRecorded: bodyItemsRecorded ?? this.bodyItemsRecorded,
    );
  }
}
