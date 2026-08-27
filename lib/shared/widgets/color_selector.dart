// Flutter imports:
import 'package:flutter/material.dart';

/// 默认取色色板（供画笔 / 文字等编辑器复用）。
const List<Color> kDefaultColorPalette = [
  Colors.white,
  Colors.black,
  Color(0xFF8E8E93),
  Color(0xFFFF3B30),
  Color(0xFFFF9500),
  Color(0xFFFFCC00),
  Color(0xFF34C759),
  Color(0xFF00C7BE),
  Color(0xFF007AFF),
  Color(0xFF5856D6),
  Color(0xFFAF52DE),
  Color(0xFFFF2D55),
];

/// RN `ColorSelector` 的 Flutter 复刻：一行圆形色块（28px，可选中描边）
/// + 可选「自定义颜色」入口。
///
/// 点击自定义入口弹出底部色板：SV（饱和/明度）面板 + 色相条 + 「完成」，
/// 对应 RN `Panel1 + HueSlider` 的取色交互。
class ColorSelector extends StatefulWidget {
  /// Creates a [ColorSelector].
  const ColorSelector({
    super.key,
    required this.colors,
    this.selected,
    this.showCustom = true,
    this.swatchSize = 28,
    this.swatchSpacing = 15,
    this.onSelect,
  });

  /// 可选色块列表。
  final List<Color> colors;

  /// 当前选中色（用于描边高亮）。
  final Color? selected;

  /// 是否显示「自定义颜色」入口（对应 RN `colorWheel`）。
  final bool showCustom;

  /// 色块直径。
  final double swatchSize;

  /// 色块间距。
  final double swatchSpacing;

  /// 选中回调。
  final ValueChanged<Color>? onSelect;

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Future<void> _openCustomPicker() async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) => _ColorPickerPanel(initial: widget.selected),
    );
    if (picked != null) widget.onSelect?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.showCustom)
          Padding(
            padding: EdgeInsets.only(right: widget.swatchSpacing),
            child: GestureDetector(
              onTap: _openCustomPicker,
              child: Container(
                width: widget.swatchSize,
                height: widget.swatchSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                  border: Border.all(color: Colors.white38, width: 1),
                ),
                child: const Icon(
                  Icons.colorize,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        for (final c in widget.colors)
          Padding(
            padding: EdgeInsets.only(right: widget.swatchSpacing),
            child: GestureDetector(
              onTap: () => widget.onSelect?.call(c),
              child: Container(
                width: widget.swatchSize,
                height: widget.swatchSize,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == widget.selected
                        ? Colors.white
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 自定义取色弹层：SV 面板 + 色相条 + 完成按钮（对应 RN Panel1 + HueSlider）。
class _ColorPickerPanel extends StatefulWidget {
  const _ColorPickerPanel({this.initial});

  final Color? initial;

  @override
  State<_ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<_ColorPickerPanel> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial ?? Colors.red);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSvPanel(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _buildHueBar(),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(_hsv.toColor()),
            child: Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                '完成',
                style: TextStyle(fontSize: 12, color: Color(0xFFE3E3E3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSvPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: (d) => _updateSv(d.localPosition, size),
          onPanUpdate: (d) => _updateSv(d.localPosition, size),
          child: SizedBox(
            width: size,
            height: size * 0.6,
            child: CustomPaint(
              painter: _SvPanelPainter(hsv: _hsv),
              child: Stack(
                children: [
                  Positioned(
                    left: _hsv.saturation * size - 10,
                    top: (1 - _hsv.value) * size * 0.6 - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hsv.toColor(),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateSv(Offset local, double size) {
    final s = (local.dx / size).clamp(0.0, 1.0);
    final v = (1 - local.dy / (size * 0.6)).clamp(0.0, 1.0);
    setState(() => _hsv = _hsv.withSaturation(s).withValue(v));
  }

  Widget _buildHueBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const thumbSize = 20.0;
        final w = constraints.maxWidth;
        final hue = _hsv.hue / 360;
        final left = hue * (w - thumbSize);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: (d) => _updateHue(d.localPosition.dx, w, thumbSize),
          onPanUpdate: (d) => _updateHue(d.localPosition.dx, w, thumbSize),
          child: SizedBox(
            height: thumbSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: thumbSize / 2,
                  right: thumbSize / 2,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: left,
                  top: 0,
                  width: thumbSize,
                  height: thumbSize,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black26, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateHue(double dx, double w, double thumbSize) {
    final f = ((dx - thumbSize / 2) / (w - thumbSize)).clamp(0.0, 1.0);
    setState(() => _hsv = _hsv.withHue(f * 360));
  }
}

/// SV（饱和 / 明度）面板绘制：底色为当前色相 + 白色横向渐变 + 黑色纵向渐变。
class _SvPanelPainter extends CustomPainter {
  const _SvPanelPainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    canvas
      ..drawRect(rect, Paint()..color = hueColor)
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.white, Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.transparent, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(covariant _SvPanelPainter oldDelegate) =>
      oldDelegate.hsv.hue != hsv.hue;
}
