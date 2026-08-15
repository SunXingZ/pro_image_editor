import 'package:flutter/material.dart';

/// 高光阴影色调工具面板。
///
/// 阴影 / 高光强度（0-100）+ 各自色调色板。
/// 参数结构：
/// `{'shadowTint': 0..100, 'highlightTint': 0..100,
///   'shadowTintColor': int(ARGB), 'highlightTintColor': int(ARGB)}`。
class HighlightShadowTintToolView extends StatefulWidget {
  /// Creates a [HighlightShadowTintToolView].
  const HighlightShadowTintToolView({
    super.key,
    required this.params,
    required this.onChanged,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

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

  int _colorValue(String key, Color fallback) =>
      (widget.params[key] as int?) ?? fallback.toARGB32();

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(
          'Shadow',
          'shadowTint',
          'shadowTintColor',
          HighlightShadowTintToolView._shadowSwatch,
          _colorValue(
            'shadowTintColor',
            HighlightShadowTintToolView._shadowSwatch.first,
          ),
          color,
          _shadowIntensity,
          (v) => setState(() => _shadowIntensity = v),
        ),
        _buildRow(
          'Highlight',
          'highlightTint',
          'highlightTintColor',
          HighlightShadowTintToolView._highlightSwatch,
          _colorValue(
            'highlightTintColor',
            HighlightShadowTintToolView._highlightSwatch.first,
          ),
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
    int currentColor,
    Color textColor,
    double intensity,
    ValueChanged<double> onIntensity,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  label,
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
              ),
              Expanded(
                child: Slider(
                  value: intensity.clamp(0, 100),
                  min: 0,
                  max: 100,
                  divisions: 200,
                  onChanged: (v) {
                    onIntensity(v);
                    widget.onChanged({...widget.params, intensityKey: v});
                  },
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  intensity.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final c in swatch)
                GestureDetector(
                  onTap: () => widget
                      .onChanged({...widget.params, colorKey: c.toARGB32()}),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.toARGB32() == currentColor
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
