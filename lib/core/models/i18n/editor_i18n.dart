import 'dart:ui';

import 'i18n.dart';

/// 按系统语言构建编辑器完整的 [I18n] 翻译。
///
/// 支持 en / ja / ko / vi / zh-Hans / zh-HK（与主项目 iOS 工程 locale 配置一致），
/// en-AU / en-GB / en-IN 等英文变体与其余未知语言回退英文默认值。
///
/// 后续在库内新增 i18n 字段时，需同步补齐本目录下各语言文件与默认英文
/// （见主项目 docs/国际化规范.md）。
I18n buildEditorI18n(Locale locale) {
  final lang = locale.languageCode.toLowerCase();
  if (lang == 'zh') {
    // zh-Hant / zh-HK / zh-TW / zh-MO 使用繁体（香港用语），其余使用简体
    final traditional = locale.scriptCode == 'Hant' ||
        const {'HK', 'TW', 'MO'}.contains(locale.countryCode);
    return traditional ? buildZhHkI18n() : buildZhHansI18n();
  }
  switch (lang) {
    case 'ja':
      return buildJaI18n();
    case 'ko':
      return buildKoI18n();
    case 'vi':
      return buildViI18n();
    default:
      return const I18n();
  }
}
