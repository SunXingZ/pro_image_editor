import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';
import '/shared/widgets/color_selector.dart';
import '/shared/widgets/edit_slider.dart';

/// 高光阴影色调工具面板。
///
/// 阴影 / 高光强度（0-100）+ 各自色调色板（RN ImageColorBalance 的
/// `ColorSelector` 色块行）。
/// 参数结构：
/// `{'shadowTint': 0..100, 'highlightTint': 0..100,
///   'shadowTintColor': int(ARGB), 'highlightTintColor': int(ARGB)}`。
class HighlightShadowTintToolView extends StatefulWidget {
  /// Creates a [HighlightShadowTintToolView].
  const HighlightShadowTintToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.i18n,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 本地化文案（阴影 / 高光行标签）。
  final I18nPixelsmixEditor i18n;

  static const List<Color> _shadowSwatch = [
    Color(0xFFFF0000),
    Color(0xFFFF7F00),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFF8B00FF),
  ];

  static const List<Color> _highlightSwatch = [
    Color(0xFFf3b4b2),
    Color(0xFFe3dfcd),
    Color(0xFFece194),
    Color(0xFFb2e6c9),
    Color(0xFF95c5de),
    Color(0xFFb399d8),
  ];

  @override
  State<HighlightShadowTintToolView> createState() =>
      _HighlightShadowTintToolViewState();
}

class _HighlightShadowTintToolViewState
    extends State<HighlightShadowTintToolView> {
  late double _shadowIntensity;
  late double _highlightIntensity;

  @override
  void initState() {
    super.initState();
    _shadowIntensity = (widget.params['shadowTint'] as num?)?.toDouble() ?? 0;
    _highlightIntensity =
        (widget.params['highlightTint'] as num?)?.toDouble() ?? 0;
  }

  @override
  void didUpdateWidget(covariant HighlightShadowTintToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shadow = widget.params['shadowTint'];
    if (shadow is num) _shadowIntensity = shadow.toDouble();
    final highlight = widget.params['highlightTint'];
    if (highlight is num) _highlightIntensity = highlight.toDouble();
  }

  Color _colorValue(String key, List<Color> swatch) =>
      Color((widget.params[key] as int?) ?? swatch.first.toARGB32());

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    final shadowColor = _colorValue(
      'shadowTintColor',
      HighlightShadowTintToolView._shadowSwatch,
    );
    final highlightColor = _colorValue(
      'highlightTintColor',
      HighlightShadowTintToolView._highlightSwatch,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(
          widget.i18n.shadow,
          'shadowTint',
          'shadowTintColor',
          HighlightShadowTintToolView._shadowSwatch,
          shadowColor,
          color,
          _shadowIntensity,
          (v) => setState(() => _shadowIntensity = v),
        ),
        _buildRow(
          widget.i18n.highlight,
          'highlightTint',
          'highlightTintColor',
          HighlightShadowTintToolView._highlightSwatch,
          highlightColor,
          color,
          _highlightIntensity,
          (v) => setState(() => _highlightIntensity = v),
        ),
      ],
    );
  }

  Widget _buildRow(
    String label,
    String intensityKey,
    String colorKey,
    List<Color> swatch,
    Color currentColor,
    Color textColor,
    double intensity,
    ValueChanged<double> onIntensity,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditSlider(
          label: label,
          value: intensity.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 200,
          textColor: textColor,
          onChanged: (v) {
            onIntensity(v);
            widget.onChanged({...widget.params, intensityKey: v});
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ColorSelector(
            colors: swatch,
            selected: currentColor,
            showCustom: false,
            onSelect: (c) =>
                widget.onChanged({...widget.params, colorKey: c.toARGB32()}),
          ),
        ),
      ],
    );
  }
}
