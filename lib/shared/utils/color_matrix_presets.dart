// Dart imports:
import 'dart:math' as math;

// 参考来源（与 RN 项目 Presets.ts 保持一致）：
// https://fecolormatrix.com
// https://github.com/skratchdot/color-matrix/blob/master/lib/filters.js
// https://github.com/una/CSSgram/tree/master/source/css
// https://reactnative.directory/
// https://github.com/facebook/react-native/issues/34865
// react-native-color-matrix-image-filters
// https://github.com/PixiColorEffects/pixi-color-effects
// https://github.com/skratchdot/color-matrix
// https://github.com/pixijs/pixijs/tree/dev/packages

// 颜色矩阵以 4x5（20 个 double）表示：前 4 列是 RGB 系数，第 5 列是 offset。
// RN 的 ColorMatrix.transformMatrix 会每行 slice(0,4)（丢弃 offset 列）得到 16 个值
// 传给 shader，因此每条预设的 matrix 最终为 16 个 double（见 ColorMatrixPreset.matrix）。

/// 与 RN rn-color-matrices 中 `bias = Platform.OS === 'ios' ? 1 : 1` 一致。
const double bias = 1;

/// 与 RN rn-color-matrices 中 `biasRev = Platform.OS === 'ios' ? 1 : 1` 一致。
const double biasRev = 1;

/// 等价于 npm 包 `clamp` 的 `clamp(1 - v, 0, 1)`，将值约束在 [0, 1]。
double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// 等价于 RN rn-color-matrices 的 `colorToRGB`，将 0xRRGGBB 拆分为 0~1 的 RGB。
List<double> _colorToRGB(int color) {
  return <double>[
    ((color >> 16) & 0xFF) / 255,
    ((color >> 8) & 0xFF) / 255,
    (color & 0xFF) / 255,
  ];
}

/// 角度转弧度（Presets.ts 中的 degToRad）。
double degToRad(double deg) => math.pi * deg / 180;

// ---------------- 静态滤镜（staticFilters，4x5 矩阵） ----------------

/// 单位矩阵，无任何颜色变化。
List<double> normal() => <double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 亮度转 Alpha（将亮度写入 Alpha 通道）。
List<double> luminanceToAlpha() => <double>[
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0.2125, 0.7154, 0.0721, 0, 0,
    ];

/// 反色。
List<double> invert() => <double>[
      -1, 0, 0, 0, bias,
      0, -1, 0, 0, bias,
      0, 0, -1, 0, bias,
      0, 0, 0, 1, 0,
    ];

