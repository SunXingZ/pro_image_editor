import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pixelsmix_filters/pixelsmix_filters.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';

/// 曲线编辑的共享控制器。
///
/// 悬浮的曲线画布（[RestorableCurveCanvas]）与底部操作区
/// （[CurveToolControls]）通过它共享通道、网格与重置状态。
class CurveEditorController extends ChangeNotifier {
  CurveChannel _channel = CurveChannel.rgb;
  bool _showGrid = true;
  bool _showCanvas = true;
  int _resetTick = 0;

  /// 当前通道。
  CurveChannel get channel => _channel;

  /// 是否显示网格。
  bool get showGrid => _showGrid;

  /// 是否显示曲线画布。
  bool get showCanvas => _showCanvas;

  /// 重置信号：每次自增，画布据此重置当前通道的控制点。
  int get resetTick => _resetTick;

  /// 切换当前通道。
  void changeChannel(CurveChannel channel) {
    if (_channel == channel) return;
    _channel = channel;
    notifyListeners();
  }

  /// 切换网格显隐。
  void toggleGrid() {
    _showGrid = !_showGrid;
    notifyListeners();
  }

  /// 切换曲线画布显隐。
  void toggleCanvas() {
    _showCanvas = !_showCanvas;
    notifyListeners();
  }

  /// 重置当前通道的控制点。
  void reset() {
    _resetTick++;
    notifyListeners();
  }
}

/// 可恢复初始控制点的曲线画布。
///
/// 仅包含曲线编辑区域（不包含通道操作区），可悬浮在预览图上层。
/// 通道切换 / 重置 / 网格开关通过 [CurveEditorController] 与底部操作区联动。
class RestorableCurveCanvas extends StatefulWidget {
  /// Creates a [RestorableCurveCanvas].
  const RestorableCurveCanvas({
    super.key,
    required this.initial,
    required this.controller,
    required this.onChanged,
    this.curveHeight = 220,
  });

  /// 初始四通道曲线点。
  final RGBACurvePoints initial;

  /// 与底部操作区共享的控制器。
  final CurveEditorController controller;

  /// 曲线变化回调。
  final ValueChanged<RGBACurvePoints> onChanged;

  /// 曲线区域高度。
  final double curveHeight;

  @override
  State<RestorableCurveCanvas> createState() => _RestorableCurveCanvasState();
}

class _RestorableCurveCanvasState extends State<RestorableCurveCanvas> {
  static const double _pointSize = 10;
  static const double _hitSlop = 26;
  static const double _touchSlop = 18;

  late RGBACurvePoints _points = widget.initial.copy();
  late CurveChannel _channel = widget.controller.channel;
  late bool _gridVisible = widget.controller.showGrid;
  late int _lastResetTick = widget.controller.resetTick;

  CurvePointSet get _activePoints => _points.channels[_channel]!;

  /// 强制画师重绘的信号：每次数据变化自增。
  /// 画师通过 `repaint:` 监听它 —— 即使不触发 rebuild 也能保证画面刷新，
  /// 与 `shouldRepaint => true`、`setState` 构成三重保障。
  final ValueNotifier<int> _repaintTick = ValueNotifier<int>(0);

  /// 当前命中的控制点索引（按下时记录，拖动期间用于高亮）
  int? _hitIndex;

  /// 指针按下位置（画布坐标）
  Offset? _downPos;

  /// 本次手势是否发生了超过阈值的拖动
  bool _dragged = false;

