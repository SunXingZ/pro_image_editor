// Project imports:
import 'package:flutter/widgets.dart';

import '/features/pixelsmix_editor/models/shader_filter_state.dart';
import 'standalone_editor_callbacks.dart';

/// A class representing callbacks for the Pixelsmix editor.
class PixelsmixEditorCallbacks extends StandaloneEditorCallbacks {
  /// Creates a new instance of [PixelsmixEditorCallbacks].
  const PixelsmixEditorCallbacks({
    this.onShaderFilterChange,
    super.onInit,
    super.onAfterViewInit,
    super.onUpdateUI,
    super.onDone,
    super.onRedo,
    super.onUndo,
    super.onCloseEditor,
    super.onKeyboardEvent,
  });

  /// A callback triggered when the shader filter parameter changes.
  final ValueChanged<ShaderFilterState>? onShaderFilterChange;

  /// Handles the shader filter change event.
  void handleShaderFilterChange(ShaderFilterState state) {
    onShaderFilterChange?.call(state);
    handleUpdateUI();
  }

  /// Creates a copy with modified editor callbacks.
  PixelsmixEditorCallbacks copyWith({
    ValueChanged<ShaderFilterState>? onShaderFilterChange,
    Function()? onInit,
    Function()? onAfterViewInit,
    Function()? onUpdateUI,
    Function()? onDone,
    Function()? onRedo,
    Function()? onUndo,
    Function()? onCloseEditor,
    bool Function(KeyEvent event)? onKeyboardEvent,
  }) {
    return PixelsmixEditorCallbacks(
      onShaderFilterChange:
          onShaderFilterChange ?? this.onShaderFilterChange,
      onKeyboardEvent: onKeyboardEvent ?? this.onKeyboardEvent,
      onInit: onInit ?? this.onInit,
      onAfterViewInit: onAfterViewInit ?? this.onAfterViewInit,
      onUpdateUI: onUpdateUI ?? this.onUpdateUI,
      onDone: onDone ?? this.onDone,
      onRedo: onRedo ?? this.onRedo,
      onUndo: onUndo ?? this.onUndo,
      onCloseEditor: onCloseEditor ?? this.onCloseEditor,
    );
  }
}
