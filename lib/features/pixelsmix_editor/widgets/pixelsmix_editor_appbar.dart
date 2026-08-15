import 'package:flutter/material.dart';

import '/core/models/editor_configs/pixelsmix_editor_configs.dart';
import '/core/models/i18n/i18n_pixelsmix_editor.dart';

/// Pixelsmix 编辑器的 AppBar：返回 + 完成（与其它子编辑器风格一致）。
class PixelsmixEditorAppbar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Creates a [PixelsmixEditorAppbar].
  const PixelsmixEditorAppbar({
    super.key,
    required this.configs,
    required this.i18n,
    required this.onClose,
    required this.onDone,
  });

  /// Pixelsmix 编辑器配置。
  final PixelsmixEditorConfigs configs;

  /// 本地化文案。
  final I18nPixelsmixEditor i18n;

  /// 关闭回调。
  final Function() onClose;

  /// 完成回调。
  final Function() onDone;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: configs.style.appBarBackground,
      foregroundColor: configs.style.appBarColor,
      actions: [
        IconButton(
          tooltip: i18n.back,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(configs.icons.backButton),
          onPressed: onClose,
        ),
        const Spacer(),
        IconButton(
          tooltip: i18n.done,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(configs.icons.applyChanges),
          iconSize: 28,
          onPressed: onDone,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
