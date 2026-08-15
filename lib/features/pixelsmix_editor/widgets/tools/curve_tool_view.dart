import 'package:flutter/material.dart';
import 'package:pixelsmix_filters/pixelsmix_filters.dart';

import 'restorable_curve_panel.dart';

/// 色调曲线工具面板。
///
/// 拆分为两块，共享同一个 [CurveEditorController]：
/// - [CurveToolView.buildCanvas]：悬浮在预览图上层的曲线画布；
/// - [CurveToolView.buildControls]：底部栏中的通道切换 / 重置 / 网格操作区。
///
/// 画布从已应用参数恢复初始控制点，并将四通道曲线点转换为
/// `{'curve': {...}}` 参数结构。
class CurveToolView extends StatelessWidget {
  /// Creates a [CurveToolView].
  const CurveToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.controller,
    this.curveHeight,
  });

  /// 当前曲线参数（用于恢复初始控制点）。
  final Map<String, dynamic> params;

  /// 曲线变化回调（携带最新参数）。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 与画布 / 操作区共享的控制器。
  final CurveEditorController controller;

  /// 曲线区域高度；为空时使用默认值。
  final double? curveHeight;

  RGBACurvePoints _initialFromParams() {
    final curve = params['curve'] as Map<String, dynamic>? ?? const {};
    if (curve.isEmpty) return RGBACurvePoints();
    return RGBACurvePoints(
      channels: {
        for (final c in CurveChannel.values)
          c: _pointSet(curve[c.name] as List? ?? const <dynamic>[]),
      },
    );
  }

  static CurvePointSet _pointSet(List<dynamic> points) {
    final xs = <double>[];
    final ys = <double>[];
    for (final p in points) {
      final list = p as List;
      if (list.length >= 2) {
        xs.add((list[0] as num).toDouble());
        ys.add((list[1] as num).toDouble());
      }
    }
    return CurvePointSet(xs, ys);
  }

  void _handleChange(RGBACurvePoints points) {
    final curve = <String, dynamic>{};
    for (final c in CurveChannel.values) {
      final set = points.channels[c]!;
      curve[c.name] = [
        for (var i = 0; i < set.xs.length; i++) [set.xs[i], set.ys[i]],
      ];
    }
    onChanged({'curve': curve});
  }

  /// 悬浮的曲线画布（放在预览图上层）。
  Widget buildCanvas() {
    return RestorableCurveCanvas(
      controller: controller,
      initial: _initialFromParams(),
      curveHeight: curveHeight ?? 220,
      onChanged: _handleChange,
    );
  }

  /// 底部操作区（通道切换 / 重置 / 网格）。
  Widget buildControls() => CurveToolControls(controller: controller);

  @override
  Widget build(BuildContext context) => buildControls();
}
