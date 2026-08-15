import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/shader_filter_state.dart';
import '../services/shader_renderer.dart';

/// 在 widget 树内应用 Pixelsmix shader 效果的通用渲染组件。
///
/// 通过 `ImageFiltered(ImageFilter.shader(...))` 将 shader 直接作用于
/// 子内容（图像），因此：
/// - 无需改动截图导出链路，效果即可烘焙进最终结果；
/// - 对视频编辑器同样逐帧生效（Impeller 后端）。
///
/// 当后端不支持（Skia）或效果未实现时，原样渲染 [child]。
class ShaderFilteredWidget extends StatefulWidget {
  /// Creates a [ShaderFilteredWidget].
  const ShaderFilteredWidget({
    super.key,
    required this.shaderFilters,
    required this.child,
    this.playTimeNotifier,
    this.imageSize,
    this.sourceImage,
  });

  /// 需要应用的 shader 效果列表（按顺序链式应用）。
  final List<ShaderFilterState> shaderFilters;

  /// 视频播放时间通知器；为空时所有效果无条件生效。
  final ValueNotifier<Duration>? playTimeNotifier;

  /// 被过滤内容的逻辑尺寸（图像尺寸）。
  ///
  /// 用于保证 shader 的 UV 映射到图像本身而非外层布局区域；
  /// 为空时回退到实际布局约束。
  final Size? imageSize;

  /// 源图（已解码）。模糊类工具需要它生成模糊纹理。
  final ui.Image? sourceImage;

  /// 被过滤的内容（通常为 [FilteredWidget]）。
  final Widget child;

  @override
  State<ShaderFilteredWidget> createState() => _ShaderFilteredWidgetState();
}

class _ShaderFilteredWidgetState extends State<ShaderFilteredWidget> {
  final List<ShaderRenderPass> _passes = [];
  bool _supported = true;
  int _prepareSeq = 0;
  bool _preparing = false;
  bool _prepareQueued = false;

  @override
  void initState() {
    super.initState();
    _supported = ShaderRenderer.instance.isSupported;
    widget.playTimeNotifier?.addListener(_onTimeChanged);
    _prepare();
  }

