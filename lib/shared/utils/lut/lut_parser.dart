import 'dart:math' as math;

/// LUT（色彩查找表）解析结果。
///
/// [data] 为按行存储的 [r, g, b] 三元组列表，对应 RN 端 `chunk(data, 3)` 的结果。
class LutData {
  /// 构造一个 [LutData]，各字段均为必填。
  const LutData({
    required this.name,
    required this.type,
    required this.size,
    required this.data,
    required this.min,
    required this.max,
  });

  /// LUT 名称。
  final String name;

  /// 维度类型，`1D` 或 `3D`。
  final String type;

  /// 每个维度的采样数。
  final int size;

  /// 每行一个 [r, g, b] 三元组的列表。
  final List<List<double>> data;

  /// 输入取值范围下限。
  final List<double> min;

  /// 输入取值范围上限。
  final List<double> max;
}

/// 按空白字符切分字符串，同时处理引号与转义。
///
/// 算法与 RN 端 `splitOnSpaceHandleQuotesWithEscapes` 保持一致：
/// - 单双引号包裹的片段内部不会被切分；
/// - 引号内的 `\` 会转义下一个字符；
/// - 空输入返回 `['']`。
List<String> splitOnSpaceHandleQuotesWithEscapes(
  String str, [
  String splits = ' \t\n\r',
]) {
  final strings = <String>[];
  String? quoteType;
  var escape = false;
  var s = StringBuffer();
  for (var i = 0; i < str.length; ++i) {
    final c = str[i];
    if (escape) {
      escape = false;
      s.write(c);
    } else {
      if (quoteType != null) {
        // 位于引号内部
        if (c == quoteType) {
          quoteType = null;
          strings.add(s.toString());
          s = StringBuffer();
        } else if (c == '\\') {
          escape = true;
        } else {
          s.write(c);
        }
      } else {
        // 不在引号内
        if (splits.contains(c)) {
          if (s.isNotEmpty) {
            strings.add(s.toString());
            s = StringBuffer();
          }
        } else if (c == '"' || c == "'") {
          if (s.isNotEmpty) {
            // 引号出现在单词中间，按普通字符处理
            s.write(c);
          } else {
            quoteType = c;
          }
        } else {
          s.write(c);
        }
      }
    }
  }
  if (s.isNotEmpty || strings.isEmpty) {
    strings.add(s.toString());
  }
  return strings;
}

final _startWhitespaceRE = RegExp(r'^\s');
final _intRE = RegExp(r'^\d+$');
final _quotesRE = RegExp(r'^".*"$');

bool _isNum(String s) => _intRE.hasMatch(s);

/// 与 JS `parseFloat` 行为一致：无法解析时返回 NaN 而不是抛异常。
double _parseFloat(String s) => double.tryParse(s) ?? double.nan;

/// 与 JS `s.split(' ').map(parseFloat)` 一致。
List<double> _splitToNumbers(String s) =>
    s.split(' ').map(_parseFloat).toList();

/// 去掉首尾双引号。
///
/// 与 RN 端 `trimQuotes` 保持一致（含其 `substr(0, len - 2)` 的既有行为）。
String _trimQuotes(String s) =>
    _quotesRE.hasMatch(s) ? s.substring(0, s.length - 2) : s;

/// 将一维数值列表按每 3 个一组切分为 [r, g, b] 行。
List<List<double>> _chunk3(List<double> flat) {
  final result = <List<double>>[];
  for (var i = 0; i < flat.length; i += 3) {
    result.add([flat[i], flat[i + 1], flat[i + 2]]);
  }
  return result;
}

