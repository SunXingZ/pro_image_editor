import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '/shared/utils/parser/curve_parser.dart';

/// 支持的 Pixelsmix 调色 / 滤镜工具类型。
///
/// 每个枚举值对应一个独立的底部工具栏入口与独立编辑页。
enum ShaderTool {
  /// 色调曲线（4 通道 RGB/R/G/B 控制点）。
  toneCurve('toneCurve'),

  /// HSL 混色（8 色相 × H/S/L）。
  hslMix('hslMix'),

  /// 色彩平衡（阴影 / 中间调 / 高光 RGB 色偏）。
  colorBalance('colorBalance'),

  /// 高光阴影色调。
  highlightShadowTint('highlightShadowTint'),

  /// 鲜艳度。
  vibrance('vibrance'),

  /// 去雾。
  haze('haze'),

  /// 高光 / 阴影。
  highlightShadow('highlightShadow'),

  /// 锐化。
  sharpen('sharpen'),

  /// 噪点。
  noise('noise'),

  /// 暗角。
  vignette('vignette'),

  /// 颜色矩阵。
  colorMatrix('colorMatrix'),

  /// 3D LUT。
  lut('lut'),

  /// 圆形模糊。
  selectiveBlur('selectiveBlur'),

  /// 线性模糊。
  tiltShiftBlur('tiltShiftBlur');

  const ShaderTool(this.id);

  /// 工具的稳定字符串标识，用于序列化。
  final String id;

  /// 根据字符串标识反查 [ShaderTool]。
  static ShaderTool? fromId(String id) {
    for (final tool in ShaderTool.values) {
      if (tool.id == id) return tool;
    }
    return null;
  }
}

/// RN `GPUImage` 固定的着色器叠加顺序（值越小越先作用于原图）。
///
/// 对应 RN `ImageEditorPage.tsx` 中 GPUImage 的 JSX 嵌套顺序：Lut 最内层
/// 最先应用，ToneCurve 最外层最后叠加，与用户操作顺序无关。Flutter 侧渲染
/// 时按此顺序对效果排序，保证任意操作顺序下叠加结果与 RN 一致。
int shaderToolCompositionOrder(ShaderTool tool) => switch (tool) {
      ShaderTool.lut => 0,
      ShaderTool.colorMatrix => 1,
      ShaderTool.selectiveBlur || ShaderTool.tiltShiftBlur => 2,
      ShaderTool.sharpen => 3,
      ShaderTool.vignette => 4,
      ShaderTool.highlightShadow => 5,
      ShaderTool.vibrance => 6,
      ShaderTool.haze => 7,
      ShaderTool.highlightShadowTint => 8,
      ShaderTool.noise => 9,
      ShaderTool.hslMix => 10,
      // RN 交互预览无 colorBalance 节点（其 UI 驱动 highlightShadowTint），
      // 此处按同类最终调色步骤排在 HSL 之后、ToneCurve 之前。
      ShaderTool.colorBalance => 11,
      ShaderTool.toneCurve => 12,
    };