  /// 双击检测状态
  DateTime? _lastTapTime;
  Offset? _lastTapPos;
  int? _lastTapHitIndex;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _repaintTick.dispose();
    super.dispose();
  }

  /// 控制器变化（通道 / 网格 / 重置）时同步到画布。
  void _onControllerChanged() {
    final c = widget.controller;
    final needsReset = c.resetTick != _lastResetTick;
    setState(() {
      _lastResetTick = c.resetTick;
      _channel = c.channel;
      _gridVisible = c.showGrid;
      if (needsReset) {
        // 用 .copy() 保证可变长度：identity 的 const 定长列表无法 insert/removeAt
        _points = _points.copy()
          ..channels[_channel] = CurvePointSet.identity().copy();
      }
    });
    if (needsReset) _emit();
  }

  /// 数据已变化：重建 Widget 树 + 通知画师重绘
  void _markChanged() {
    setState(() {});
    _repaintTick.value++;
  }

  // ---- 手势处理（纯 Listener 指针事件，不经手势竞技场，单击加点最可靠） ----

  /// 命中测试：返回点击位置附近控制点的索引，无则 null
  int? _hitTestControlPoint(Offset pos) {
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final points = _activePoints;
    for (var i = 0; i < points.xs.length; i++) {
      final px = points.xs[i] * w;
      final py = h - points.ys[i] * h; // 数据 y 向上，画布 y 翻转
      if ((pos.dx - px).abs() <= _hitSlop && (pos.dy - py).abs() <= _hitSlop) {
        return i;
      }
    }
    return null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _downPos = event.localPosition;
    _hitIndex = _hitTestControlPoint(event.localPosition);
    _dragged = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final hit = _hitIndex;
    final pos = event.localPosition;

    if (hit == null) {
      // 未命中控制点：移动超过阈值记为拖动（空白区域无操作）
      if (_downPos != null && (_downPos! - pos).distance > _touchSlop) {
        _dragged = true;
      }
      return;
    }

    // 端点固定不可拖动
    if (hit == 0 || hit == _activePoints.xs.length - 1) return;

    _dragged = true;

    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final mx = pos.dx.clamp(_pointSize, w - _pointSize);
    final my = pos.dy.clamp(_pointSize, h - _pointSize);

    final prevX = _activePoints.xs[hit - 1];
    final nextX = _activePoints.xs[hit + 1];
    _activePoints.xs[hit] = _clamp(
      mx / w,
      ((prevX * w) + _hitSlop) / w,
      ((nextX * w) - _hitSlop) / w,
    );
    _activePoints.ys[hit] = ((h - my) / h).clamp(0.0, 1.0);

    _markChanged(); // 拖动中实时刷新画布
    _emit(); // 实时刷新图片预览
  }

  void _onPointerUp(PointerUpEvent event) {
    final pos = event.localPosition;
    final hit = _hitIndex;

    if (_dragged) {
      // 拖动结束：清除高亮
      _hitIndex = null;
      _dragged = false;
      _markChanged();
      _emit();
      _resetPointerState();
      return;
    }

    // 单击 / 双击
    final now = DateTime.now();
    final isDoubleTap = _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 350) &&
        _lastTapPos != null &&
        (_lastTapPos! - pos).distance < 32;

    if (hit != null && hit > 0 && hit < _activePoints.xs.length - 1) {
      // 点中控制点：连续两次点击同一控制点删除
      if (isDoubleTap && hit == _lastTapHitIndex) {
        _activePoints.xs.removeAt(hit);
        _activePoints.ys.removeAt(hit);
        _markChanged();
        _emit();
      }
    } else {
      // 空白区域：单击加点（双击空白区也只在第一次加点）
      if (!isDoubleTap) {
        _addOrRemovePoint(pos, remove: false);
      }
    }

    // 双击后重置，避免三连击连锁删除
    if (isDoubleTap) {
      _lastTapTime = null;
      _lastTapPos = null;
      _lastTapHitIndex = null;
    } else {
      _lastTapTime = now;
      _lastTapPos = pos;
      _lastTapHitIndex = hit;
    }
    _resetPointerState();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _resetPointerState();
  }

  void _resetPointerState() {
    _downPos = null;
    _hitIndex = null;
    _dragged = false;
  }

  double _clamp(double v, double minV, double maxV) =>
      v < minV ? minV : (v > maxV ? maxV : v);

  double _round2(double v) => double.parse(v.toStringAsFixed(2));

  void _addOrRemovePoint(Offset pos, {required bool remove}) {
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final xNorm = _round2((pos.dx / w).clamp(0.0, 1.0));
    final yNorm = _round2(((h - pos.dy) / h).clamp(0.0, 1.0));

    // 查找与该位置重叠的既有控制点
    var overlapIndex = -1;
    for (var i = 0; i < _activePoints.xs.length; i++) {
      if ((_activePoints.xs[i] - xNorm).abs() <= 0.05 &&
          (_activePoints.ys[i] - yNorm).abs() <= 0.05) {
        overlapIndex = i;
        break;
      }
    }

    if (remove) {
      if (overlapIndex > 0 && overlapIndex < _activePoints.xs.length - 1) {
        _activePoints.xs.removeAt(overlapIndex);
        _activePoints.ys.removeAt(overlapIndex);
        _markChanged();
        _emit();
      }
    } else {
      // 空白区域单击加点：x 不与既有控制点过近（避免重复 x 破坏样条）
      if (overlapIndex == -1 &&
          _activePoints.xs.every((x) => (x - xNorm).abs() > 0.02)) {
        var index = _activePoints.xs.length - 1;
        for (var i = 0; i < _activePoints.xs.length - 1; i++) {
          if (xNorm > _activePoints.xs[i] &&
              xNorm < _activePoints.xs[i + 1]) {
            index = i + 1;
            break;
          }
        }
        _activePoints.xs.insert(index, xNorm);
        _activePoints.ys.insert(index, yNorm);
        _markChanged();
        _emit();
      }
    }
  }

  void _emit() {
    widget.onChanged(_points.copy());
  }

  Size get _canvasSize => Size(
        math.max(MediaQuery.sizeOf(context).width - 40, 100).toDouble(),
        math.max(widget.curveHeight, 150),
      );

  @override
  Widget build(BuildContext context) {
    // 画布隐藏时收缩为占位，保留 State（控制点等编辑状态不丢失）。
    if (!widget.controller.showCanvas) {
      return const SizedBox.shrink();
    }
    final size = _canvasSize;
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        // 半透明背景：透出下方的预览图
        color: const Color(0x4D1C1C1C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: CustomPaint(
          size: size,
          painter: _CurvePainter(
            points: _activePoints,
            channel: _channel,
            pointSize: _pointSize,
            gridVisible: _gridVisible,
            hitIndex: _hitIndex,
            repaint: _repaintTick,
          ),
        ),
      ),
    );
  }
}

