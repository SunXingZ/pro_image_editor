import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:pixelsmix_filters/pixelsmix_filters.dart';

import '../models/shader_filter_state.dart';

/// 本项目内 pixelsmix shader 资源的包前缀路径。
const String kPixelsmixShadersRoot =
    'packages/pro_image_editor/lib/shared/shaders/pixelsmix/';

/// 单个已准备好的渲染 pass：shader 程序 + 需要注入的纹理采样器。
class ShaderRenderPass {
  /// Creates a [ShaderRenderPass].
  const ShaderRenderPass({
    required this.state,
    required this.shader,
    this.samplers = const {},
    this.textureKey,
  });

  /// 该 pass 对应的效果状态（prepare 时的快照）。
  final ShaderFilterState state;

  /// 已加载的片段着色器（可复用，uniform 在绘制前同步装配）。
  final ui.FragmentShader shader;

  /// 需要注入的纹理采样器：采样器索引 -> 图片。
  final Map<int, ui.Image> samplers;

  /// 纹理键：当前参数与已准备纹理一致时可复用本 pass。
  final String? textureKey;
}

/// 管理 Pixelsmix 调色 shader 的加载缓存、uniform 装配与纹理生成
/// （曲线 LUT / 3D LUT / 模糊纹理）。
///
/// shader 程序只加载一次并缓存，拖拽实时预览时不重复编译。
class ShaderRenderer {
  ShaderRenderer._();

  /// 单例。
  static final ShaderRenderer instance = ShaderRenderer._();

  final Map<ShaderTool, Future<ui.FragmentProgram>> _programs = {};
  final Map<String, ui.Image> _curveLutCache = {};
  final Map<String, Future<ui.Image>> _lutImageCache = {};

  /// 当前渲染后端是否支持 [ui.ImageFilter.shader]（Impeller）。
  bool get isSupported => ui.ImageFilter.isShaderFilterSupported;

  /// 各工具对应的 shader 资源路径。
  String _assetFor(ShaderTool tool) => switch (tool) {
        ShaderTool.toneCurve => '${kPixelsmixShadersRoot}tone_curve.frag',
        ShaderTool.hslMix => '${kPixelsmixShadersRoot}hsl_mix.frag',
        ShaderTool.colorBalance =>
          '${kPixelsmixShadersRoot}color_balance.frag',
        ShaderTool.highlightShadowTint =>
          '${kPixelsmixShadersRoot}highlight_shadow_tint.frag',
        ShaderTool.vibrance => '${kPixelsmixShadersRoot}vibrance.frag',
        ShaderTool.haze => '${kPixelsmixShadersRoot}haze.frag',
        ShaderTool.highlightShadow =>
          '${kPixelsmixShadersRoot}highlight_shadow.frag',
        ShaderTool.sharpen => '${kPixelsmixShadersRoot}sharpen.frag',
        ShaderTool.noise => '${kPixelsmixShadersRoot}noise.frag',
        ShaderTool.vignette => '${kPixelsmixShadersRoot}vignette.frag',
        ShaderTool.colorMatrix => '${kPixelsmixShadersRoot}color_matrix.frag',
        ShaderTool.lut => '${kPixelsmixShadersRoot}lut.frag',
        ShaderTool.selectiveBlur =>
          '${kPixelsmixShadersRoot}selective_blur.frag',
        ShaderTool.tiltShiftBlur =>
          '${kPixelsmixShadersRoot}tilt_shift_blur.frag',
      };

