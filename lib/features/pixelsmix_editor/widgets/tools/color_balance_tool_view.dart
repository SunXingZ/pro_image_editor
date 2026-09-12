import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';
import '/shared/widgets/edit_slider.dart';

/// 色彩平衡工具面板（MIX 色彩平衡）。
///
/// 顶部提供公共的波段切换（阴影 / 中间调 / 高光），下方显示所选波段对应的
/// 三条 CMY 成对色条：青↔红、品红↔绿、黄↔蓝（-100~100，正偏青/品红/黄，
/// 负偏红/绿/蓝）。
/// 参数结构：
/// `{'shadows': [c,m,y], 'midtones': [c,m,y], 'highlights': [c,m,y],
///   'preserveLuminosity': true}`。
class ColorBalanceToolView extends StatefulWidget {
  /// Creates a [ColorBalanceToolView].
  const ColorBalanceToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.i18n,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 本地化文案（波段与色条标签）。
  final I18nPixelsmixEditor i18n;

  @override
  State<ColorBalanceToolView> createState() => _ColorBalanceToolViewState();
}

class _ColorBalanceToolViewState extends State<ColorBalanceToolView> {
  static const List<String> _bands = ['shadows', 'midtones', 'highlights'];

  /// 色条两端色名：左端（负值）= 红/绿/蓝，右端（正值）= 青/品红/黄，
  /// 与渐变轨道方向一致。
  List<String> get _barLeftLabels =>
      [widget.i18n.red, widget.i18n.green, widget.i18n.blue];

  List<String> get _barRightLabels =>
      [widget.i18n.cyan, widget.i18n.magenta, widget.i18n.yellow];

  /// 波段显示名（阴影 / 中间调 / 高光）。
  List<String> get _bandLabels => [
        widget.i18n.shadows,
        widget.i18n.midtones,
        widget.i18n.highlights,
      ];

  /// 9 个值（band*3 + 色条），本地驱动保证拖拽流畅。
  late List<double> _local = _fromParams();
  int _band = 0;

  List<double> _fromParams() {
    final result = <double>[];
    for (final band in _bands) {
      final v = widget.params[band];
      for (var c = 0; c < 3; c++) {
        result.add(v is List && v.length > c ? (v[c] as num).toDouble() : 0);
      }
    }
    return result;
  }

  @override
  void didUpdateWidget(covariant ColorBalanceToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _local = _fromParams();
    }
  }

  void _set(int bar, double value) {
    final idx = _band * 3 + bar;
    setState(() => _local[idx] = value);
    widget.onChanged({
      ...widget.params,
      _bands[_band]: [
        _local[_band * 3],
        _local[_band * 3 + 1],
        _local[_band * 3 + 2],
      ],
      'preserveLuminosity': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBandSelector(color),
        for (var bar = 0; bar < 3; bar++) _buildBarRow(bar, color),
      ],
    );
  }

  Widget _buildBandSelector(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var b = 0; b < _bands.length; b++)
            GestureDetector(
              onTap: () => setState(() => _band = b),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _band == b
                        ? const Color(0xFFFFD700)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  _bandLabels[b],
                  style: TextStyle(
                    color: _band == b ? const Color(0xFFFFD700) : color,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarRow(int bar, Color color) {
    final value = _local[_band * 3 + bar];
    final track = _barTrack(bar);
    // MIX 式布局：两端色名 + 滑杆；数值右对齐显示在滑杆上方。
    // 底部对齐保证色名与滑杆行垂直居中；行距 12 避免拥挤。
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 36,
            height: 28,
            child: Text(
              _barLeftLabels[bar],
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          Expanded(
            child: EditSlider(
              value: value.clamp(-100.0, 100.0),
              min: -100,
              max: 100,
              divisions: 200,
              trackColors: track,
              valueText: value.toStringAsFixed(0),
              textColor: color,
              padding: EdgeInsets.zero,
              marginBottom: 0,
              onChanged: (v) => _set(bar, v),
            ),
          ),
          SizedBox(
            width: 36,
            height: 28,
            child: Text(
              _barRightLabels[bar],
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 色条轨道渐变：负端（红/绿/蓝）→ 正端（青/品红/黄）。
  List<Color> _barTrack(int bar) => switch (bar) {
        0 => [const Color(0xFFFF4D4F), const Color(0xFF36CFC9)],
        1 => [const Color(0xFF73D13D), const Color(0xFFB37FEB)],
        _ => [const Color(0xFF40A9FF), const Color(0xFFFFC53D)],
      };
}
