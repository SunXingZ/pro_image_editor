#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

// 三波段 [色相0~1, 饱和度0~1]（renderer 已归一化）。
layout(location = 2) uniform float inputShadowHue;
layout(location = 3) uniform float inputShadowSaturation;
layout(location = 4) uniform float inputMidtoneHue;
layout(location = 5) uniform float inputMidtoneSaturation;
layout(location = 6) uniform float inputHighlightHue;
layout(location = 7) uniform float inputHighlightSaturation;

// sRGB → CIELAB（D65 白点）。分离色调在感知均匀空间内进行：
// 亮度 L 严格不变，饱和度拉满时该区颜色完全变为所选色相的纯色调，
// 与 MIX / Lightroom 分离色调观感一致，且不会产生荧光亮度失真。
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
    // 保证与 rgbToLab 严格互逆。
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

// 色相(0~1) → Lab a/b 单位方向（半径 70 接近对应色相的色域边缘）。
// 色相环：0°/360° 红(+a) → 90° 黄(+b) → 180° 绿(-a) → 270° 蓝(-b)。
vec2 hueToAb(float hue) {
    float angle = hue * 6.28318530718;
    return vec2(cos(angle), sin(angle)) * 70.0;
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    vec4 textureColor = texture(u_texture_input, textureCoordinate);

    // 相对亮度（Rec.709）分区；平滑带覆盖更宽，保证拉满时染色明显。
    float lum = dot(textureColor.rgb, vec3(0.2125, 0.7154, 0.0721));
    float wShadow = 1.0 - smoothstep(0.10, 0.50, lum);
    float wHighlight = smoothstep(0.50, 0.90, lum);
    float wMidtone = smoothstep(0.05, 0.35, lum) *
                     (1.0 - smoothstep(0.65, 0.95, lum));

    vec3 lab = rgbToLab(textureColor.rgb);

    // 分离色调：各波段把 a/b 向「色相方向的目标色调」混合，
    // 混合权重 = 分区权重 × 饱和度（饱和度 0 严格恒等，1 完全替换）；
    // 按 阴影 → 中间调 → 高光 顺序叠加，亮部波段优先。
    float a = lab.y;
    float b = lab.z;
    vec2 ab = hueToAb(inputShadowHue);
    float w = wShadow * inputShadowSaturation;
    a = mix(a, ab.x, w);
    b = mix(b, ab.y, w);
    ab = hueToAb(inputMidtoneHue);
    w = wMidtone * inputMidtoneSaturation;
    a = mix(a, ab.x, w);
    b = mix(b, ab.y, w);
    ab = hueToAb(inputHighlightHue);
    w = wHighlight * inputHighlightSaturation;
    a = mix(a, ab.x, w);
    b = mix(b, ab.y, w);

    vec3 result = labToRgb(vec3(lab.x, a, b));
    fragColor = vec4(clamp(result, 0.0, 1.0), textureColor.w);
}
