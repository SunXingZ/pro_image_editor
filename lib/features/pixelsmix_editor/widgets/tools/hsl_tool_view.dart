import 'package:flutter/material.dart';

import '/shared/widgets/color_selector.dart';
import '/shared/widgets/edit_slider.dart';
import 'hsl_band_colors.dart';

/// HSL 混色工具面板。
///
/// 8 色相各配 H/S/L 三个滑杆（-100~100），轨道渐变与 RN `ImageHsl`
/// 的 `hslSliderColors` 一致：
/// - Hue：前一个色相 → 当前色相；
/// - Saturation：同色相去饱和（灰）→ 全饱和；
/// - Brightness：黑色 → 50% 明度。
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

  /// Hue 轨道：前一个色相 → 当前色相（与 RN hslSliderColors.hue 一致）。
  List<Color> _hueTrack() {
    final prev = (_selected - 1 + _names.length) % _names.length;
    return [kHslBandColors[prev], kHslBandColors[_selected]];
  }

  /// Saturation 轨道：同色相去饱和 → 全饱和。
  List<Color> _satTrack() {
    final hsl = HSLColor.fromColor(kHslBandColors[_selected]);
    return [hsl.withSaturation(0).toColor(), hsl.withSaturation(1).toColor()];
  }

  /// Brightness 轨道：黑色 → 50% 明度。
  List<Color> _brightnessTrack() {
    final hsl = HSLColor.fromColor(kHslBandColors[_selected]);
    return [hsl.withLightness(0).toColor(), hsl.withLightness(0.5).toColor()];
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 色相选择（RN ImageHsl 的 ColorSelector 色块行）
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ColorSelector(
            colors: kHslBandColors,
            selected: kHslBandColors[_selected],
            showCustom: false,
            onSelect: (c) =>
                setState(() => _selected = kHslBandColors.indexOf(c)),
          ),
        ),
        // H/S/L 滑杆（渐变轨道）
        for (var axis = 0; axis < 3; axis++)
          EditSlider(
            label: _labels[axis],
            value: _local[_names[_selected]]![axis].clamp(-100.0, 100.0),
            min: -100,
            max: 100,
            divisions: 200,
            trackColors: switch (axis) {
              0 => _hueTrack(),
              1 => _satTrack(),
              _ => _brightnessTrack(),
            },
            textColor: textColor,
            onChanged: (v) => _update(axis, v),
          ),
      ],
    );
  }
}
