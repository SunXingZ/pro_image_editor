// Dart imports:
import 'dart:async';
import 'dart:ui' as ui;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixelsmix_filters/pixelsmix_filters.dart';

// Project imports:
import '/core/mixins/converted_callbacks.dart';
import '/core/mixins/converted_configs.dart';
import '/core/mixins/standalone_editor.dart';
import '/core/utils/size_utils.dart';
import '/pro_image_editor.dart';
import '/shared/services/content_recorder/widgets/content_recorder.dart';
import '/shared/utils/file_constructor_utils.dart';
import '/shared/widgets/transform/transformed_content_generator.dart';

export 'models/shader_filter_state.dart';
export 'services/shader_renderer.dart';
export 'widgets/pixelsmix_editor_appbar.dart';
export 'widgets/pixelsmix_editor_bottombar.dart';
export 'widgets/shader_filtered_widget.dart';
export 'widgets/source_image_loader.dart';
export 'widgets/tools/blur_tool_view.dart';
export 'widgets/tools/color_balance_tool_view.dart';
export 'widgets/tools/color_matrix_tool_view.dart';
export 'widgets/tools/curve_tool_view.dart';
export 'widgets/tools/highlight_shadow_tint_tool_view.dart';
export 'widgets/tools/hsl_tool_view.dart';
export 'widgets/tools/lut_tool_view.dart';
export 'widgets/tools/restorable_curve_panel.dart';
export 'widgets/tools/slider_tool_view.dart';

