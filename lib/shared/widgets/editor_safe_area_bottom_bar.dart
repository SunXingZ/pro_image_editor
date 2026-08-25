import 'package:flutter/material.dart';

/// Wraps an editor bottom bar so its background extends into the bottom
/// safe area (the home-indicator region) instead of leaving a transparent
/// strip below the bar.
///
/// Sub editors previously wrapped the whole `Scaffold` in a `SafeArea`, so the
/// bottom safe-area padding was placed *outside* the `Scaffold` and rendered
/// transparently (showing the page underneath). This widget moves that padding
/// *inside* the bar: the [color] fills the whole bottom region while [child]
/// keeps a reduced safe-area inset ([bottomInsetScale]), so bar and bottom
/// edge merge into one without the bottom area looking overly tall.
class EditorSafeAreaBottomBar extends StatelessWidget {
  /// Creates an `EditorSafeAreaBottomBar`.
  const EditorSafeAreaBottomBar({
    super.key,
    required this.color,
    required this.applyBottomSafeArea,
    this.child,
  });

  /// Scale factor applied to the bottom safe-area inset (home-indicator
  /// height), compressing it to 2/3 of the system value.
  static const double bottomInsetScale = 2 / 3;

  /// Background color of the bottom bar, painted across the whole bottom
  /// region including the safe area.
  final Color color;

  /// Whether to apply the bottom safe-area inset (home-indicator height) to
  /// the [child] content.
  final bool applyBottomSafeArea;

  /// The bottom bar content. When `null`, renders nothing (equivalent to
  /// having no bottom bar).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (child == null) return const SizedBox.shrink();
    final bottomInset = applyBottomSafeArea
        ? MediaQuery.paddingOf(context).bottom * bottomInsetScale
        : 0.0;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: child,
      ),
    );
  }
}

/// Scales the bottom safe-area inset for its child.
///
/// Some bars (e.g. `BottomAppBar`) ship their own `SafeArea` that reads
/// `MediaQuery.padding.bottom` directly. This wrapper scales that inset by
/// [EditorSafeAreaBottomBar.bottomInsetScale] so such bars keep the same
/// reduced bottom spacing as [EditorSafeAreaBottomBar].
class EditorScaledBottomSafeArea extends StatelessWidget {
  /// Creates an `EditorScaledBottomSafeArea`.
  const EditorScaledBottomSafeArea({super.key, required this.child});

  /// The widget whose bottom safe-area inset will be scaled.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final bottom =
        data.padding.bottom * EditorSafeAreaBottomBar.bottomInsetScale;
    return MediaQuery(
      data: data.copyWith(
        padding: data.padding.copyWith(bottom: bottom),
        viewPadding: data.viewPadding.copyWith(bottom: bottom),
      ),
      child: child,
    );
  }
}