/// 一条可序列化的 Pixelsmix 调色 / 滤镜效果。
///
/// 与 [FilterState] / [TuneAdjustmentMatrix] 平行：携带视频时间轴字段，
/// 可随主编辑器历史撤销 / 重做，并由 [ShaderFilteredWidget] 渲染。
///
/// [params] 为工具相关的参数，均为 JSON 可序列化结构：
/// - `toneCurve`:
///   `{'curve': {'rgb': [[x,y],...], 'r': [...], 'g': [...], 'b': [...]}}`
/// - `hslMix`:
///   `{'colors': {'red': [h,s,b], 'orange': [...], ...}}`
/// - `colorBalance`:
///   `{'shadows': [r,g,b], 'midtones': [r,g,b], 'highlights': [r,g,b],
///     'preserveLuminosity': bool}`
/// - `highlightShadowTint`:
///   `{'shadowTintIntensity': double, 'highlightTintIntensity': double,
///     'shadowTintColor': int, 'highlightTintColor': int}`
/// - `vibrance` / `haze` / `highlightShadow` / `sharpen` / `noise`:
///   单值或双值对象。
/// - `vignette`:
///   `{'center': [x,y], 'color': int, 'start': double, 'end': double}`
/// - `colorMatrix`:
///   `{'matrix': [16 doubles, 列主序]}`
/// - `lut`:
///   `{'lutTexture': String, 'intensity': double}`
/// - `selectiveBlur`:
///   `{'x': double, 'y': double, 'radius': double, 'blurSize': double,
///     'intensity': double}`
/// - `tiltShiftBlur`:
///   `{'topFocus': double, 'bottomFocus': double,
///     'focusFallOffRate': double, 'intensity': double}`
class ShaderFilterState {
  /// Creates a [ShaderFilterState] instance from a [Map] representation.
  factory ShaderFilterState.fromMap(Map<String, dynamic> map) {
    return ShaderFilterState(
      id: (map['id'] as String?) ?? _generateId(),
      tool: ShaderTool.fromId(map['tool'] as String? ?? '') ??
          ShaderTool.toneCurve,
      params: (map['params'] as Map<String, dynamic>?) ?? const {},
      startTime: map['startTime'] != null
          ? Duration(milliseconds: map['startTime'] as int)
          : null,
      endTime: map['endTime'] != null
          ? Duration(milliseconds: map['endTime'] as int)
          : null,
      enterDuration: map['enterDuration'] != null
          ? Duration(milliseconds: map['enterDuration'] as int)
          : null,
      exitDuration: map['exitDuration'] != null
          ? Duration(milliseconds: map['exitDuration'] as int)
          : null,
      enterCurve: parseCurve(map['enterCurve'] as String?),
      exitCurve: parseCurve(map['exitCurve'] as String?),
      meta: (map['meta'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Creates a [ShaderFilterState] with the given fields.
  ShaderFilterState({
    String? id,
    required this.tool,
    required this.params,
    this.startTime,
    this.endTime,
    this.enterDuration,
    this.exitDuration,
    this.enterCurve,
    this.exitCurve,
    this.meta = const {},
  }) : id = id ?? _generateId();

  static int _idCounter = 0;

  static String _generateId() {
    _idCounter++;
    return 'shader-filter-${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  /// 唯一标识。
  final String id;

  /// 工具类型。
  final ShaderTool tool;

  /// 工具参数（JSON 可序列化）。
  final Map<String, dynamic> params;

  /// 视频时间轴字段（仅视频编辑器使用；为空时始终生效）。
  /// 开始时间。
  final Duration? startTime;

  /// 结束时间。
  final Duration? endTime;

  /// 进入过渡时长（视频时间）。
  final Duration? enterDuration;

  /// 退出过渡时长（视频时间）。
  final Duration? exitDuration;

  /// 进入过渡曲线。
  final Curve? enterCurve;

  /// 退出过渡曲线。
  final Curve? exitCurve;

  /// 用户附加元数据。
  final Map<String, dynamic> meta;

  /// 是否为"无效果"（空参数且工具为恒等）。
  bool get isIdentity => params.isEmpty;

  /// 转换为 [Map] 表示。
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tool': tool.id,
      'params': params,
      if (startTime != null) 'startTime': startTime!.inMilliseconds,
      if (endTime != null) 'endTime': endTime!.inMilliseconds,
      if (enterDuration != null) 'enterDuration': enterDuration!.inMilliseconds,
      if (exitDuration != null) 'exitDuration': exitDuration!.inMilliseconds,
      if (enterCurve != null) 'enterCurve': curveToString(enterCurve!),
      if (exitCurve != null) 'exitCurve': curveToString(exitCurve!),
      if (meta.isNotEmpty) 'meta': meta,
    };
  }

  /// 深拷贝。
  ShaderFilterState copy() {
    return ShaderFilterState(
      id: id,
      tool: tool,
      params: {...params},
      startTime: startTime,
      endTime: endTime,
      enterDuration: enterDuration,
      exitDuration: exitDuration,
      enterCurve: enterCurve,
      exitCurve: exitCurve,
      meta: {...meta},
    );
  }

  /// 以新字段复制。
  ShaderFilterState copyWith({
    String? id,
    ShaderTool? tool,
    Map<String, dynamic>? params,
    Duration? startTime,
    Duration? endTime,
    Duration? enterDuration,
    Duration? exitDuration,
    Curve? enterCurve,
    Curve? exitCurve,
    Map<String, dynamic>? meta,
  }) {
    return ShaderFilterState(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      params: params ?? {...this.params},
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      enterDuration: enterDuration ?? this.enterDuration,
      exitDuration: exitDuration ?? this.exitDuration,
      enterCurve: enterCurve ?? this.enterCurve,
      exitCurve: exitCurve ?? this.exitCurve,
      meta: meta ?? {...this.meta},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShaderFilterState &&
        other.id == id &&
        other.tool == tool &&
        mapEquals(other.params, params) &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.enterDuration == enterDuration &&
        other.exitDuration == exitDuration &&
        other.enterCurve == enterCurve &&
        other.exitCurve == exitCurve &&
        mapEquals(other.meta, meta);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      tool.hashCode ^
      params.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      enterDuration.hashCode ^
      exitDuration.hashCode ^
      enterCurve.hashCode ^
      exitCurve.hashCode ^
      meta.hashCode;
}
