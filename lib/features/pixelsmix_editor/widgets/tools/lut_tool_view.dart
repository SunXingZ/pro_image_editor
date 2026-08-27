import 'package:flutter/material.dart';

import '/shared/utils/lut/lut_parser.dart';
import '/shared/widgets/edit_slider.dart';

/// LUT 工具面板（对齐 RN `ImageLut`）。
///
/// 提供「选择文件」入口（由宿主应用通过 [PixelsmixEditorConfigs.lutFilePicker]
/// 实现，选择并解析 .cube/.csp 文件）、启用开关与强度滑杆。
/// 参数结构：
/// `{'enable': bool, 'intensity': 0..100, 'name': String,
///   'size': int, 'data': [r,g,b,...] 扁平化列表}`。
class LutToolView extends StatefulWidget {
  /// Creates a [LutToolView].
  const LutToolView({
    super.key,
    required this.params,
    required this.onChanged,
    this.onPickLut,
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// LUT 文件选择回调（宿主应用注入）；为空时隐藏「选择文件」入口。
  final Future<List<LutData>> Function()? onPickLut;

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

  bool get _enable => widget.params['enable'] as bool? ?? true;

  String get _name => widget.params['name'] as String? ?? '';

  Future<void> _pickLut() async {
    final picker = widget.onPickLut;
    if (picker == null) return;
    final luts = await picker();
    if (luts.isEmpty) return;
    final lut = luts.first;
    final flat = <double>[
      for (final row in lut.data) ...row,
    ];
    widget.onChanged({
      ...widget.params,
      'name': lut.name,
      'size': lut.size,
      'data': flat,
      'enable': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    const color = Colors.white70;
    final hasLut = widget.params['data'] is List &&
        (widget.params['data'] as List).isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 选择文件（RN ImageLut 的圆角全宽按钮）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: widget.onPickLut == null ? null : _pickLut,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                widget.onPickLut == null
                    ? (hasLut ? _name : '未配置 LUT 选择器')
                    : (hasLut ? _name : '选择文件'),
                style: const TextStyle(fontSize: 12, color: Color(0xFFE3E3E3)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        // 启用开关（RN ImageLut 的 Enable 行）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enable',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Switch(
                activeTrackColor: const Color(0xFF7B6CFF),
                activeThumbColor: Colors.white,
                inactiveTrackColor: Colors.white,
                inactiveThumbColor: Colors.white,
                value: _enable,
                onChanged: (v) =>
                    widget.onChanged({...widget.params, 'enable': v}),
              ),
            ],
          ),
        ),
        // 强度滑杆
        EditSlider(
          label: 'Intensity',
          value: _intensity.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 200,
          valueText: '${_intensity.round()}%',
          textColor: color,
          onChanged: (v) {
            setState(() => _intensity = v);
            widget.onChanged({...widget.params, 'intensity': v});
          },
        ),
      ],
    );
  }
}
