#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

// 三波段 CMY 归一色条值（-1~1，+青/+品红/+黄，负向为红/绿/蓝）。
layout(location = 2) uniform vec3 inputShadowsShift;
layout(location = 5) uniform vec3 inputMidtonesShift;
layout(location = 8) uniform vec3 inputHighlightsShift;
layout(location = 11) uniform float inputPreserveLuminosity;

// sRGB → CIELAB（D65 白点）。
// 色彩平衡在感知均匀空间内偏移 a/b 轴：亮度 L 严格不变，偏移量在视觉上
// 均匀分布，从数学上避免 RGB 加法在通道边界钳位导致的荧光纯色 ——
// 与 Photoshop / MIX 的色彩平衡观感同源。
vec3 rgbToLab(vec3 c) {
    vec3 lin = mix(c / 12.92,
                   pow((c + 0.055) / 1.055, vec3(2.4)),
                   step(vec3(0.04045), c));
    float x = dot(lin, vec3(0.4124, 0.3576, 0.1805)) / 0.95047;
    float y = dot(lin, vec3(0.2126, 0.7152, 0.0722));
    float z = dot(lin, vec3(0.0193, 0.1192, 0.9505)) / 1.08883;
    vec3 xyz = vec3(x, y, z);
    vec3 f = mix(7.787 * xyz + 16.0 / 116.0,
                 pow(max(xyz, vec3(1e-5)), vec3(1.0 / 3.0)),
                 step(vec3(0.008856), xyz));
    return vec3(116.0 * f.y - 16.0, 500.0 * (f.x - f.y), 200.0 * (f.y - f.z));
}

vec3 labToRgb(vec3 lab) {
    float fy = (lab.x + 16.0) / 116.0;
    vec3 f = vec3(fy + lab.y / 500.0, fy, fy - lab.z / 200.0);
    // 逆变换分支阈值为 f 值域的 6/29（对应 xyz 域的 0.008856），
    // 保证与 rgbToLab 严格互逆（否则暗色像素往返后亮度漂移）。
    vec3 fr = mix((f - 16.0 / 116.0) / 7.787, f * f * f,
                  step(vec3(6.0 / 29.0), f));
    vec3 xyz = vec3(fr.x * 0.95047, fr.y, fr.z * 1.08883);
    vec3 lin = vec3(
        dot(xyz, vec3(3.2406, -1.5372, -0.4986)),
        dot(xyz, vec3(-0.9689, 1.8758, 0.0415)),
        dot(xyz, vec3(0.0557, -0.2040, 1.0570)));
    return mix(12.92 * lin,
               1.055 * pow(max(lin, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055,
               step(vec3(0.0031308), lin));
}

// CMY 色条 → Lab a/b 偏移。满值（±1）约对应 ±150 的感知偏移（强染色档），
// 青=(-a,-b)、红=(+a,+b少量)、品红=(+a)、绿=(-a)、黄=(+b)、蓝=(-b)。
vec2 cmyToAbShift(vec3 cmy) {
    float da = cmy.y * 0.45 - cmy.x * 0.32 - cmy.z * 0.05;
    float db = cmy.z * 0.45 - cmy.x * 0.28;
    return vec2(da, db) * 150.0;
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    vec4 textureColor = texture(u_texture_input, textureCoordinate);

    // 分区权重：按像素整体亮度（HSL 明度）划分阴影/中间调/高光，
    // 同一权重作用于整像素，与 MIX / Photoshop 一致。
    float lum = (max(max(textureColor.r, textureColor.g), textureColor.b) +
                 min(min(textureColor.r, textureColor.g), textureColor.b)) / 2.0;

    const float a0 = 0.25;
    const float b0 = 0.333;
    float wShadow = clamp((lum - b0) / -a0 + 0.5, 0.0, 1.0);
    float wMidtone = clamp((lum - b0) / a0 + 0.5, 0.0, 1.0) *
                     clamp((lum + b0 - 1.0) / -a0 + 0.5, 0.0, 1.0);
    float wHighlight = clamp((lum + b0 - 1.0) / a0 + 0.5, 0.0, 1.0);

    vec2 abShift = cmyToAbShift(inputShadowsShift) * wShadow +
                   cmyToAbShift(inputMidtonesShift) * wMidtone +
                   cmyToAbShift(inputHighlightsShift) * wHighlight;

    if (inputPreserveLuminosity > 0.5) {
        vec3 lab = rgbToLab(textureColor.rgb);
        vec3 shifted = vec3(lab.x, lab.y + abShift.x, lab.z + abShift.y);
        fragColor = vec4(clamp(labToRgb(shifted), 0.0, 1.0), textureColor.w);
    } else {
        // 亮度保持关闭：退回 RGB 加法（UI 恒为保留路径，此处仅兜底）。
        vec3 shift = vec3(-inputShadowsShift.x, -inputShadowsShift.y,
                          -inputShadowsShift.z) /
                         2.0 * wShadow +
                     vec3(-inputMidtonesShift.x, -inputMidtonesShift.y,
                          -inputMidtonesShift.z) /
                         2.0 * wMidtone +
                     vec3(-inputHighlightsShift.x, -inputHighlightsShift.y,
                          -inputHighlightsShift.z) /
                         2.0 * wHighlight;
        fragColor = vec4(clamp(textureColor.rgb + shift, 0.0, 1.0), textureColor.w);
    }
}
