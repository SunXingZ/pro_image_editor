import 'package:flutter/material.dart';

/// 颜色矩阵工具面板。
///
/// 顶部提供公共的输出通道切换（R/G/B/A），下方显示该行对应的
/// 4 个输入通道滑杆（-1~1），列主序存储。
/// 参数结构：`{'matrix': [16 doubles]}`。
class ColorMatrixToolView extends StatefulWidget {
  /// Creates a [ColorMatrixToolView].
  const ColorMatrixToolView({
    super.key,
    required this.params,
    required this.onChanged,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<ColorMatrixToolView> createState() => _ColorMatrixToolViewState();
}

class _ColorMatrixToolViewState extends State<ColorMatrixToolView> {
  static const List<String> _rows = ['R', 'G', 'B', 'A'];
  static const List<double> _identity = [
    1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1,
  ];

  /// 16 个值，本地驱动保证拖拽流畅。
  late List<double> _local = _fromParams();
  int _row = 0;

  List<double> _fromParams() {
    final v = widget.params['matrix'];
    if (v is List && v.length >= 16) {
      return v.take(16).map((e) => (e as num).toDouble()).toList();
    }
    return List.of(_identity);
  }

  @override
  void didUpdateWidget(covariant ColorMatrixToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _local = _fromParams();
    }
  }

  void _set(int col, double value) {
    final idx = _row * 4 + col;
    setState(() => _local[idx] = value);
    widget.onChanged({...widget.params, 'matrix': List.of(_local)});
  }

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRowSelector(color),
        for (var col = 0; col < 4; col++) _buildColSlider(col, color),
      ],
    );
  }

  Widget _buildRowSelector(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var r = 0; r < _rows.length; r++)
            GestureDetector(
              onTap: () => setState(() => _row = r),
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
                    color: _row == r
                        ? const Color(0xFFFFD700)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  _rows[r],
                  style: TextStyle(
                    color: _row == r ? const Color(0xFFFFD700) : color,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColSlider(int col, Color color) {
    final value = _local[_row * 4 + col];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              '${_rows[_row]} ← in[$col]',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(-1.0, 1.0),
              min: -1,
              max: 1,
              divisions: 200,
              onChanged: (v) => _set(col, v),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