  /// 异步准备一个渲染 pass：加载 shader 程序并生成所需纹理。
  ///
  /// [source] 为被过滤的源图，模糊类工具需要它来生成模糊纹理；
  /// 返回 `null` 表示该效果当前无法渲染（后端不支持 / 缺少源图），
  /// 调用方应原样渲染。
  Future<ShaderRenderPass?> prepare(
    ShaderFilterState state, {
    ui.Image? source,
  }) async {
    if (!isSupported) return null;
    final asset = _assetFor(state.tool);

    final program = await (_programs[state.tool] ??= _loadProgram(asset));
    final shader = program.fragmentShader();
    final samplers = <int, ui.Image>{};

    switch (state.tool) {
      case ShaderTool.toneCurve:
        final curve =
            state.params['curve'] as Map<String, dynamic>? ?? const {};
        samplers[1] = await _curveLut(curve);
        break;
      case ShaderTool.lut:
        // 关闭状态：跳过该 pass（与 RN Lut.getUniforms 返回 null 一致）。
        if (state.params['enable'] == false) return null;
        final data = state.params['data'];
        if (data is List && data.isNotEmpty) {
          final size = (state.params['size'] as num?)?.toInt() ?? _lutSize;
          samplers[1] = await _customLutImage(data, size);
        } else {
          final preset = state.params['preset'] as String? ?? 'identity';
          samplers[1] = await _lutImage(preset);
        }
        break;
      case ShaderTool.selectiveBlur:
      case ShaderTool.tiltShiftBlur:
        if (source == null) return null;
        final intensity = (state.params['intensity'] as num?)?.toDouble() ?? 0;
        final blurred = await _buildBlurredTexture(source, intensity);
        if (blurred == null) return null;
        samplers[1] = blurred;
        break;
      default:
        break;
    }

    final pass = ShaderRenderPass(
      state: state,
      shader: shader,
      samplers: samplers,
      textureKey: textureKeyFor(state),
    );
    // 缓存本次 pass：子编辑器返回主编辑器时可同步复用，避免滤镜
    // 延迟出现造成闪屏。容量有限，超出时淘汰最早一条。
    if (_passCache.length >= _passCacheLimit) {
      _passCache.remove(_passCache.keys.first);
    }
    _passCache[state.id] = pass;
    return pass;
  }

  /// 全局 pass 缓存：键为状态 id。
  final Map<String, ShaderRenderPass> _passCache = {};
  static const int _passCacheLimit = 24;

  /// 同步取出指定状态已缓存的 pass（无则返回 `null`）。
  ShaderRenderPass? cachedPassFor(ShaderFilterState state) =>
      _passCache[state.id];

  /// 计算某个状态对应的纹理键（即纹理依赖的参数）。
  ///
  /// 键相同的状态可复用已准备的采样器，仅更新 uniform 即可，
  /// 从而让预览在拖动时同步、逐帧跟随。
  static String? textureKeyFor(ShaderFilterState state) =>
      switch (state.tool) {
        ShaderTool.toneCurve => state.params['curve']?.toString(),
        ShaderTool.lut => _lutTextureKey(state.params),
        ShaderTool.selectiveBlur || ShaderTool.tiltShiftBlur =>
          (state.params['intensity'] as num?)?.round().toString(),
        _ => null,
      };

  /// LUT 纹理键：自定义文件按 尺寸+内容哈希，预设按预设名。
  static String? _lutTextureKey(Map<String, dynamic> params) {
    final data = params['data'];
    if (data is List && data.isNotEmpty) {
      final size = (params['size'] as num?)?.toInt() ?? _lutSize;
      return 'custom:$size:${Object.hashAll(data)}';
    }
    return params['preset'] as String?;
  }

  Future<ui.FragmentProgram> _loadProgram(String asset) =>
      ui.FragmentProgram.fromAsset(asset);

  /// 由曲线参数生成 256×1 的调色 LUT 纹理（复用 pixelsmix 的曲线算法）。
  Future<ui.Image> _curveLut(Map<String, dynamic> curve) async {
    final key = curve.toString();
    final cached = _curveLutCache[key];
    if (cached != null) return cached;

    final points = RGBACurvePoints(
      channels: {
        for (final entry in curve.entries)
          CurveChannel.values.firstWhere(
            (c) => c.name == entry.key,
            orElse: () => CurveChannel.rgb,
          ): _parsePointSet(entry.value as List? ?? const <dynamic>[]),
      },
    );
    final pixels = buildToneCurvePixels(points);
    final image = await _decodeRgba(pixels, 256, 1);
    _curveLutCache[key] = image;
    return image;
  }