/// 曲线底部操作区（通道切换 / 重置 / 网格开关）。
///
/// 与悬浮的 [RestorableCurveCanvas] 通过同一个 [CurveEditorController] 联动。
class CurveToolControls extends StatelessWidget {
  /// Creates a [CurveToolControls].
  const CurveToolControls({
    super.key,
    required this.controller,
    required this.i18n,
  });

  /// 与画布共享的控制器。
  final CurveEditorController controller;

  /// 本地化文案（重置 / 网格 tooltip）。
  final I18nPixelsmixEditor i18n;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 重置 / 网格开关
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: i18n.resetCurve,
                    onPressed: controller.reset,
                  ),
                  IconButton(
                    icon: Icon(
                      controller.showGrid ? Icons.grid_on : Icons.grid_off,
                      color: Colors.white70,
                    ),
                    tooltip: i18n.toggleGrid,
                    onPressed: controller.toggleGrid,
                  ),
                  IconButton(
                    icon: Icon(
                      controller.showCanvas
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    tooltip: i18n.toggleCurveCanvas,
                    onPressed: controller.toggleCanvas,
                  ),
                ],
              ),
            ),
            // 通道切换
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final channel in CurveChannel.values)
                    _ChannelButton(
                      channel: channel,
                      selected: channel == controller.channel,
                      onTap: () => controller.changeChannel(channel),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final CurveChannel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = channel.activeColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A2A2A) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : const Color(0xFF333333),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          channel.label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  const _CurvePainter({
    required this.points,
    required this.channel,
    required this.pointSize,
    required this.gridVisible,
    required this.hitIndex,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final CurvePointSet points;
  final CurveChannel channel;
  final double pointSize;
  final bool gridVisible;

  /// 当前命中的控制点索引（拖动时高亮）
  final int? hitIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;

    // 通道主色：RGB 用浅灰，其余用对应通道颜色
    final accent = channel.activeColor == Colors.white
        ? const Color(0xFFE8E8E8)
        : channel.activeColor;

    _paintGrid(canvas, size);

    if (points.xs.length < 2) return;

    final spline = NaturalCubicSpline(points.xs, points.ys);
    final pts = _curveSamples(spline, w, h);

    // 曲线下方淡色填充
    final fill = Path()..moveTo(0, h);
    for (final p in pts) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..style = PaintingStyle.fill
        ..color = accent.withValues(alpha: 0.12),
    );

    // 曲线
    final curve = Path();
    for (var i = 0; i < pts.length; i++) {
      if (i == 0) {
        curve.moveTo(pts[i].dx, pts[i].dy);
      } else {
        curve.lineTo(pts[i].dx, pts[i].dy);
      }
    }
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );

    // 控制点
    for (var i = 0; i < points.xs.length; i++) {
      final center = Offset(points.xs[i] * w, h - points.ys[i] * h);
      final isEndpoint = i == 0 || i == points.xs.length - 1;
      final isActive = i == hitIndex;

      // 外圈光晕
      canvas.drawCircle(
        center,
        isActive ? pointSize + 5 : pointSize + 3,
        Paint()
          ..style = PaintingStyle.fill
          ..color = accent.withValues(alpha: isActive ? 0.5 : 0.25),
      );
      // 深色底
      canvas.drawCircle(
        center,
        pointSize,
        Paint()..color = const Color(0xFF141414),
      );
      // 内点（端点略小）
      canvas.drawCircle(
        center,
        isEndpoint ? pointSize - 4 : pointSize - 2.5,
        Paint()..color = accent,
      );
    }
  }

  /// 采样曲线上的点（画布坐标）
  List<Offset> _curveSamples(NaturalCubicSpline spline, double w, double h) {
    final steps = (w / 2).ceil();
    return List.generate(
      steps + 1,
      (i) {
        final x = (i * 2.0).clamp(0.0, w);
        final t = (x / w).clamp(0.0, 1.0);
        return Offset(x, h - spline.at(t) * h);
      },
      growable: false,
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    if (!gridVisible) return;
    final paint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) => true;
}
