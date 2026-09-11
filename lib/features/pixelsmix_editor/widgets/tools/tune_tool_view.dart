import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_tune_editor.dart';
import '/shared/widgets/edit_slider.dart';

/// 基础调节工具面板。
///
/// 与 MIX/醒图一致：上方一次只显示当前参数的一个滑块，下方为横向参数条，
/// 点参数名切换滑块（非零值参数优先选中），值写入 `{'<id>': value}` 参数
/// 结构，由 [ShaderRenderer.tuneMatrix] 合成 4×5 颜色矩阵渲染。
///
/// 在「调节」页参数级平铺模式（[hideParamBar]）下，参数条隐藏，当前参数由
/// 外部通过 [initialParamId] 指定（底部 tab 栏承担参数选择）。
class TuneToolView extends StatefulWidget {
  /// Creates a [TuneToolView].
  const TuneToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.i18n,
    this.textColor,
    this.activeColor,
    this.initialParamId,
    this.hideParamBar = false,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 参数名称本地化文案。
  final I18nTuneEditor i18n;

  /// 文字颜色；为空时使用默认白 70% 透明度。
  final Color? textColor;

  /// 选中参数高亮颜色；为空时使用白色。
  final Color? activeColor;

  /// 外部指定的当前参数；变化时滑块跟随切换。
  final String? initialParamId;

  /// 是否隐藏内置参数条（由外部 tab 栏承担参数选择）。
  final bool hideParamBar;

  @override
  State<TuneToolView> createState() => _TuneToolViewState();
}

/// 单个可调参数配置（与 [TuneAdjustmentItem] 一致）。
class _TuneParam {
  const _TuneParam({
    required this.id,
    required this.label,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelMultiplier,
  });

  /// 参数键名（与 [TuneAdjustmentItem.id] 一致，值直接进 params）。
  final String id;

  /// 显示名称。
  final String label;

  /// 滑杆范围。
  final double min;
  final double max;

  /// 滑杆分档数。
  final int divisions;

  /// 显示值倍率。
  final double labelMultiplier;
}

class _TuneToolViewState extends State<TuneToolView> {
  late final List<_TuneParam> _params = _buildParams();
  late final Map<String, double> _values = {
    for (final p in _params) p.id: _valueOf(p.id),
  };

  /// 当前选中的参数；为空时自动选第一个非零值参数。
  String? _selectedId;

  List<_TuneParam> _buildParams() => [
        _TuneParam(
          id: 'brightness',
          label: widget.i18n.brightness,
          min: -0.5,
          max: 0.5,
          divisions: 200,
          labelMultiplier: 200,
        ),
        _TuneParam(
          id: 'contrast',
          label: widget.i18n.contrast,
          min: -0.5,
          max: 0.5,
          divisions: 200,
          labelMultiplier: 200,
        ),
        _TuneParam(
          id: 'saturation',
          label: widget.i18n.saturation,
          min: -0.5,
          max: 0.5,
          divisions: 200,
          labelMultiplier: 200,
        ),
        _TuneParam(
          id: 'exposure',
          label: widget.i18n.exposure,
          min: -1,
          max: 1,
          divisions: 200,
          labelMultiplier: 200,
        ),
        _TuneParam(
          id: 'hue',
          label: widget.i18n.hue,
          min: -0.25,
          max: 0.25,
          divisions: 400,
          labelMultiplier: 400,
        ),
        _TuneParam(
          id: 'temperature',
          label: widget.i18n.temperature,
          min: -0.5,
          max: 0.5,
          divisions: 200,
          labelMultiplier: 200,
        ),
        _TuneParam(
          id: 'tint',
          label: widget.i18n.tint,
          min: -0.5,
          max: 0.5,
          divisions: 200,
          labelMultiplier: 200,
        ),
        _TuneParam(
          id: 'fade',
          label: widget.i18n.fade,
          min: -1,
          max: 1,
          divisions: 200,
          labelMultiplier: 200,
        ),
      ];

  double _valueOf(String id) =>
      (widget.params[id] as num?)?.toDouble() ?? 0;

  @override
  void didUpdateWidget(covariant TuneToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同步外部参数变化（如重新编辑已有参数），本地值跟随。
    for (final p in _params) {
      final v = widget.params[p.id];
      if (v is num) _values[p.id] = v.toDouble();
    }
    // 外部指定的当前参数变化时，滑块跟随切换。
    if (widget.initialParamId != oldWidget.initialParamId) {
      _selectedId = widget.initialParamId;
    }
  }

  void _update(_TuneParam param, double value) {
    setState(() => _values[param.id] = value);
    widget.onChanged({...widget.params, param.id: value});
  }

  _TuneParam get _selected {
    final id = _selectedId;
    if (id != null) {
      for (final p in _params) {
        if (p.id == id) return p;
      }
    }
    // 优先选第一个非零值参数，方便继续微调。
    for (final p in _params) {
      if ((_values[p.id] ?? 0) != 0) return p;
    }
    return _params.first;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.textColor ?? Colors.white70;
    final p = _selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditSlider(
          label: p.label,
          value: _values[p.id] ?? 0,
          min: p.min,
          max: p.max,
          divisions: p.divisions,
          valueText: ((_values[p.id] ?? 0) * p.labelMultiplier)
              .round()
              .toString(),
          textColor: color,
          onChanged: (v) => _update(p, v),
        ),
        // 参数级平铺模式：参数条由外部 tab 栏承担，这里不再渲染。
        if (!widget.hideParamBar)
          SizedBox(
            height: 34,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in _params)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selectedId = e.id),
                        child: Center(
                          child: Text(
                            e.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: e.id == p.id
                                  ? (widget.activeColor ?? Colors.white)
                                  : color,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