  static CurvePointSet _parsePointSet(List<dynamic> points) {
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

  /// 支持的 3D LUT 预设名。
  static const List<String> lutPresets = [
    'identity',
    'warm',
    'cool',
    'vivid',
    'mono',
  ];

  /// 生成指定预设的 3D LUT 纹理（宽 = size*size，高 = size，与 lut.frag 布局一致）。
  Future<ui.Image> _lutImage(String preset) async {
    final cached = _lutImageCache[preset];
    if (cached != null) return cached;
    final future = _buildLutImage(preset);
    _lutImageCache[preset] = future;
    return future;
  }

  static const int _lutSize = 32;

  Future<ui.Image> _buildLutImage(String preset) async {
    const size = _lutSize;
    const w = size * size;
    const h = size;
    final pixels = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final slice = x ~/ size;
        final px = x % size;
        final r = px / (size - 1);
        final g = y / (size - 1);
        final b = slice / (size - 1);
        final out = _applyLut(r, g, b, preset);
        final idx = (y * w + x) * 4;
        pixels[idx] = (out[0] * 255).round();
        pixels[idx + 1] = (out[1] * 255).round();
        pixels[idx + 2] = (out[2] * 255).round();
        pixels[idx + 3] = 255;
      }
    }
    return _decodeRgba(pixels, w, h);
  }

  /// 生成文件解析出的自定义 3D LUT 纹理（宽 = size*size，高 = size）。
  ///
  /// 像素布局与 RN `createImageByLut` 一致：按数据序号 i 映射到
  /// (startY = (i/size)%size, startX = i%size + size*((i/size)/size))。
  Future<ui.Image> _customLutImage(List<dynamic> data, int size) async {
    final key = 'custom:$size:${Object.hashAll(data)}';
    final cached = _lutImageCache[key];
    if (cached != null) return cached;
    final future = _buildCustomLutImage(data, size);
    _lutImageCache[key] = future;
    return future;
  }

  Future<ui.Image> _buildCustomLutImage(List<dynamic> data, int size) async {
    final w = size * size;
    final h = size;
    final pixels = Uint8List(w * h * 4);
    final count = size * size * size;
    for (var i = 0; i < count; i++) {
      final startY = (i ~/ size) % size;
      final startX = i % size + size * ((i ~/ size) ~/ size);
      final src = i * 3;
      final r = (data[src] as num).clamp(0.0, 1.0);
      final g = (data[src + 1] as num).clamp(0.0, 1.0);
      final b = (data[src + 2] as num).clamp(0.0, 1.0);
      final idx = (startY * w + startX) * 4;
      pixels[idx] = (r * 255).round();
      pixels[idx + 1] = (g * 255).round();
      pixels[idx + 2] = (b * 255).round();
      pixels[idx + 3] = 255;
    }
    return _decodeRgba(pixels, w, h);
  }

  static List<double> _applyLut(double r, double g, double b, String preset) {
    switch (preset) {
      case 'warm':
        return [
          (r * 1.08 + 0.03).clamp(0.0, 1.0),
          (g * 1.02).clamp(0.0, 1.0),
          (b * 0.94 - 0.02).clamp(0.0, 1.0),
        ];
      case 'cool':
        return [
          (r * 0.94 - 0.02).clamp(0.0, 1.0),
          g.clamp(0.0, 1.0),
          (b * 1.06 + 0.03).clamp(0.0, 1.0),
        ];
      case 'vivid':
        double f(double v) => v < 0.5 ? v * 0.85 : v * 1.15;
        return [
          f(r).clamp(0.0, 1.0),
          f(g).clamp(0.0, 1.0),
          f(b).clamp(0.0, 1.0),
        ];
      case 'mono':
        final lum = 0.299 * r + 0.587 * g + 0.114 * b;
        return [lum, lum, lum];
      default:
        return [r, g, b];
    }
  }

  /// 模糊纹理缓存：键为强度，源图切换时清空。
  ui.Image? _blurSource;
  final Map<int, ui.Image> _blurCache = {};

  /// 由源图生成模糊纹理（多遍高斯，方向交替）。
  ///
  /// 模糊纹理是参数函数而非时间函数，生成后即可被最终合成 pass
  /// 逐帧复用；视频画面变化时纹理不会逐帧更新（已知降级）。
  Future<ui.Image?> _buildBlurredTexture(
    ui.Image? source,
    double intensity,
  ) async {
    if (source == null) return null;
    if (!identical(_blurSource, source)) {
      _blurSource = source;
      _blurCache.clear();
    }
    final key = intensity.round().clamp(0, 30).toInt();
    final cached = _blurCache[key];
    if (cached != null) return cached;
    final texture = await _buildBlurPasses(source, intensity);
    _blurCache[key] = texture;
    return texture;
  }

  Future<ui.Image> _buildBlurPasses(ui.Image source, double intensity) async {
    final downscaled = await _maybeDownscale(source);
    try {
      // 优先使用与 pixelsmix 自测页一致的 export 离屏管线（已验证），
      // 模糊由 gaussian shader 在光栅化时完成，可靠。
      return await _buildBlurPassesExport(downscaled, intensity);
    } catch (_) {
      // export 管线异常时回退到 saveLayer 方案。
      return _buildBlurPassesSaveLayer(downscaled, intensity);
    }
  }

  bool _filtersRegistered = false;

  /// 注册 pixelsmix 的离屏管线（幂等，仅首次生效）。
  Future<void> _ensureFiltersRegistered() async {
    if (_filtersRegistered) return;
    await registerPixelsmixFilters();
    _filtersRegistered = true;
  }

  Future<ui.Image> _buildBlurPassesExport(
    ui.Image source,
    double intensity,
  ) async {
    await _ensureFiltersRegistered();
    var texture = TextureSource.fromImage(source);
    final passes = intensity.round().clamp(0, 30).toInt();
    for (var i = 0; i < passes; i++) {
      final radius = (passes - i - 1) * 0.5;
      final dir = i.isEven
          ? math.Point<double>(radius, 0)
          : math.Point<double>(0, radius);
      final cfg = PixelsmixGaussianBlurShaderConfiguration()..direction = dir;
      final img = await cfg.export(texture, texture.size);
      texture = TextureSource.fromImage(img);
    }
    return texture.image;
  }

  Future<ui.Image> _buildBlurPassesSaveLayer(
    ui.Image source,
    double intensity,
  ) async {
    var current = source;
    final passes = intensity.round().clamp(0, 30).toInt();
    for (var i = 0; i < passes; i++) {
      final radius = ((passes - i - 1) * 0.5).clamp(0.0, 10.0);
      if (radius <= 0) continue;
      current = await _gaussianPass(current, radius, i.isEven);
    }
    return current;
  }

  /// 模糊纹理生成前先降采样（长边不超过 1024），
  /// 否则全分辨率多遍高斯在拖动时明显卡顿。
  Future<ui.Image> _maybeDownscale(ui.Image src) async {
    const maxDim = 1024.0;
    final longSide = math.max(src.width, src.height).toDouble();
    if (longSide <= maxDim) return src;
    final scale = maxDim / longSide;
    final w = (src.width * scale).round();
    final h = (src.height * scale).round();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      src,
      Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint(),
    );
    final picture = recorder.endRecording();
    return picture.toImage(w, h);
  }

  Future<ui.Image> _gaussianPass(
    ui.Image src,
    double sigma,
    bool horizontal,
  ) async {
    final rect = Rect.fromLTWH(
      0,
      0,
      src.width.toDouble(),
      src.height.toDouble(),
    );
    final recorder = ui.PictureRecorder();
    // saveLayer 携带 imageFilter 是 ImageFiltered 的底层机制，保证模糊生效。
    Canvas(recorder)
      ..saveLayer(
        rect,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: horizontal ? sigma : 0,
            sigmaY: horizontal ? 0 : sigma,
          ),
      )
      ..drawImage(src, Offset.zero, Paint())
      ..restore();
    final picture = recorder.endRecording();
    return picture.toImage(src.width, src.height);
  }

  static Future<ui.Image> _decodeRgba(Uint8List pixels, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  /// 同步装配 uniforms（须在 [prepare] 之后、绘制前调用）。
  ///
  /// [state] 为装配 uniforms 所依据的最新参数（可与 [ShaderRenderPass.state]
  /// 不同，用于拖动时即时跟随）；[size] 为渲染区域逻辑尺寸。
  void apply(
    ShaderRenderPass pass,
    ShaderFilterState state,
    Size size,
    double devicePixelRatio,
  ) {
    final physical = Size(
      size.width * devicePixelRatio,
      size.height * devicePixelRatio,
    );
    final shader = pass.shader;
    final p = state.params;
    void setFloat(int i, double v) => shader.setFloat(i, v);

    switch (pass.state.tool) {
      case ShaderTool.toneCurve:
        // tone_curve.frag: u_size(0) 由引擎自动设置为纹理尺寸
        break;

      case ShaderTool.hslMix:
        // hsl_mix.frag: 8×vec3（location 2,5,...,23）
        final colors = p['colors'] as Map<String, dynamic>? ?? const {};
        const names = PixelsmixHslMixShaderConfiguration.colorNames;
        const hues = PixelsmixHslMixShaderConfiguration.colorHues;
        for (var i = 0; i < names.length; i++) {
          final minHue = hues[i];
          final maxHue = i == hues.length - 1 ? 0.0 : hues[i + 1];
          final v = colors[names[i]];
          final h = (v is List && v.isNotEmpty)
              ? (v[0] as num).toDouble()
              : 0.0;
          final s =
              (v is List && v.length > 1) ? (v[1] as num).toDouble() : 0.0;
          final b =
              (v is List && v.length > 2) ? (v[2] as num).toDouble() : 0.0;
          // 与 RN HslMix.getColorShifts 一致：hue 为 -100~100 的滑杆值，
          // 换算 lerp(minHue, maxHue, hue)/100 = (minHue + (maxHue-minHue)*hue)/100。
          // 之前多除了一次 100，导致 Hue 位移比 RN 弱约 100 倍、肉眼不生效。
          final x = (minHue + (maxHue - minHue) * h) / 100.0;
          final y = (100 + s) / 100;
          final z = (100 + b) / 100;
          setFloat(i * 3 + 2, x);
          setFloat(i * 3 + 3, y);
          setFloat(i * 3 + 4, z);
        }
        break;

      case ShaderTool.colorBalance:
        // color_balance.frag: shadows(2) midtones(5) highlights(8)
        // preserveLuminosity(11)
        final bands = ['shadows', 'midtones', 'highlights'];
        for (var band = 0; band < bands.length; band++) {
          final rgb = _rgbList(p[bands[band]]);
          for (var c = 0; c < 3; c++) {
            setFloat(band * 3 + c + 2, rgb[c]);
          }
        }
        setFloat(11, (p['preserveLuminosity'] as bool? ?? true) ? 1.0 : 0.0);
        break;

      case ShaderTool.highlightShadowTint:
        // highlight_shadow_tint.frag: intensity(2,3) colors(4,7)
        setFloat(2, ((p['shadowTint'] as num?)?.toDouble() ?? 0) / 100 * 0.2);
        setFloat(
          3,
          ((p['highlightTint'] as num?)?.toDouble() ?? 0) / 100 * 0.2,
        );
        _setColor(
          setFloat,
          4,
          Color((p['shadowTintColor'] as int?) ?? 0xFF000000),
        );
        _setColor(
          setFloat,
          7,
          Color((p['highlightTintColor'] as int?) ?? 0xFF000000),
        );
        break;

      case ShaderTool.vibrance:
        // vibrance.frag: factor(2)
        setFloat(
          2,
          (((p['vibrance'] as num?)?.toDouble() ?? 50) - 50) / 100 * 1.2,
        );
        break;

      case ShaderTool.haze:
        // haze.frag: hazeDistance(2) slope(3)
        setFloat(2, ((p['haze'] as num?)?.toDouble() ?? 0) / 100 * 0.3);
        setFloat(3, 0.0);
        break;

      case ShaderTool.highlightShadow:
        // highlight_shadow.frag: shadows(2) highlights(3)
        setFloat(2, ((p['shadows'] as num?)?.toDouble() ?? 0) / 100);
        setFloat(
          3,
          1 - ((p['highlights'] as num?)?.toDouble() ?? 0) / 100,
        );
        break;

      case ShaderTool.sharpen:
        // sharpen.frag: factor(2)
        setFloat(2, ((p['sharpen'] as num?)?.toDouble() ?? 0) / 100 * 1.5);
        break;

      case ShaderTool.noise:
        // noise.frag: amount(2)
        setFloat(2, ((p['noise'] as num?)?.toDouble() ?? 0) / 100);
        break;

      case ShaderTool.vignette:
        // vignette.frag: center(2) color(4) start(7) end(8)
        setFloat(2, 0.5);
        setFloat(3, 0.5);
        final v = (p['vignette'] as num?)?.toDouble() ?? 0;
        setFloat(7, 0.70 - v / 100);
        setFloat(8, 0.75);
        setFloat(4, 0.0);
        setFloat(5, 0.0);
        setFloat(6, 0.0);
        break;

      case ShaderTool.colorMatrix:
        // color_matrix.frag: mat4(2..17)
        final m = p['matrix'] as List? ?? _identityMatrix;
        for (var i = 0; i < 16 && i < m.length; i++) {
          setFloat(i + 2, (m[i] as num).toDouble());
        }
        break;

      case ShaderTool.lut:
        // lut.frag: lutSize(2) intensity(3)
        final size = (p['size'] as num?)?.toInt() ?? _lutSize;
        setFloat(2, size.toDouble());
        setFloat(3, ((p['intensity']) ?? 100) / 100);
        break;

      case ShaderTool.selectiveBlur:
        // selective_blur.frag: radius(2) point(3,4) blurSize(5) aspect(6)
        final aspectRatio = physical.height / physical.width;
        final radius = (p['radius'] as num?)?.toDouble() ?? 0.25;
        final circleRadius = radius * aspectRatio.clamp(0.0, 1.0);
        setFloat(2, circleRadius + 0.1);
        setFloat(3, (p['x'] as num?)?.toDouble() ?? 0.5);
        setFloat(4, (p['y'] as num?)?.toDouble() ?? 0.5);
        setFloat(5, circleRadius / 2);
        setFloat(6, aspectRatio);
        break;

      case ShaderTool.tiltShiftBlur:
        // tilt_shift_blur.frag: topFocus(2) bottomFocus(3) falloff(4)
        setFloat(2, (p['topFocus'] as num?)?.toDouble() ?? 0.33);
        setFloat(3, (p['bottomFocus'] as num?)?.toDouble() ?? 0.66);
        setFloat(
          4,
          (p['focusFallOffRate'] as num?)?.toDouble() ?? 0.12,
        );
        break;
    }

    for (final entry in pass.samplers.entries) {
      pass.shader.setImageSampler(entry.key, entry.value);
    }
  }

  static void _setColor(
    void Function(int index, double value) setFloat,
    int location,
    Color color,
  ) {
    setFloat(location, color.r);
    setFloat(location + 1, color.g);
    setFloat(location + 2, color.b);
  }

  static List<double> _rgbList(dynamic value) {
    if (value is List) {
      final rgb = <double>[];
      for (var i = 0; i < 3; i++) {
        rgb.add((value[i] as num).toDouble());
      }
      return rgb;
    }
    return const [0, 0, 0];
  }

  /// 4x4 恒等颜色矩阵（列主序）。
  static const List<double> _identityMatrix = [
    1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1,
  ];
}
