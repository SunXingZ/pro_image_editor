#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

// 4x5 颜色矩阵（与 ColorFilter.matrix 布局一致，20 个分量），
// 承载基础调节（亮度/对比度/饱和度/曝光/色相/色温/色调/褪色）合成后的矩阵。
layout(location = 2) uniform float u_m0;
layout(location = 3) uniform float u_m1;
layout(location = 4) uniform float u_m2;
layout(location = 5) uniform float u_m3;
layout(location = 6) uniform float u_m4;
layout(location = 7) uniform float u_m5;
layout(location = 8) uniform float u_m6;
layout(location = 9) uniform float u_m7;
layout(location = 10) uniform float u_m8;
layout(location = 11) uniform float u_m9;
layout(location = 12) uniform float u_m10;
layout(location = 13) uniform float u_m11;
layout(location = 14) uniform float u_m12;
layout(location = 15) uniform float u_m13;
layout(location = 16) uniform float u_m14;
layout(location = 17) uniform float u_m15;
layout(location = 18) uniform float u_m16;
layout(location = 19) uniform float u_m17;
layout(location = 20) uniform float u_m18;
layout(location = 21) uniform float u_m19;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    // highp：contrast 系数可达 ~3，lowp（±2）会溢出截断造成色块断裂。
    highp vec4 color = texture(u_texture_input, textureCoordinate);
    highp float r = color.r;
    highp float g = color.g;
    highp float b = color.b;
    highp float a = color.a;
    // clamp：ImageFilter.shader 的输出直接参与合成，越界负值/超 1 值
    // 以未定义方式混合（花屏），必须收敛到 0..1。
    fragColor = clamp(vec4(
        u_m0 * r + u_m1 * g + u_m2 * b + u_m3 * a + u_m4,
        u_m5 * r + u_m6 * g + u_m7 * b + u_m8 * a + u_m9,
        u_m10 * r + u_m11 * g + u_m12 * b + u_m13 * a + u_m14,
        u_m15 * r + u_m16 * g + u_m17 * b + u_m18 * a + u_m19
    ), 0.0, 1.0);
}
