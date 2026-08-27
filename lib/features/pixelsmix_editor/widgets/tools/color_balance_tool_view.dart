import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';
import '/shared/widgets/edit_slider.dart';

/// 色彩平衡工具面板。
///
/// 顶部提供公共的 RGB 通道切换，下方显示所选通道对应的
/// 阴影 / 中间调 / 高光三个滑杆。
/// 参数结构：
/// `{'shadows': [r,g,b], 'midtones': [r,g,b], 'highlights': [r,g,b],
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

  /// 本地化文案（波段标签）。
  final I18nPixelsmixEditor i18n;

  @override
  State<ColorBalanceToolView> createState() => _ColorBalanceToolViewState();
}

class _ColorBalanceToolViewState extends State<ColorBalanceToolView> {
  static const List<String> _bands = ['shadows', 'midtones', 'highlights'];
  static const List<String> _channels = ['R', 'G', 'B'];

  /// 波段显示名（阴影 / 中间调 / 高光）。
  List<String> get _bandLabels => [
        widget.i18n.shadows,
        widget.i18n.midtones,
        widget.i18n.highlights,
      ];

  /// 9 个值（band*3 + channel），本地驱动保证拖拽流畅。
  late List<double> _local = _fromParams();
  int _channel = 0;

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

  void _set(int band, double value) {
    final idx = band * 3 + _channel;
    setState(() => _local[idx] = value);
    widget.onChanged({
      ...widget.params,
      _bands[band]: [
        _local[band * 3],
        _local[band * 3 + 1],
        _local[band * 3 + 2],
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
        _buildChannelSelector(color),
        for (var band = 0; band < _bands.length; band++)
          _buildBandRow(band, color),
      ],
    );
  }

  Widget _buildChannelSelector(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var c = 0; c < _channels.length; c++)
            GestureDetector(
              onTap: () => setState(() => _channel = c),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _channel == c
                        ? const Color(0xFFFFD700)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  _channels[c],
                  style: TextStyle(
                    color: _channel == c ? const Color(0xFFFFD700) : color,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBandRow(int band, Color color) {
    final value = _local[band * 3 + _channel];
    return EditSlider(
      label: _bandLabels[band],
      value: value.clamp(-1.0, 1.0),
      min: -1,
      max: 1,
      divisions: 200,
      valueText: value.toStringAsFixed(2),
      textColor: color,
      onChanged: (v) => _set(band, v),
    );
  }
}
