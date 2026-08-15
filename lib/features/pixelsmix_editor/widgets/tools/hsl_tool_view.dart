import 'package:flutter/material.dart';

/// HSL 混色工具面板。
///
/// 8 色相各配 H/S/L 三个滑杆（-100~100）。
/// 参数结构：`{'colors': {'red': [h,s,b], ...}}`。
class HslToolView extends StatefulWidget {
  /// Creates a [HslToolView].
  const HslToolView({
    super.key,
    required this.params,
    required this.onChanged,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<HslToolView> createState() => _HslToolViewState();
}

class _HslToolViewState extends State<HslToolView> {
  static const List<String> _names = [
    'red',
    'orange',
    'yellow',
    'green',
    'lightgreen',
    'blue',
    'purple',
    'fuchsia',
  ];

  static const List<Color> _swatch = [
    Color(0xFFFF0000),
    Color(0xFFFFA500),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF90EE90),
    Color(0xFF0000FF),
    Color(0xFF800080),
    Color(0xFFFF00FF),
  ];

  static const List<String> _labels = ['Hue', 'Saturation', 'Lightness'];

  int _selected = 0;

  /// 各色相的本地 H/S/L 值，驱动拖拽流畅。
  late Map<String, List<double>> _local = _fromParams();

  Map<String, List<double>> _fromParams() {
    final source = widget.params['colors'] as Map<String, dynamic>? ?? const {};
    final result = <String, List<double>>{};
    for (final name in _names) {
      final v = source[name];
      if (v is List && v.length >= 3) {
        result[name] = [v[0].toDouble(), v[1].toDouble(), v[2].toDouble()];
      } else {
        // 必须用可变列表，拖动时会原地修改。
        result[name] = [0.0, 0.0, 0.0];
      }
    }
    return result;
  }

  @override
  void didUpdateWidget(covariant HslToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _local = _fromParams();
    }
  }

  void _update(int axis, double value) {
    setState(() => _local[_names[_selected]]![axis] = value);
    widget.onChanged({'colors': {
      for (final entry in _local.entries) entry.key: List.of(entry.value),
    }});
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 色相选择
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _swatch.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _swatch[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selected == i
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
        // H/S/L 滑杆
        for (var axis = 0; axis < 3; axis++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    _labels[axis],
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: (_local[_names[_selected]]![axis])
                        .clamp(-100.0, 100.0),
                    min: -100,
                    max: 100,
                    divisions: 200,
                    onChanged: (v) => _update(axis, v),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    _local[_names[_selected]]![axis].toStringAsFixed(0),
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
      ],
    );
  }
}
