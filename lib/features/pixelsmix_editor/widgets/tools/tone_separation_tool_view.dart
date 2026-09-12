import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';
import '/shared/widgets/color_selector.dart';
import '/shared/widgets/edit_slider.dart';

/// 色调分离工具面板（MIX 分离色调）。
///
/// 顶部提供公共的波段切换（阴影 / 中间调 / 高光），其下为预设颜色行
/// （阴影 / 中间调用饱和色板、高光用粉彩色板，对齐 MIX 预设），下方为
/// 所选波段对应的色相（0~360°）+ 饱和度（0~100）两条滑杆。
/// 参数结构：
/// `{'shadows': [hue, sat], 'midtones': [hue, sat], 'highlights': [hue, sat]}`。
class ToneSeparationToolView extends StatefulWidget {
  /// Creates a [ToneSeparationToolView].
  const ToneSeparationToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.i18n,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 本地化文案（波段与通道标签）。
  final I18nPixelsmixEditor i18n;

  /// 饱和色板（阴影 / 中间调预设，对齐 MIX 色调分离的常用色）。
  static const List<Color> _vividSwatch = [
    Color(0xFFFF0000),
    Color(0xFFFF7F00),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFF8B00FF),
  ];

  /// 粉彩色板（高光预设）。
  static const List<Color> _pastelSwatch = [
    Color(0xFFF3B4B2),
    Color(0xFFE3DFCD),
    Color(0xFFECE194),
    Color(0xFFB2E6C9),
    Color(0xFF95C5DE),
    Color(0xFFB399D8),
  ];

  @override
  State<ToneSeparationToolView> createState() => _ToneSeparationToolViewState();
}

class _ToneSeparationToolViewState extends State<ToneSeparationToolView> {
  static const List<String> _bands = ['shadows', 'midtones', 'highlights'];

  /// 彩虹渐变轨道（首尾红色形成色相环闭环）。
  static const List<Color> _hueTrackColors = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  /// 波段显示名（阴影 / 中间调 / 高光）。
  List<String> get _bandLabels => [
        widget.i18n.shadows,
        widget.i18n.midtones,
        widget.i18n.highlights,
      ];

  /// 本地值（band*2 + 通道），驱动拖拽流畅。
  late List<double> _local = _fromParams();
  int _band = 0;

  List<double> _fromParams() {
    final result = <double>[];
    for (final band in _bands) {
      final v = widget.params[band];
      result
        ..add(v is List && v.isNotEmpty ? (v[0] as num).toDouble() : 0)
        ..add(v is List && v.length > 1 ? (v[1] as num).toDouble() : 0);
    }
    return result;
  }

  @override
  void didUpdateWidget(covariant ToneSeparationToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _local = _fromParams();
    }
  }

  void _set(int axis, double value) {
    final idx = _band * 2 + axis;
    setState(() => _local[idx] = value);
    widget.onChanged({
      ...widget.params,
      _bands[_band]: [_local[_band * 2], _local[_band * 2 + 1]],
    });
  }

  /// 当前色相的纯色（用于饱和度轨道的终点）。
  Color get _hueColor => HSLColor.fromAHSL(
        1,
        (_local[_band * 2] % 360).clamp(0.0, 359.9),
        1,
        0.5,
      ).toColor();

  /// 当前波段对应的预设色板：阴影 / 中间调用饱和色，高光用粉彩色。
  List<Color> get _activeSwatch =>
      _band == 2
          ? ToneSeparationToolView._pastelSwatch
          : ToneSeparationToolView._vividSwatch;

  /// 当前色相命中的预设色块（用于选中描边；未命中或饱和度近 0 返回 null，
  /// 保证重置后不残留描边）。
  Color? get _selectedSwatchColor {
    if (_local[_band * 2 + 1] < 10) return null;
    final hue = _local[_band * 2];
    for (final c in _activeSwatch) {
      if ((HSLColor.fromColor(c).hue - hue).abs() < 1.5) return c;
    }
    return null;
  }

  /// 点击预设色块：设置当前波段色相；饱和度近 0 时给一个可感知的
  /// 默认强度，避免「点了没反应」。
  void _onSwatchSelected(Color color) {
    final hue = HSLColor.fromColor(color).hue;
    if (_local[_band * 2 + 1] < 10) {
      _set(1, 50);
    }
    _set(0, hue);
  }

  /// 重置当前波段的色调（色相 / 饱和度归零，该波段恢复无染色）。
  void _resetBand() {
    _set(0, 0);
    _set(1, 0);
  }

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBandSelector(color),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 重置当前波段（对齐 MIX：色板行左侧的重置入口）。
              GestureDetector(
                onTap: _resetBand,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 1),
                  ),
                  child: Icon(
                    Icons.restart_alt,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              ColorSelector(
                colors: _activeSwatch,
                selected: _selectedSwatchColor,
                showCustom: false,
                onSelect: _onSwatchSelected,
              ),
            ],
          ),
        ),
        EditSlider(
          label: widget.i18n.hue,
          value: _local[_band * 2],
          min: 0,
          max: 360,
          divisions: 360,
          trackColors: _hueTrackColors,
          textColor: color,
          onChanged: (v) => _set(0, v),
        ),
        EditSlider(
          label: widget.i18n.saturation,
          value: _local[_band * 2 + 1],
          min: 0,
          max: 100,
          divisions: 200,
          trackColors: [
            HSLColor.fromAHSL(1, _local[_band * 2], 0, 0.5).toColor(),
            _hueColor,
          ],
          textColor: color,
          onChanged: (v) => _set(1, v),
        ),
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
}
