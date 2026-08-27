import 'package:flutter/material.dart';

/// HSL 混色工具的 8 个色相基准色（与 RN `HslMix.colorsMap` 一致）。
///
/// 同时用作 HSL 色带选择、鲜艳度滑杆的轨道渐变等处的共享色板。
const List<Color> kHslBandColors = [
  Color(0xFFFF0000), // red
  Color(0xFFFFA500), // orange
  Color(0xFFFFFF00), // yellow
  Color(0xFF00FF00), // green
  Color(0xFF90EE90), // lightgreen
  Color(0xFF0000FF), // blue
  Color(0xFF800080), // purple
  Color(0xFFFF00FF), // fuchsia
];
