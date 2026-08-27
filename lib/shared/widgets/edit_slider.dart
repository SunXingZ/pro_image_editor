// Flutter imports:
import 'package:flutter/material.dart';

/// RN `EditSlider` 的 Flutter 复刻：白色 28px 圆形滑块 + 3px 圆角轨道。
///
/// 布局与 RN `LabelRow + Slider` 一致：上方一行「左标签 / 右数值」
/// （space-between，13px），下方滑杆独占一整行，因此轨道够长不拥挤。
///
/// - 提供 [trackColors] 时整条轨道渲染为水平线性渐变（对应 RN
///   `trackTintColors` 传入 LinearGradient 的行为，如 HSL / 鲜艳度等滑杆）；
/// - 不提供时渲染为白色轨道（半透明底 + 左侧白色填充），与 RN 默认
///   `minimum/maximumTrackTintColor='white'` 一致。
class EditSlider extends StatefulWidget {
  /// Creates an [EditSlider].
  const EditSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.label,
    this.valueText,
    this.trackColors,
    this.snapToMiddle = false,
    this.enabled = true,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.marginBottom = 10,
  });

  /// 当前值。
  final double value;

  /// 值变化回调（拖拽过程中持续回调）。
  final ValueChanged<double> onChanged;

  /// 开始拖拽回调（对应 RN `onSlidingStart`）。
  final ValueChanged<double>? onChangeStart;

  /// 结束拖拽回调（对应 RN `onSlidingComplete`）。
  final ValueChanged<double>? onChangeEnd;

  /// 最小值。
  final double min;

  /// 最大值。
  final double max;

  /// 分档数；为空时连续取值。
  final int? divisions;

  /// 标签文字（位于滑杆上方左侧）；为空则不渲染文字行。
  final String? label;

  /// 数值文字（位于滑杆上方右侧）；为空时显示 [value] 取整。
  final String? valueText;

  /// 轨道渐变颜色；为空时渲染白色轨道 + 左侧白色填充。
  final List<Color>? trackColors;

  /// 是否启用「吸附中点」：拖拽接近中点（±3 单位）时吸附，对应 RN
  /// 滑杆的 `autoAttach` 行为（如鲜艳度 / 亮度等以 50 为中点的滑杆）。
  final bool snapToMiddle;

  /// 是否可交互；为 false 时仅展示。
  final bool enabled;

  /// 标签 / 数值文字颜色。
  final Color? textColor;

  /// 控件内边距（默认横向 16，保证数值右侧有间距）。
  final EdgeInsets padding;

  /// 与下一个控件之间的底部间距（对齐 RN LabelRow 的 marginBottom）。
  final double marginBottom;

  @override
  State<EditSlider> createState() => _EditSliderState();
}

class _EditSliderState extends State<EditSlider> {
  static const double _thumbSize = 28;
  static const double _trackHeight = 3;

  double _lastValue = 0;

  void _drag(double dx, double trackWidth) {
    if (!widget.enabled) return;
    final length = trackWidth - _thumbSize;
    if (length <= 0) return;
    var v = widget.min +
        ((dx - _thumbSize / 2) / length) * (widget.max - widget.min);
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = (widget.max - widget.min) / widget.divisions!;
      v = widget.min + ((v - widget.min) / step).round() * step;
    }
    v = v.clamp(widget.min, widget.max);
    if (widget.snapToMiddle) {
      final middle = (widget.min + widget.max) / 2;
      if ((v - middle).abs() <= 3) v = middle;
    }
    _lastValue = v;
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.textColor ?? Colors.white70;
    final fraction = ((widget.value - widget.min) / (widget.max - widget.min))
        .clamp(0.0, 1.0);
    final valueText = widget.valueText ??
        (widget.value.clamp(widget.min, widget.max)).round().toString();
    final hasText = widget.label != null || widget.valueText != null;
    return Padding(
      padding: widget.padding
          .copyWith(bottom: widget.padding.bottom + widget.marginBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 文字行：左标签 / 右数值（RN LabelRow 布局，滑杆独占下一行）
          if (hasText) ...[
            Row(
              mainAxisAlignment: widget.label != null
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                if (widget.valueText != null || widget.label != null)
                  Text(
                    valueText,
                    style: TextStyle(color: color, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: _thumbSize,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final length = w - _thumbSize;
                final thumbLeft = fraction * length;
                final gradient = _gradientOrNull();
                return SizedBox(
                  height: _thumbSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanDown: (d) {
                      widget.onChangeStart?.call(widget.value);
                      _drag(d.localPosition.dx, w);
                    },
                    onPanUpdate: (d) => _drag(d.localPosition.dx, w),
                    onPanEnd: (_) => widget.onChangeEnd?.call(_lastValue),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 轨道：渐变（整条）或白色半透明底
                        Positioned(
                          left: _thumbSize / 2,
                          right: _thumbSize / 2,
                          child: Container(
                            height: _trackHeight,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(_trackHeight / 2),
                              gradient: gradient,
                              color: gradient == null
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : null,
                            ),
                          ),
                        ),
                        // 无渐变时的左侧白色填充（到滑块中心）
                        if (widget.trackColors == null)
                          Positioned(
                            left: _thumbSize / 2,
                            width: thumbLeft,
                            child: Container(
                              height: _trackHeight,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(_trackHeight / 2),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        // 滑块：白色圆点 + 白色阴影（RN thumbStyle）
                        Positioned(
                          left: thumbLeft,
                          top: 0,
                          width: _thumbSize,
                          height: _thumbSize,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white70,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient? _gradientOrNull() {
    final colors = widget.trackColors;
    if (colors == null || colors.length < 2) return null;
    return LinearGradient(colors: colors);
  }
}