  @override
  void didUpdateWidget(covariant ShaderFilteredWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playTimeNotifier != widget.playTimeNotifier) {
      oldWidget.playTimeNotifier?.removeListener(_onTimeChanged);
      widget.playTimeNotifier?.addListener(_onTimeChanged);
    }
    if (oldWidget.sourceImage != widget.sourceImage) {
      _prepare();
    } else if (oldWidget.shaderFilters != widget.shaderFilters &&
        _needsReprepare()) {
      _prepare();
    }
  }

  /// 判断是否需要重新准备（工具集合或纹理键变化时才需要）。
  ///
  /// 纯 uniform 参数变化由 build 即时跟随，无需异步重载。
  bool _needsReprepare() {
    final tools = widget.shaderFilters.map((s) => s.tool).toSet();
    final passTools = _passes.map((p) => p.state.tool).toSet();
    if (tools.length != passTools.length) return true;
    for (final t in tools) {
      if (!passTools.contains(t)) return true;
    }
    for (final pass in _passes) {
      ShaderFilterState? current;
      for (final s in widget.shaderFilters) {
        if (s.tool == pass.state.tool) current = s;
      }
      if (current == null) continue;
      if (pass.textureKey != ShaderRenderer.textureKeyFor(current)) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    widget.playTimeNotifier?.removeListener(_onTimeChanged);
    super.dispose();
  }

  void _onTimeChanged() {
    setState(() {});
  }

  Future<void> _prepare() async {
    if (!_supported) return;
    // 合并并发准备：拖拽过程中只执行最新一次，避免异步重建堆积造成卡顿。
    _prepareSeq++;
    if (_preparing) {
      _prepareQueued = true;
      return;
    }
    _preparing = true;
    _prepareQueued = false;
    final seq = _prepareSeq;

    final passes = <ShaderRenderPass>[];
    for (final state in widget.shaderFilters) {
      final pass = await ShaderRenderer.instance.prepare(
        state,
        source: widget.sourceImage,
      );
      if (pass != null) passes.add(pass);
    }

    if (!mounted) return;
    _preparing = false;
    if (seq != _prepareSeq || _prepareQueued) {
      await _prepare();
      return;
    }
    setState(() {
      _passes
        ..clear()
        ..addAll(passes);
    });
  }

  /// 计算当前（考虑视频时间轴后）应生效的效果。
  ///
  /// 时间轴模式下 shader 参数无法线性插值，仅做显隐切换。
  List<ShaderFilterState> _effectiveStates() {
    final playTime = widget.playTimeNotifier?.value;
    if (playTime == null) return widget.shaderFilters;
    return widget.shaderFilters.where((state) {
      final start = state.startTime ?? Duration.zero;
      final end = state.endTime;
      if (playTime < start) return false;
      if (end != null && !(playTime < end)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) return widget.child;
    final passes = _resolvedPasses();
    if (passes.isEmpty) return widget.child;

    final dpr = MediaQuery.devicePixelRatioOf(context);

    Widget wrapChain(Size size) {
      // 按工具匹配 pass 与当前状态，直接用最新参数装配 uniforms，
      // 使拖动时预览逐帧同步跟随；纹理不匹配时沿用 pass 快照避免闪烁。
      final effective = _effectiveStates();
      final stateByTool = <ShaderTool, ShaderFilterState>{
        for (final s in effective) s.tool: s,
      };
      final usedPasses = <ShaderRenderPass>[];
      for (final pass in passes) {
        final current = stateByTool[pass.state.tool];
        if (current == null) continue; // 该工具当前无生效效果
        final canApplyCurrent =
            pass.textureKey == ShaderRenderer.textureKeyFor(current);
        ShaderRenderer.instance.apply(
          pass,
          canApplyCurrent ? current : pass.state,
          size,
          dpr,
        );
        usedPasses.add(pass);
      }
      if (usedPasses.isEmpty) return widget.child;

      // 按列表顺序链式应用：先加入的效果作用于原图（最内层），
      // 后加入的效果叠加在最上层，与用户操作顺序一致。
      var child = widget.child;
      for (final pass in usedPasses) {
        child = ImageFiltered(
          imageFilter: ui.ImageFilter.shader(pass.shader),
          child: child,
        );
      }
      return child;
    }

    final imageSize = widget.imageSize;
    if (imageSize != null) {
      return wrapChain(imageSize);
    }

    return LayoutBuilder(
      builder: (context, constraints) => wrapChain(constraints.biggest),
    );
  }

  /// 解析当前应使用的渲染 pass 列表（顺序与 [widget.shaderFilters] 一致）。
  ///
  /// 优先使用已就绪（纹理键匹配当前状态）的异步准备 pass；当某个效果刚被
  /// 重新编辑、异步重载尚未完成时，优先回退到全局缓存中该状态最新准备好的
  /// pass（例如子编辑器 done 时已预准备），避免返回主编辑器后首帧仍渲染旧
  /// pass 造成的闪屏；均不可用时沿用旧 pass 兜底，避免该效果整体缺失。
  List<ShaderRenderPass> _resolvedPasses() {
    final result = <ShaderRenderPass>[];
    for (final s in widget.shaderFilters) {
      ShaderRenderPass? pass;
      for (final p in _passes) {
        if (p.state.tool == s.tool) {
          pass = p;
          break;
        }
      }
      if (pass != null &&
          pass.textureKey == ShaderRenderer.textureKeyFor(s)) {
        result.add(pass);
        continue;
      }
      final fresh = ShaderRenderer.instance.cachedPassFor(s);
      if (fresh != null) {
        result.add(fresh);
      } else if (pass != null) {
        result.add(pass);
      }
    }
    return result;
  }
}