/// 夜视效果。
List<double> nightvision() => <double>[
      0.1, 0.4, 0, 0, 0,
      0.3, 1, 0.3, 0, 0,
      0, 0.4, 0.1, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 暖色调（静态矩阵）。
List<double> warm() => <double>[
      1.06, 0, 0, 0, 0,
      0, 1.01, 0, 0, 0,
      0, 0, 0.93, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 冷色调（静态矩阵）。
List<double> cool() => <double>[
      0.99, 0, 0, 0, 0,
      0, 0.93, 0, 0, 0,
      0, 0, 1.08, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 特艺彩色（Technicolor）效果。
List<double> technicolor() => <double>[
      1.9125277891456083, -0.8545344976951645, -0.09155508482755585, 0,
      11.793603434377337 / biasRev,
      -0.3087833385928097, 1.7658908555458428, -0.10601743074722245, 0,
      -70.35205161461398 / biasRev,
      -0.231103377548616, -0.7501899197440212, 1.847597816108189, 0,
      30.950940869491138 / biasRev,
      0, 0, 0, 1, 0,
    ];

/// 宝丽来（Polaroid）效果。
List<double> polaroid() => <double>[
      1.438, -0.062, -0.062, 0, 0,
      -0.122, 1.378, -0.122, 0, 0,
      -0.016, -0.016, 1.483, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 通道重排为 BGR。
List<double> toBGR() => <double>[
      0, 0, 1, 0, 0,
      0, 1, 0, 0, 0,
      1, 0, 0, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 柯达克罗姆（Kodachrome）胶片效果。
List<double> kodachrome() => <double>[
      1.1285582396593525, -0.3967382283601348, -0.03992559172921793, 0,
      63.72958762196502 / biasRev,
      -0.16404339962244616, 1.0835251566291304, -0.05498805115633132, 0,
      24.732407896706203 / biasRev,
      -0.16786010706155763, -0.5603416277695248, 1.6014850761964943, 0,
      35.62982807460946 / biasRev,
      0, 0, 0, 1, 0,
    ];

/// 布朗尼（Browni）胶片效果。
List<double> browni() => <double>[
      0.5997023498159715, 0.34553243048391263, -0.2708298674538042, 0,
      47.43192855600873 / biasRev,
      -0.037703249837783157, 0.8609577587992641, 0.15059552388459913, 0,
      -36.96841498319127 / biasRev,
      0.24113635128153335, -0.07441037908422492, 0.44972182064877153, 0,
      -7.562075277591283 / biasRev,
      0, 0, 0, 1, 0,
    ];

/// 复古（Vintage）效果。
List<double> vintage() => <double>[
      0.6279345635605994, 0.3202183420819367, -0.03965408211312453, 0,
      9.651285835294123 / biasRev,
      0.02578397704808868, 0.6441188644374771, 0.03259127616149294, 0,
      7.462829176470591 / biasRev,
      0.0466055556782719, -0.0851232987247891, 0.5241648018700465, 0,
      5.159190588235296 / biasRev,
      0, 0, 0, 1, 0,
    ];

/// LSD 迷幻效果。
List<double> lsd() => <double>[
      2, -0.4, 0.5, 0, 0,
      -0.5, 2, -0.4, 0, 0,
      -0.4, -0.5, 3, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 红色弱（Protanomaly）模拟。
List<double> protanomaly() => <double>[
      0.817, 0.183, 0, 0, 0,
      0.333, 0.667, 0, 0, 0,
      0, 0.125, 0.875, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 绿色弱（Deuteranomaly）模拟。
List<double> deuteranomaly() => <double>[
      0.8, 0.2, 0, 0, 0,
      0.258, 0.742, 0, 0, 0,
      0, 0.142, 0.858, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 蓝色弱（Tritanomaly）模拟。
List<double> tritanomaly() => <double>[
      0.967, 0.033, 0, 0, 0,
      0, 0.733, 0.267, 0, 0,
      0, 0.183, 0.817, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 红色盲（Protanopia）模拟。
List<double> protanopia() => <double>[
      0.567, 0.433, 0, 0, 0,
      0.558, 0.442, 0, 0, 0,
      0, 0.242, 0.758, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 绿色盲（Deuteranopia）模拟。
List<double> deuteranopia() => <double>[
      0.625, 0.375, 0, 0, 0,
      0.7, 0.3, 0, 0, 0,
      0, 0.3, 0.7, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 蓝色盲（Tritanopia）模拟。
List<double> tritanopia() => <double>[
      0.95, 0.05, 0, 0, 0,
      0, 0.433, 0.567, 0, 0,
      0, 0.475, 0.525, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 全色盲（Achromatopsia）模拟。
List<double> achromatopsia() => <double>[
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 全色弱（Achromatomaly）模拟。
List<double> achromatomaly() => <double>[
      0.618, 0.320, 0.062, 0, 0,
      0.163, 0.775, 0.062, 0, 0,
      0.163, 0.320, 0.516, 0, 0,
      0, 0, 0, 1, 0,
    ];

// ---------------- 动态函数（与 rn-color-matrices 公式一一对应） ----------------

/// RGBA 缩放。
List<double> rgba([double r = 1, double g = 1, double b = 1, double a = 1]) =>
    <double>[
      r, 0, 0, 0, 0,
      0, g, 0, 0, 0,
      0, 0, b, 0, 0,
      0, 0, 0, a, 0,
    ];

/// 饱和度，v 为 0 时去饱和、1 时不变。
List<double> saturate([double v = 1]) => <double>[
      0.213 + 0.787 * v, 0.715 - 0.715 * v, 0.072 - 0.072 * v, 0, 0,
      0.213 - 0.213 * v, 0.715 + 0.285 * v, 0.072 - 0.072 * v, 0, 0,
      0.213 - 0.213 * v, 0.715 - 0.715 * v, 0.072 + 0.928 * v, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 色相旋转，v 为弧度值。
List<double> hueRotate([double v = 0]) {
  final cos = math.cos(v);
  final sin = math.sin(v);
  final a00 = (0.213) + (cos * 0.787) - (sin * 0.213);
  final a01 = (0.715) - (cos * 0.715) - (sin * 0.715);
  final a02 = (0.072) - (cos * 0.072) + (sin * 0.928);
  final a10 = (0.213) - (cos * 0.213) + (sin * 0.143);
  final a11 = (0.715) + (cos * 0.285) + (sin * 0.140);
  final a12 = (0.072) - (cos * 0.072) - (sin * 0.283);
  final a20 = (0.213) - (cos * 0.213) - (sin * 0.787);
  final a21 = (0.715) - (cos * 0.715) + (sin * 0.715);
  final a22 = (0.072) + (cos * 0.928) + (sin * 0.072);

  return <double>[
    a00, a01, a02, 0, 0,
    a10, a11, a12, 0, 0,
    a20, a21, a22, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// 灰度，v=1 完全去色，v=0 不变。
List<double> grayscale([double v = 1]) {
  final cv = _clamp01(1 - v);

  return <double>[
    0.2126 + 0.7874 * cv, 0.7152 - 0.7152 * cv, 0.0722 - 0.0722 * cv, 0, 0,
    0.2126 - 0.2126 * cv, 0.7152 + 0.2848 * cv, 0.0722 - 0.0722 * cv, 0, 0,
    0.2126 - 0.2126 * cv, 0.7152 - 0.7152 * cv, 0.0722 + 0.9278 * cv, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// 棕褐色调，v=1 完全复古，v=0 不变。
List<double> sepia([double v = 1]) {
  final cv = _clamp01(1 - v);

  return <double>[
    0.393 + 0.607 * cv, 0.769 - 0.769 * cv, 0.189 - 0.189 * cv, 0, 0,
    0.349 - 0.349 * cv, 0.686 + 0.314 * cv, 0.168 - 0.168 * cv, 0, 0,
    0.272 - 0.272 * cv, 0.534 - 0.534 * cv, 0.131 + 0.869 * cv, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// 亮度，v=1 不变。
List<double> brightness([double v = 1]) => <double>[
      v, 0, 0, 0, 0,
      0, v, 0, 0, 0,
      0, 0, v, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 对比度，v=1 不变；offset 使用 bias 系数。
List<double> contrast([double v = 1]) {
  final n = 0.5 * (1 - v);

  return <double>[
    v, 0, 0, 0, bias * n,
    0, v, 0, 0, bias * n,
    0, 0, v, 0, bias * n,
    0, 0, 0, 1, 0,
  ];
}

/// 色温，v>0 变暖、v<0 变冷。
List<double> temperature([double v = 0]) => <double>[
      1 + v, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1 - v, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 色调染色，v>0 增强红蓝。
List<double> tint([double v = 0]) => <double>[
      1 + v, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1 + v, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 阈值化（二值化），offset 为 -bias * v。
List<double> threshold([double v = 0]) {
  const rLum = 0.03086;
  const gLum = 0.06094;
  const bLum = 0.00820;
  const r = rLum * 255;
  const g = gLum * 255;
  const b = bLum * 255;

  return <double>[
    r, g, b, 0, -bias * v,
    r, g, b, 0, -bias * v,
    r, g, b, 0, -bias * v,
    0, 0, 0, 1, 0,
  ];
}

/// 夜间效果。
List<double> night([double v = 0.1]) => <double>[
      v * (-2.0), -v, 0, 0, 0,
      -v, 0, v, 0, 0,
      0, v, v * 2.0, 0, 0,
      0, 0, 0, 1, 0,
    ];

/// 掠食者视角（红外效果）。
List<double> predator([double v = 1]) => <double>[
      // row 1
      11.224130630493164 * v,
      -4.794486999511719 * v,
      -2.8746118545532227 * v,
      0 * v,
      0.40342438220977783 * v / biasRev,
      // row 2
      -3.6330697536468506 * v,
      9.193157196044922 * v,
      -2.951810836791992 * v,
      0 * v,
      -1.316135048866272 * v / biasRev,
      // row 3
      -3.2184197902679443 * v,
      -4.2375030517578125 * v,
      7.476448059082031 * v,
      0 * v,
      0.8044459223747253 * v / biasRev,
      // row 4
      0, 0, 0, 1, 0,
    ];

/// 色调分层染色（colorTone）。颜色以 0xRRGGBB 整数传入。
List<double> colorTone([
  double? desaturation,
  double? toned,
  int? lightColor,
  int? darkColor,
]) {
  final lRgb = _colorToRGB(lightColor ?? 0xFFE580);
  final dRgb = _colorToRGB(darkColor ?? 0x338000);

  return <double>[
    0.3, 0.59, 0.11, 0, 0,
    lRgb[0], lRgb[1], lRgb[2], (desaturation ?? 0.2), 0,
    dRgb[0], dRgb[1], dRgb[2], (toned ?? 0.15), 0,
    lRgb[0] - dRgb[0], lRgb[1] - dRgb[1], lRgb[2] - dRgb[2], 0, 0,
  ];
}

/// 双色调（duoTone）。颜色以 0xRRGGBB 整数传入。
List<double> duoTone([int? first, int? second]) {
  final fRgb = _colorToRGB(first ?? 0xFFE580);
  final sRgb = _colorToRGB(second ?? 0x338000);

  return <double>[
    fRgb[0] - sRgb[0], 0, 0, 0, sRgb[0] * bias,
    fRgb[1] - sRgb[1], 0, 0, 0, sRgb[1] * bias,
    fRgb[2] - sRgb[2], 0, 0, 0, sRgb[2] * bias,
    0, 0, 0, 1, 0,
  ];
}

// ---------------- 矩阵拼接（concat-color-matrices 4x5 乘法） ----------------

/// 拼接两个 4x5 颜色矩阵（严格照抄 concat-color-matrices 的乘法公式）。
/// 结果等价于先应用 [matA] 再应用 [matB]。
List<double> concatTwoColorMatrices(List<double> matB, List<double> matA) {
  final tmp = List<double>.filled(20, 0.0);

  var index = 0;
  for (var j = 0; j < 20; j += 5) {
    for (var i = 0; i < 4; i++) {
      tmp[index++] = matA[j + 0] * matB[i + 0] +
          matA[j + 1] * matB[i + 5] +
          matA[j + 2] * matB[i + 10] +
          matA[j + 3] * matB[i + 15];
    }
    tmp[index++] = matA[j + 0] * matB[4] +
        matA[j + 1] * matB[9] +
        matA[j + 2] * matB[14] +
        matA[j + 3] * matB[19] +
        matA[j + 4];
  }

  return tmp;
}

/// 依次拼接多个 4x5 颜色矩阵（等价于 JS 的 reduce(concatTwoColorMatrices)）。
List<double> concatColorMatrices(List<List<double>> matrices) {
  return matrices.reduce(concatTwoColorMatrices);
}

/// 将 4x5 矩阵每行 slice(0,4)（丢弃第 5 个 offset 列），得到传给 shader 的 16 个值。
List<double> _toShaderMatrix(List<double> m) {
  return <double>[
    m[0], m[1], m[2], m[3],
    m[5], m[6], m[7], m[8],
    m[10], m[11], m[12], m[13],
    m[15], m[16], m[17], m[18],
  ];
}

/// 单个颜色矩阵滤镜预设。
class ColorMatrixPreset {
  /// 创建一个 [ColorMatrixPreset] 实例。
  ///
  /// - [name]: 预设名称（normal / R1~R10 / W1~W18 / C1~C16 / B1~B14）。
  /// - [classify]: 分类（all / recommend / warm / cool / bw）。
  /// - [isVip]: 是否为 VIP 预设。
  /// - [matrix]: 16 个 double 的颜色矩阵（4 行 x 4，已丢弃 offset 列）。
  const ColorMatrixPreset({
    required this.name,
    required this.classify,
    this.isVip = false,
    required this.matrix,
  });

  /// 预设名称（normal / R1~R10 / W1~W18 / C1~C16 / B1~B14）。
  final String name;

  /// 分类（all / recommend / warm / cool / bw）。
  final String classify;

  /// 是否为 VIP 预设。
  final bool isVip;

  /// 16 个 double 的颜色矩阵（4 行 x 4，已丢弃 offset 列）。
  final List<double> matrix;
}

/// 用 4x5 矩阵构建预设：先计算矩阵，再取前 4 列得到 16 值。
ColorMatrixPreset _buildPreset(
  String name,
  String classify,
  bool isVip,
  List<double> matrix,
) {
  return ColorMatrixPreset(
    name: name,
    classify: classify,
    isVip: isVip,
    matrix: _toShaderMatrix(matrix),
  );
}

/// 全部颜色矩阵滤镜预设（normal + R + W + C + B，共 59 条）。
/// 矩阵均在 Dart 端计算完成后取前 4 列得到 16 值。
final List<ColorMatrixPreset> colorMatrixPresets = <ColorMatrixPreset>[
  // normal
  _buildPreset('normal', 'all', false, normal()),

  // R1~R10：recommend 推荐组
  _buildPreset('R1', 'recommend', false, protanomaly()),
  _buildPreset('R2', 'recommend', false, deuteranomaly()),
  _buildPreset('R3', 'recommend', false, tritanomaly()),
  _buildPreset('R4', 'recommend', false, protanopia()),
  _buildPreset('R5', 'recommend', false, deuteranopia()),
  _buildPreset('R6', 'recommend', false, tritanopia()),
  _buildPreset('R7', 'recommend', false, achromatomaly()),
  _buildPreset('R8', 'recommend', false, polaroid()),
  _buildPreset('R9', 'recommend', false, warm()),
  _buildPreset('R10', 'recommend', false, cool()),

  // W1~W18：warm 暖色组
  _buildPreset('W1', 'warm', false, concatColorMatrices(<List<double>>[
        sepia(0.2),
        brightness(1.15),
        saturate(1.4),
      ])),
  _buildPreset('W2', 'warm', false, concatColorMatrices(<List<double>>[
        sepia(0.35),
        contrast(1.1),
        brightness(1.2),
        saturate(1.3),
      ])),
  _buildPreset('W3', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.5),
        contrast(1.2),
        saturate(1.8),
      ])),
  _buildPreset('W4', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.35),
        saturate(1.1),
        contrast(1.5),
      ])),
  _buildPreset('W5', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.15),
        brightness(1.2),
        saturate(1.35),
        hueRotate(degToRad(-5)),
      ])),
  _buildPreset('W6', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.4),
        contrast(1.5),
        brightness(1.2),
        saturate(1.4),
        hueRotate(degToRad(-10)),
      ])),
  _buildPreset('W7', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.5),
        contrast(1.05),
        brightness(1.05),
        saturate(1.35),
      ])),
  _buildPreset('W8', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.35),
        contrast(1.15),
        brightness(1.15),
        saturate(1.8),
      ])),
  _buildPreset('W9', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.2),
        brightness(1.3),
        saturate(1.25),
      ])),
  _buildPreset('W10', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.05),
        brightness(1.05),
        saturate(2),
      ])),
  _buildPreset('W11', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.35),
        contrast(1.05),
        brightness(1.05),
        saturate(1.75),
      ])),
  _buildPreset('W12', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.35),
        contrast(1.25),
        saturate(1.25),
      ])),
  _buildPreset('W13', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.35),
        contrast(1.25),
        brightness(1.1),
        saturate(1.25),
      ])),
  _buildPreset('W14', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.35),
        contrast(1.15),
        brightness(1.2),
        saturate(1.3),
      ])),
  _buildPreset('W15', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.45),
        contrast(1.25),
        brightness(1.75),
        saturate(1.3),
        hueRotate(degToRad(-5)),
      ])),
  _buildPreset('W16', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.7),
        contrast(1.35),
        saturate(1.6),
      ])),
  _buildPreset('W17', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.55),
        contrast(1.05),
        brightness(1.35),
        saturate(1.65),
      ])),
  _buildPreset('W18', 'warm', true, concatColorMatrices(<List<double>>[
        sepia(0.7),
        contrast(1.15),
        brightness(1.15),
        saturate(1.55),
      ])),

  // C1~C16：cool 冷色组
  _buildPreset('C1', 'cool', false, concatColorMatrices(<List<double>>[
        sepia(0.4),
        contrast(1.25),
        brightness(1.1),
        saturate(0.9),
        hueRotate(degToRad(-2)),
      ])),
  _buildPreset('C2', 'cool', false, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.25),
        brightness(1.25),
        hueRotate(degToRad(5)),
      ])),
  _buildPreset('C3', 'cool', false, concatColorMatrices(<List<double>>[
        sepia(0.15),
        contrast(1.25),
        brightness(1.25),
        hueRotate(degToRad(5)),
      ])),
  _buildPreset('C4', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.25),
        brightness(1.15),
        saturate(0.9),
        hueRotate(degToRad(-5)),
      ])),
  _buildPreset('C5', 'cool', true, concatColorMatrices(<List<double>>[
        contrast(1.1),
        brightness(1.1),
      ])),
  _buildPreset('C6', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.2),
        brightness(1.2),
        saturate(1.05),
        hueRotate(degToRad(-15)),
      ])),
  _buildPreset('C7', 'cool', true, concatColorMatrices(<List<double>>[
        saturate(1.1),
        contrast(1.5),
      ])),
  _buildPreset('C8', 'cool', true, concatColorMatrices(<List<double>>[
        contrast(1.1),
        brightness(1.25),
        saturate(1.1),
      ])),
  _buildPreset('C9', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.15),
        brightness(1.2),
      ])),
  _buildPreset('C10', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.25),
        brightness(1.2),
        saturate(0.9),
      ])),
  _buildPreset('C11', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.15),
        contrast(1.25),
        brightness(1.25),
        saturate(1.2),
      ])),
  _buildPreset('C12', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.1),
        brightness(1.1),
      ])),
  _buildPreset('C13', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.35),
        contrast(0.8),
        brightness(1.25),
        saturate(1.4),
      ])),
  _buildPreset('C14', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.25),
        brightness(1.25),
        saturate(1.35),
        hueRotate(degToRad(-5)),
      ])),
  _buildPreset('C15', 'cool', true, concatColorMatrices(<List<double>>[
        sepia(0.15),
        contrast(1.5),
        brightness(1.1),
        hueRotate(degToRad(-10)),
      ])),
  _buildPreset('C16', 'cool', true, concatColorMatrices(<List<double>>[
        contrast(1.1),
        brightness(1.15),
        saturate(1.1),
      ])),

  // B1~B14：bw 黑白/复古组
  _buildPreset('B1', 'bw', false, concatColorMatrices(<List<double>>[
        sepia(0.5),
        hueRotate(degToRad(-30)),
        saturate(1.4),
      ])),
  _buildPreset('B2', 'bw', false, concatColorMatrices(<List<double>>[
        sepia(0.5),
        contrast(1.25),
        brightness(1.15),
        saturate(0.9),
        hueRotate(degToRad(-5)),
      ])),
  _buildPreset('B3', 'bw', false, concatColorMatrices(<List<double>>[
        brightness(1.25),
        contrast(0.85),
        grayscale(1),
      ])),
  _buildPreset('B4', 'bw', true, concatColorMatrices(<List<double>>[
        brightness(1.4),
        contrast(0.95),
        saturate(0),
        sepia(0.35),
      ])),
  _buildPreset('B5', 'bw', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.5),
        brightness(0.9),
        hueRotate(degToRad(-15)),
      ])),
  _buildPreset('B6', 'bw', true, concatColorMatrices(<List<double>>[
        brightness(1.2),
        contrast(0.85),
        saturate(0.05),
        sepia(0.2),
      ])),
  _buildPreset('B7', 'bw', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.5),
        brightness(0.9),
        hueRotate(degToRad(-15)),
      ])),
  _buildPreset('B8', 'bw', true, concatColorMatrices(<List<double>>[
        sepia(0.25),
        contrast(1.5),
        brightness(0.95),
        hueRotate(degToRad(-15)),
      ])),
  _buildPreset('B9', 'bw', true, concatColorMatrices(<List<double>>[
        sepia(0.4),
        contrast(1.2),
        brightness(0.9),
        saturate(1.4),
        hueRotate(degToRad(-10)),
      ])),
  _buildPreset('B10', 'bw', true, concatColorMatrices(<List<double>>[
        sepia(0.75),
        contrast(0.75),
        brightness(1.25),
        saturate(1.4),
      ])),
  _buildPreset('B11', 'bw', true, concatColorMatrices(<List<double>>[
        brightness(1.3),
        contrast(1),
        grayscale(1.2),
      ])),
  _buildPreset('B12', 'bw', true, concatColorMatrices(<List<double>>[
        sepia(0.85),
        contrast(0.75),
        brightness(1.05),
        saturate(1.2),
      ])),
  _buildPreset('B13', 'bw', true, concatColorMatrices(<List<double>>[
        brightness(1.05),
        contrast(1.2),
        grayscale(1.5),
        saturate(0.8),
      ])),
  _buildPreset('B14', 'bw', true, concatColorMatrices(<List<double>>[
        brightness(1.1),
        contrast(1.5),
        grayscale(1.4),
        saturate(1.2),
      ])),
];
