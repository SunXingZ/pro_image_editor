// Flutter imports:
import 'package:flutter/services.dart';

import '../../constants/editor_style_constants.dart';

/// A style class for the Pixelsmix editor.
class PixelsmixEditorStyle {
  /// Creates an instance of [PixelsmixEditorStyle].
  const PixelsmixEditorStyle({
    this.appBarBackground = kImageEditorAppBarBackground,
    this.appBarColor = kImageEditorAppBarColor,
    this.bottomBarBackground = kImageEditorBottomBarBackground,
    this.bottomBarActiveItemColor = kImageEditorPrimaryColor,
    this.bottomBarInactiveItemColor = kImageEditorBottomBarColor,
    this.background = kImageEditorBackground,
    this.uiOverlayStyle = kImageEditorUiOverlayStyle,
  });

  /// Background color of the app bar.
  final Color appBarBackground;

  /// Foreground color (text and icons) of the app bar.
  final Color appBarColor;

  /// Background color of the editor.
  final Color background;

  /// Background color of the bottom navigation bar.
  final Color bottomBarBackground;

  /// Color of active items in the bottom navigation bar.
  final Color bottomBarActiveItemColor;

  /// Color of inactive items in the bottom navigation bar.
  final Color bottomBarInactiveItemColor;

  /// UI overlay style, defining the appearance of system status bars.
  final SystemUiOverlayStyle uiOverlayStyle;

  /// Creates a copy with modified fields.
  PixelsmixEditorStyle copyWith({
    Color? appBarBackground,
    Color? appBarColor,
    Color? background,
    Color? bottomBarBackground,
    Color? bottomBarActiveItemColor,
    Color? bottomBarInactiveItemColor,
    SystemUiOverlayStyle? uiOverlayStyle,
  }) {
    return PixelsmixEditorStyle(
      appBarBackground: appBarBackground ?? this.appBarBackground,
      appBarColor: appBarColor ?? this.appBarColor,
      background: background ?? this.background,
      bottomBarBackground: bottomBarBackground ?? this.bottomBarBackground,
      bottomBarActiveItemColor:
          bottomBarActiveItemColor ?? this.bottomBarActiveItemColor,
      bottomBarInactiveItemColor:
          bottomBarInactiveItemColor ?? this.bottomBarInactiveItemColor,
      uiOverlayStyle: uiOverlayStyle ?? this.uiOverlayStyle,
    );
  }
}
