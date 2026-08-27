import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';
import '/shared/widgets/edit_slider.dart';
import '../../models/shader_filter_state.dart';

/// 模糊工具底部面板。
///
/// 仅提供类型切换（圆形/线性）与强度滑杆；
/// 模糊区域（圆心/半径或清晰带）通过预览图上的手势覆盖层控制。
class BlurToolView extends StatefulWidget {
  /// Creates a [BlurToolView].
  const BlurToolView({
    super.key,
    required this.current,
    required this.onChanged,
    required this.i18n,
  });

  /// 当前生效的模糊效果（用于初始化）。
  final ShaderFilterState? current;

  /// 状态变化回调（携带完整 [ShaderFilterState]）。
  final ValueChanged<ShaderFilterState> onChanged;

  /// 本地化文案（类型 / 强度标签）。
  final I18nPixelsmixEditor i18n;

  @override
  State<BlurToolView> createState() => _BlurToolViewState();
}

class _BlurToolViewState extends State<BlurToolView> {
  late bool _isCircular;
  late double _intensity;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _isCircular = c == null || c.tool == ShaderTool.selectiveBlur;
    _intensity = (c?.params['intensity'] as num?)?.toDouble() ?? 0;
  }

  void _emit() {
    // 保留已有的位置参数，仅改变类型 / 强度。
    // 注意：'intensity' 必须放在 spread 之后，否则会被旧参数中的
    // 过期强度覆盖，导致强度始终停留在初始值、模糊不生效。
    final prev = widget.current;
    final params = <String, dynamic>{
      if (prev != null) ...prev.params,
      'intensity': _intensity,
    };
    widget.onChanged(
      ShaderFilterState(
        tool: _isCircular
            ? ShaderTool.selectiveBlur
            : ShaderTool.tiltShiftBlur,
        params: params,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 类型切换
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (label, circular) in [
                (widget.i18n.circular, true),
                (widget.i18n.linear, false),
              ])
                GestureDetector(
                  onTap: () {
                    setState(() => _isCircular = circular);
                    _emit();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _isCircular == circular
                            ? const Color(0xFFFFD700)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: _isCircular == circular
                            ? const Color(0xFFFFD700)
                            : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 强度
        EditSlider(
          label: widget.i18n.intensity,
          value: _intensity.clamp(0, 30),
          min: 0,
          max: 30,
          divisions: 300,
          valueText: (_intensity * 100 / 30).round().toString(),
          onChanged: (v) {
            setState(() => _intensity = v);
            _emit();
          },
        ),
      ],
    );
  }
}
