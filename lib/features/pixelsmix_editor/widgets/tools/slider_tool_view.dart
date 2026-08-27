import 'package:flutter/material.dart';

import '/shared/widgets/edit_slider.dart';

/// 单个滑杆配置。
class SliderToolItem {
  /// Creates a [SliderToolItem].
  const SliderToolItem({
    required this.key,
    required this.label,
    this.min = 0,
    this.max = 100,
    this.initial = 0,
    this.divisions = 200,
    this.trackColors,
    this.snapToMiddle = false,
  });

  /// 参数在 [Map] 中的键名。
  final String key;

  /// 显示名称。
  final String label;

  /// 最小值。
  final double min;

  /// 最大值。
  final double max;

  /// 默认值。
  final double initial;

  /// 滑杆分档数。
  final int divisions;

  /// 轨道渐变颜色（对应 RN 滑杆的 `trackTintColors`，如鲜艳度 / 高光阴影）。
  final List<Color>? trackColors;

  /// 是否吸附中点（对应 RN 滑杆的 `autoAttach`，以 50 为中点的滑杆开启）。
  final bool snapToMiddle;
}

/// 通用数值滑杆工具面板。
///
/// 滑杆值由本地状态驱动（拖拽始终流畅），并实时提交到参数。
class SliderToolView extends StatefulWidget {
  /// Creates a [SliderToolView].
  const SliderToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.items,
    this.textColor,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 滑杆列表。
  final List<SliderToolItem> items;

  /// 文字颜色；为空时使用默认白 70% 透明度。
  final Color? textColor;

  @override
  State<SliderToolView> createState() => _SliderToolViewState();
}

class _SliderToolViewState extends State<SliderToolView> {
  late final Map<String, double> _values = {
    for (final item in widget.items)
      item.key: widget.params[item.key] is num
          ? (widget.params[item.key] as num).toDouble()
          : item.initial,
  };

  @override
  void didUpdateWidget(covariant SliderToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同步外部参数变化（如重新编辑已有参数），本地值跟随。
    for (final item in widget.items) {
      final v = widget.params[item.key];
      if (v is num) _values[item.key] = v.toDouble();
    }
  }

  void _update(SliderToolItem item, double value) {
    setState(() => _values[item.key] = value);
    widget.onChanged({...widget.params, item.key: value});
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.textColor ?? Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in widget.items) _buildRow(item, color),
      ],
    );
  }

  Widget _buildRow(SliderToolItem item, Color color) {
    return EditSlider(
      label: item.label,
      value: _values[item.key] ?? item.initial,
      min: item.min,
      max: item.max,
      divisions: item.divisions,
      trackColors: item.trackColors,
      snapToMiddle: item.snapToMiddle,
      textColor: color,
      onChanged: (v) => _update(item, v),
    );
  }
}
