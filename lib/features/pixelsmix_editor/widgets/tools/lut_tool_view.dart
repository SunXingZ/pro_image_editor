import 'package:flutter/material.dart';

/// LUT 工具面板。
///
/// 预设 3D LUT + 强度滑杆。
/// 参数结构：`{'preset': String, 'intensity': 0..100}`。
class LutToolView extends StatefulWidget {
  /// Creates a [LutToolView].
  const LutToolView({
    super.key,
    required this.params,
    required this.onChanged,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  static const List<String> _presets = [
    'identity',
    'warm',
    'cool',
    'vivid',
    'mono',
  ];

  static const Map<String, String> _labels = {
    'identity': 'Original',
    'warm': 'Warm',
    'cool': 'Cool',
    'vivid': 'Vivid',
    'mono': 'Mono',
  };

  @override
  State<LutToolView> createState() => _LutToolViewState();
}

class _LutToolViewState extends State<LutToolView> {
  late double _intensity;

  @override
  void initState() {
    super.initState();
    _intensity = (widget.params['intensity'] as num?)?.toDouble() ?? 100;
  }

  @override
  void didUpdateWidget(covariant LutToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final v = widget.params['intensity'];
    if (v is num) _intensity = v.toDouble();
  }

  String get _preset => widget.params['preset'] as String? ?? 'identity';

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    const labels = LutToolView._labels;
    const presets = LutToolView._presets;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 预设选择
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in presets)
                GestureDetector(
                  onTap: () =>
                      widget.onChanged({...widget.params, 'preset': p}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _preset == p
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _preset == p
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF333333),
                      ),
                    ),
                    child: Text(
                      labels[p] ?? p,
                      style: TextStyle(
                        fontSize: 12,
                        color: _preset == p
                            ? const Color(0xFFFFD700)
                            : Colors.white70,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 强度
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const SizedBox(
                width: 88,
                child: Text(
                  'Intensity',
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _intensity.clamp(0, 100),
                  min: 0,
                  max: 100,
                  divisions: 200,
                  onChanged: (v) {
                    setState(() => _intensity = v);
                    widget.onChanged({...widget.params, 'intensity': v});
                  },
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  _intensity.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
