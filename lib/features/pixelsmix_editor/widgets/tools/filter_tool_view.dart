import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/models/i18n/i18n_pixelsmix_editor.dart';
import '/shared/widgets/edit_slider.dart';

import '../../models/lut_filter_catalog.dart';
import '../../models/shader_filter_state.dart';
import '../shader_filtered_widget.dart';

/// 滤镜工具面板（内置 LUT 预设画廊，替代原颜色矩阵）。
///
/// 顶部按分类切换（首个为「原图」），下方网格排布内置 LUT 滤镜；
/// 每个滤镜使用 [previewSource]（当前编辑图片）+ LUT shader 渲染真实缩略图，
/// 源图未就绪时回退为色块。滤镜不显示名称；选中后可调强度（0~100）。
///
/// 参数结构：`{'asset': String, 'preset': String, 'size': int,
///   'intensity': 0..100, 'enable': true}`；点「原图」清空为 `{}`（恒等）。
class FilterToolView extends StatefulWidget {
  /// Creates a [FilterToolView].
  const FilterToolView({
    super.key,
    required this.params,
    required this.onChanged,
    required this.i18n,
    this.previewSource,
    this.categories = const [],
  });

  /// 当前参数。
  final Map<String, dynamic> params;

  /// 参数变化回调。
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// 本地化文案。
  final I18nPixelsmixEditor i18n;

  /// 源图就绪通知器（当前编辑图片）。
  final ValueListenable<ui.Image?>? previewSource;

  /// 内置 LUT 滤镜分类（宿主注入，分类名已本地化）。
  final List<LutFilterCategory> categories;

  @override
  State<FilterToolView> createState() => _FilterToolViewState();
}

class _FilterToolViewState extends State<FilterToolView> {
  /// 当前分类 key（空字符串表示「原图」）。
  String _classify = '';

  String? get _preset => widget.params['preset'] as String?;

  double get _intensity =>
      (widget.params['intensity'] as num?)?.toDouble() ?? 100;

  @override
  void initState() {
    super.initState();
    // 默认选中第一个分类
    if (widget.categories.isNotEmpty) _classify = widget.categories.first.key;
  }

  @override
  void didUpdateWidget(covariant FilterToolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_classify.isEmpty && widget.categories.isNotEmpty) {
      _classify = widget.categories.first.key;
    }
  }

  List<LutFilterPreset> get _visibleFilters {
    if (_classify.isEmpty) return const [];
    for (final c in widget.categories) {
      if (c.key == _classify) return c.filters;
    }
    return const [];
  }

  void _applyPreset(LutFilterPreset preset) {
    widget.onChanged({
      ...widget.params,
      'asset': preset.asset,
      'preset': preset.id,
      'size': preset.size,
      'intensity': _intensity,
      'enable': true,
    });
  }

  void _applyNone() {
    // 清空参数 = 恒等（无滤镜），预览回到原图
    widget.onChanged(const {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 分类切换（首个为原图，横向可滚动避免小屏溢出）
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChip('', widget.i18n.filterOriginal, isNone: true),
                for (final c in widget.categories) _buildChip(c.key, c.name),
              ],
            ),
          ),
        ),
        // 预设网格（仅当前分类，懒加载；定宽缩略图保证整齐）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 116),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in _visibleFilters)
                    _buildPresetTile(preset),
                ],
              ),
            ),
          ),
        ),
        // 强度滑杆（选中滤镜后显示，部分滤镜满强度过重可调低）
        if (_preset != null && _preset!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: EditSlider(
              label: widget.i18n.intensity,
              value: _intensity.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 200,
              valueText: '${_intensity.round()}%',
              textColor: Colors.white70,
              onChanged: (v) => widget.onChanged({
                ...widget.params,
                'intensity': v,
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String key, String label, {bool isNone = false}) {
    final selected = _classify == key;
    return GestureDetector(
      onTap: () {
        setState(() => _classify = key);
        // 「原图」同时清空滤镜参数（回落到恒等）
        if (isNone) _applyNone();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? const Color(0xFFFFD700) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFFFD700) : Colors.white70,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetTile(LutFilterPreset preset) {
    final selected = _preset == preset.id;
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A2A2A) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFFFD700) : const Color(0xFF333333),
            width: selected ? 1.5 : 1,
          ),
        ),
        // 仅缩略图，定宽 44px，网格整齐
        child: _buildThumbnail(preset),
      ),
    );
  }

  /// 缩略图：当前编辑图片 + LUT shader；源图未就绪时回退色块。
  ///
  /// 仅渲染当前分类的缩略图（切换分类才重建），且每个 LUT 纹理由
  /// [ShaderRenderer] 全局缓存，避免内存随分类累积。
  Widget _buildThumbnail(LutFilterPreset preset) {
    const size = 44.0;
    final notifier = widget.previewSource;
    if (notifier == null) return _fallbackTile(preset, size);
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: notifier,
      builder: (context, image, child) {
        if (image == null) return _fallbackTile(preset, size);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: size,
            height: size,
            child: ShaderFilteredWidget(
              shaderFilters: [
                ShaderFilterState(
                  tool: ShaderTool.filter,
                  params: {
                    'asset': preset.asset,
                    'size': preset.size,
                    'intensity': 100.0,
                    'enable': true,
                  },
                ),
              ],
              imageSize: const Size(size, size),
              child: RawImage(
                image: image,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackTile(LutFilterPreset preset, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.lerp(
          const Color(0xFF2A2A2A),
          Colors.white,
          (preset.id.hashCode.abs() % 20) / 100,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