/// 解析 .csp 格式的 LUT 文本。
LutData parseCSP(String str) {
  final data = <double>[];
  var name = 'unknown';
  var type = '1D';
  var size = 0;
  var min = [0.0, 0.0, 0.0];
  var max = [1.0, 1.0, 1.0];

  final lines = str
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && !_startWhitespaceRE.hasMatch(s))
      .toList();

  // 检查文件头：首行必须是 CSPLUTV100，次行必须是 1D/3D
  type = lines.length > 1 ? lines[1] : '';
  if (lines.length < 2 ||
      lines[0] != 'CSPLUTV100' ||
      (type != '1D' && type != '3D')) {
    throw const FormatException('not CSP');
  }

  // 跳过元信息，直到遇到第一个纯数字行
  var lineNdx = 2;
  for (; lineNdx < lines.length; ++lineNdx) {
    final line = lines[lineNdx];
    if (_isNum(line)) {
      break;
    }
    if (line.startsWith('TITLE ')) {
      name = _trimQuotes(line.substring(6).trim());
    }
  }

  // 读取三段映射范围：输入/输出必须都是 0..1
  for (var i = 0; i < 3; ++i) {
    ++lineNdx;
    final input = _splitToNumbers(lines[lineNdx++]);
    final output = _splitToNumbers(lines[lineNdx++]);
    if (input.length != 2 ||
        output.length != 2 ||
        input[0] != 0 ||
        input[1] != 1 ||
        output[0] != 0 ||
        output[1] != 1) {
      throw const FormatException('mapped ranges not support');
    }
  }

  // 读取尺寸：三通道必须一致，仅支持立方体
  final sizes = _splitToNumbers(lines[lineNdx++]);
  if (sizes[0] != sizes[1] || sizes[0] != sizes[2]) {
    throw const FormatException('only cubic sizes supported');
  }
  size = sizes[0].round();

  // 读取数据：每行恰好 3 个数值
  for (; lineNdx < lines.length; ++lineNdx) {
    final parts = _splitToNumbers(lines[lineNdx]);
    if (parts.length != 3) {
      throw const FormatException('malformed file');
    }
    data.addAll(parts);
  }

  return LutData(
    name: name,
    type: type,
    size: size,
    data: _chunk3(data),
    min: min,
    max: max,
  );
}

/// 解析 .cube 格式的 LUT 文本。
LutData parseCUBE(String str) {
  final data = <double>[];
  var name = 'unknown';
  var type = '1D';
  var size = 0;
  var min = [0.0, 0.0, 0.0];
  var max = [1.0, 1.0, 1.0];

  final lines = str.split('\n');
  for (final origLine in lines) {
    final hashNdx = origLine.indexOf('#');
    final line = hashNdx >= 0 ? origLine.substring(0, hashNdx) : origLine;
    final parts = splitOnSpaceHandleQuotesWithEscapes(line);
    switch (parts[0].toUpperCase()) {
      case 'TITLE':
        name = parts[1];
        break;
      case 'LUT_1D_SIZE':
        size = int.parse(parts[1]);
        type = '1D';
        break;
      case 'LUT_3D_SIZE':
        size = int.parse(parts[1]);
        type = '3D';
        break;
      case 'DOMAIN_MIN':
        min = parts.sublist(1).map(_parseFloat).toList();
        break;
      case 'DOMAIN_MAX':
        max = parts.sublist(1).map(_parseFloat).toList();
        break;
      default:
        if (parts.length == 3) {
          data.addAll(parts.map(_parseFloat));
        }
        break;
    }
  }

  // 未声明 size 时根据数据长度推断
  if (size == 0) {
    size = type == '1D'
        ? data.length ~/ 3
        : math.pow(data.length / 3, 1 / 3).round();
  }

  return LutData(
    name: name,
    type: type,
    size: size,
    data: _chunk3(data),
    min: min,
    max: max,
  );
}

const _parsers = <String, LutData Function(String)>{
  'cube': parseCUBE,
  'csp': parseCSP,
};

/// 按 [format] 解析 LUT 文本，支持 `'cube'` / `'csp'`。
///
/// 其它格式抛出 [ArgumentError]。
LutData parse(String str, [String format = 'cube']) {
  final parser = _parsers[format.toLowerCase()];
  if (parser == null) {
    throw ArgumentError('no parser for format: $format');
  }
  return parser(str);
}