/// The `PixelsmixEditor` widget allows users to adjust the current image with
/// a single Pixelsmix shader tool (tone curve, HSL, color balance, ...).
///
/// 通过工厂构造器创建（与 `TuneEditor` 一致）：
/// - [PixelsmixEditor.file]
/// - [PixelsmixEditor.asset]
/// - [PixelsmixEditor.network]
/// - [PixelsmixEditor.memory]
/// - [PixelsmixEditor.autoSource]
/// - [PixelsmixEditor.video]
class PixelsmixEditor extends StatefulWidget
    with StandaloneEditor<PixelsmixEditorInitConfigs> {
  /// Constructs a `PixelsmixEditor` widget.
  const PixelsmixEditor._({
    super.key,
    required this.initConfigs,
    this.editorImage,
    this.videoController,
  }) : assert(
         editorImage != null || videoController != null,
         'Either editorImage or videoController must be provided.',
       );

  /// Constructs a `PixelsmixEditor` widget with image data loaded from memory.
  factory PixelsmixEditor.memory(
    Uint8List byteArray, {
    Key? key,
    required PixelsmixEditorInitConfigs initConfigs,
  }) {
    return PixelsmixEditor._(
      key: key,
      editorImage: EditorImage(byteArray: byteArray),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PixelsmixEditor` widget with an image loaded from a file.
  factory PixelsmixEditor.file(
    dynamic file, {
    Key? key,
    required PixelsmixEditorInitConfigs initConfigs,
  }) {
    return PixelsmixEditor._(
      key: key,
      editorImage: EditorImage(file: ensureFileInstance(file)),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PixelsmixEditor` widget with an image loaded from an asset.
  factory PixelsmixEditor.asset(
    String assetPath, {
    Key? key,
    required PixelsmixEditorInitConfigs initConfigs,
  }) {
    return PixelsmixEditor._(
      key: key,
      editorImage: EditorImage(assetPath: assetPath),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PixelsmixEditor` widget with an image loaded from a network
  /// URL.
  factory PixelsmixEditor.network(
    String networkUrl, {
    Key? key,
    required PixelsmixEditorInitConfigs initConfigs,
  }) {
    return PixelsmixEditor._(
      key: key,
      editorImage: EditorImage(networkUrl: networkUrl),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PixelsmixEditor` widget with an image loaded automatically
  /// based on the provided source.
  factory PixelsmixEditor.autoSource({
    Key? key,
    Uint8List? byteArray,
    dynamic file,
    String? assetPath,
    String? networkUrl,
    EditorImage? editorImage,
    ProVideoController? videoController,
    required PixelsmixEditorInitConfigs initConfigs,
  }) {
    return PixelsmixEditor._(
      key: key,
      editorImage: videoController != null
          ? null
          : editorImage ??
                EditorImage(
                  byteArray: byteArray,
                  file: file,
                  networkUrl: networkUrl,
                  assetPath: assetPath,
                ),
      videoController: videoController,
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PixelsmixEditor` widget with an video player.
  factory PixelsmixEditor.video(
    ProVideoController videoController, {
    Key? key,
    required PixelsmixEditorInitConfigs initConfigs,
  }) {
    return PixelsmixEditor._(
      key: key,
      videoController: videoController,
      initConfigs: initConfigs,
    );
  }

  @override
  final PixelsmixEditorInitConfigs initConfigs;
  @override
  final EditorImage? editorImage;
  @override
  final ProVideoController? videoController;

  @override
  createState() => PixelsmixEditorState();
}

/// The state class for the `PixelsmixEditor` widget.
class PixelsmixEditorState extends State<PixelsmixEditor>
    with
        ImageEditorConvertedConfigs,
        ImageEditorConvertedCallbacks,
        StandaloneEditorState<PixelsmixEditor, PixelsmixEditorInitConfigs> {
  /// Stream controller to trigger UI updates on parameter change.
  late final StreamController<void> uiStream;

  /// 当前工具。
  ShaderTool get tool => initConfigs.tool;

  /// 是否模糊类入口（圆形/线性共用同一个编辑页）。
  bool get _isBlurTool =>
      tool == ShaderTool.selectiveBlur || tool == ShaderTool.tiltShiftBlur;

  /// 曲线工具是否使用悬浮面板（覆盖在预览图上层，不占用底部空间）。
  ///
  /// 仅在未自定义底部栏时生效；若调用方提供了自定义 `bottomBar`，则交由
  /// 调用方自行渲染，避免出现两个曲线面板。
  bool get _useFloatingCurvePanel =>
      tool == ShaderTool.toneCurve &&
      configs.pixelsmixEditor.widgets.bottomBar == null;

  /// 预览应渲染的效果：其他已应用的 shader 效果 + 当前编辑中的工具。
  ///
  /// 与主编辑器渲染顺序一致（重编辑同工具时在原位替换、保持顺序），
  /// 保证所见即所得，避免保存后效果与预览不一致造成"叠加/强度翻倍"观感。
  List<ShaderFilterState> get _previewShaderFilters {
    final state = current;
    final applied = appliedShaderFilters;
    if (state == null) return applied;
    final result = <ShaderFilterState>[];
    var replaced = false;
    for (final s in applied) {
      final matches = _isBlurTool
          ? (s.tool == ShaderTool.selectiveBlur ||
              s.tool == ShaderTool.tiltShiftBlur)
          : s.tool == tool;
      if (matches) {
        if (!replaced) {
          result.add(state);
          replaced = true;
        }
        // 同工具的旧状态跳过，保留原位
      } else {
        result.add(s);
      }
    }
    if (!replaced) result.add(state);
    return result;
  }

  /// 当前生效的 shader 效果。
  ShaderFilterState? current;

  /// 预览解码后的源图（供 done 时预准备模糊纹理等）。
  ui.Image? _previewSource;

  /// 曲线画布与底部操作区的共享控制器（toneCurve 工具使用）。
  CurveEditorController? _curveController;

  CurveEditorController get _curveEditorController =>
      _curveController ??= CurveEditorController();

  /// Pixelsmix 编辑器回调。
  PixelsmixEditorCallbacks? get pixelsmixEditorCallbacks =>
      callbacks.pixelsmixEditorCallbacks;

  @override
  void initState() {
    super.initState();
    uiStream = StreamController.broadcast();
    uiStream.stream.listen((_) => rebuildController.add(null));

    // 初始化当前参数：优先取已应用的、同工具（模糊类含两种）的最近一条效果。
    for (final state in appliedShaderFilters.reversed) {
      if (state.tool == tool ||
          (_isBlurTool &&
              (state.tool == ShaderTool.selectiveBlur ||
                  state.tool == ShaderTool.tiltShiftBlur))) {
        current = state;
        break;
      }
    }

    pixelsmixEditorCallbacks?.onInit?.call();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      pixelsmixEditorCallbacks?.onAfterViewInit?.call();
    });
  }

  @override
  void dispose() {
    _curveController?.dispose();
    uiStream.close();
    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    rebuildController.add(null);
    super.setState(fn);
  }

  /// 已应用的 shader 效果（来自 initConfigs）。
  List<ShaderFilterState> get appliedShaderFilters =>
      initConfigs.appliedShaderFilters;

  /// 工具参数变化时更新当前效果并实时刷新预览。
  void onChanged(Map<String, dynamic> params) {
    final prev = current;
    setState(() {
      // 保留时间轴字段，避免视频编辑时丢失分段/过渡信息。
      current = ShaderFilterState(
        tool: tool,
        params: params,
        startTime: prev?.startTime,
        endTime: prev?.endTime,
        enterDuration: prev?.enterDuration,
        exitDuration: prev?.exitDuration,
        enterCurve: prev?.enterCurve,
        exitCurve: prev?.exitCurve,
        meta: prev?.meta ?? const {},
      );
    });
    uiStream.add(null);
    pixelsmixEditorCallbacks?.handleShaderFilterChange(current!);
  }

  /// 完整状态变化（模糊工具切换类型时工具本身会改变）。
  void onShaderStateChanged(ShaderFilterState state) {
    final prev = current;
    setState(() {
      // 保留时间轴字段，避免视频编辑时丢失分段/过渡信息。
      current = ShaderFilterState(
        id: state.id,
        tool: state.tool,
        params: state.params,
        startTime: state.startTime ?? prev?.startTime,
        endTime: state.endTime ?? prev?.endTime,
        enterDuration: state.enterDuration ?? prev?.enterDuration,
        exitDuration: state.exitDuration ?? prev?.exitDuration,
        enterCurve: state.enterCurve ?? prev?.enterCurve,
        exitCurve: state.exitCurve ?? prev?.exitCurve,
        meta: state.meta.isNotEmpty ? state.meta : (prev?.meta ?? const {}),
      );
    });
    uiStream.add(null);
    pixelsmixEditorCallbacks?.handleShaderFilterChange(current!);
  }

  /// 由模糊手势参数生成 [ShaderFilterState]。
  void _onBlurGesture(BlurParams params) {
    final isCircular = params.type == BlurType.circular;
    final c =
        params.circular ??
        const BlurCircularParams(x: 0.5, y: 0.5, radius: 0.25);
    final l =
        params.linear ??
        const BlurLinearParams(topFocus: 0.33, bottomFocus: 0.66);
    onShaderStateChanged(
      ShaderFilterState(
        tool: isCircular
            ? ShaderTool.selectiveBlur
            : ShaderTool.tiltShiftBlur,
        params: isCircular
            ? {
                'intensity': params.intensity,
                'x': c.x,
                'y': c.y,
                'radius': c.radius,
              }
            : {
                'intensity': params.intensity,
                'topFocus': l.topFocus,
                'bottomFocus': l.bottomFocus,
              },
      ),
    );
  }

  /// 由 [ShaderFilterState] 生成模糊手势覆盖层参数。
  BlurParams _blurParamsFromState(ShaderFilterState state) {
    final isCircular = state.tool == ShaderTool.selectiveBlur;
    final p = state.params;
    return BlurParams(
      type: isCircular ? BlurType.circular : BlurType.tiltShift,
      intensity: (p['intensity'] as num?)?.toDouble() ?? 0,
      circular: isCircular
          ? BlurCircularParams(
              x: (p['x'] as num?)?.toDouble() ?? 0.5,
              y: (p['y'] as num?)?.toDouble() ?? 0.5,
              radius: (p['radius'] as num?)?.toDouble() ?? 0.25,
            )
          : null,
      linear: !isCircular
          ? BlurLinearParams(
              topFocus: (p['topFocus'] as num?)?.toDouble() ?? 0.33,
              bottomFocus: (p['bottomFocus'] as num?)?.toDouble() ?? 0.66,
            )
          : null,
    );
  }

  /// 处理"完成"：返回当前效果（无效果时返回 null）。
  Future<void> done() async {
    final state = current;
    if (state != null) {
      // 预准备当前效果（复用缓存并写入 pass 缓存），确保返回主编辑器前
      // 已就绪，避免主编辑器重建后首帧未滤镜造成的闪屏。
      try {
        await ShaderRenderer.instance.prepare(state, source: _previewSource);
      } catch (_) {
        // 预准备失败不影响返回，首次渲染时仍会异步加载。
      }
    }
    doneEditing(
      editorImage: editorImage,
      returnValue: state == null ? null : [state],
      blur: appliedBlurFactor,
      matrixFilterList: appliedFilters,
      matrixTuneAdjustmentsList: appliedTuneAdjustments
          .map((item) => item.matrix)
          .toList(),
      transform: initialTransformConfigs,
    );
    pixelsmixEditorCallbacks?.handleDone();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme.copyWith(
        tooltipTheme: theme.tooltipTheme.copyWith(preferBelow: true),
      ),
      child: ExtendedPopScope(
        canPop: configs.pixelsmixEditor.enableGesturePop,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: configs.pixelsmixEditor.style.uiOverlayStyle,
          child: SafeArea(
            top: configs.pixelsmixEditor.safeArea.top,
            bottom: configs.pixelsmixEditor.safeArea.bottom,
            left: configs.pixelsmixEditor.safeArea.left,
            right: configs.pixelsmixEditor.safeArea.right,
            child: RecordInvisibleWidget(
              controller: screenshotCtrl,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: !configs.pixelsmixEditor.safeArea.bottom,
                child: Scaffold(
                  backgroundColor: configs.pixelsmixEditor.style.background,
                  appBar: _buildAppBar(),
                  body: _buildBody(),
                  bottomNavigationBar: _buildBottomNavBar(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (configs.pixelsmixEditor.widgets.appBar != null) {
      return configs.pixelsmixEditor.widgets.appBar!.call(
        this,
        rebuildController.stream,
      );
    }
    return PixelsmixEditorAppbar(
      configs: configs.pixelsmixEditor,
      i18n: i18n.pixelsmixEditor,
      onClose: close,
      onDone: done,
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        editorBodySize = constraints.biggest;
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            if (initConfigs.convertToUint8List && isVideoEditor)
              _buildBackground(),
            ContentRecorder(
              controller: screenshotCtrl,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  if (!initConfigs.convertToUint8List || !isVideoEditor)
                    _buildBackground(),
                  if (configs.pixelsmixEditor.widgets.bodyItemsRecorded != null)
                    ...configs.pixelsmixEditor.widgets.bodyItemsRecorded!(
                      this,
                      rebuildController.stream,
                    ),
                ],
              ),
            ),
            if (configs.pixelsmixEditor.widgets.bodyItems != null)
              ...configs.pixelsmixEditor.widgets.bodyItems!(
                this,
                rebuildController.stream,
              ),
            // 曲线工具：面板悬浮在预览图上层，不占用底部空间。
            if (_useFloatingCurvePanel) _buildFloatingCurvePanel(),
          ],
        );
      },
    );
  }

  /// 悬浮在预览图上层的曲线画布。
  Widget _buildFloatingCurvePanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildCurveToolView().buildCanvas(),
      ),
    );
  }

  /// 构建曲线工具视图（画布与底部操作区共享同一个控制器）。
  CurveToolView _buildCurveToolView() => CurveToolView(
        params: current?.params ?? const {},
        onChanged: onChanged,
        curveHeight: 220,
        controller: _curveEditorController,
      );

  Widget _buildBackground() {
    return SourceImageLoader(
      image: editorImage,
      builder: (source) {
        _previewSource = source;
        return Hero(
          tag: heroTag,
          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        child: TransformedContentGenerator(
          isVideoPlayer: videoController != null,
          configs: configs,
          transformConfigs:
              initialTransformConfigs ?? TransformConfigs.empty(),
          child: StreamBuilder(
            stream: uiStream.stream,
            builder: (context, snapshot) {
              final imageSize = getValidSizeOrDefault(
                mainImageSize,
                editorBodySize,
              );
              final preview = ShaderFilteredWidget(
                shaderFilters: _previewShaderFilters,
                playTimeNotifier: videoController?.playTimeNotifier,
                imageSize: imageSize,
                sourceImage: source,
                child: FilteredWidget(
                  width: imageSize.width,
                  height: imageSize.height,
                  configs: configs,
                  image: editorImage,
                  videoPlayer: videoController?.videoPlayer,
                  blankSize: initConfigs.mainImageSize,
                  filters: appliedFilters,
                  tuneAdjustments: appliedTuneAdjustments,
                  blurFactor: appliedBlurFactor,
                ),
              );

              // 模糊工具：在预览图上叠加手势覆盖层控制模糊区域。
              if (_isBlurTool && current != null) {
                return SizedBox(
                  width: imageSize.width,
                  height: imageSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      preview,
                      Positioned.fill(
                        child: BlurOverlay(
                          bounds: imageSize,
                          params: _blurParamsFromState(current!),
                          onChanged: _onBlurGesture,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return preview;
            },
          ),
        ),
        );
      },
    );
  }

  Widget? _buildBottomNavBar() {
    if (configs.pixelsmixEditor.widgets.bottomBar != null) {
      return configs.pixelsmixEditor.widgets.bottomBar!.call(
        this,
        rebuildController.stream,
      );
    }
    return PixelsmixEditorBottombar(
      configs: configs.pixelsmixEditor,
      i18n: i18n.pixelsmixEditor,
      tool: tool,
      params: current?.params ?? const {},
      onChanged: onChanged,
      current: current,
      onShaderStateChanged: onShaderStateChanged,
      curveController:
          tool == ShaderTool.toneCurve ? _curveEditorController : null,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ShaderTool>('tool', tool))
      ..add(
        DiagnosticsProperty<ShaderFilterState?>('current', current),
      );
  }
}
