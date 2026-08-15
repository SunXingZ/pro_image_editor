#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;
uniform sampler2D u_lut_texture;

layout(location = 2) uniform float inputLutSize;
layout(location = 3) uniform float inputIntensity;

// 注意：SkSL 不允许将 sampler2D 作为函数参数，故直接引用全局采样器 u_lut_texture。
vec4 sampleAs3DTexture(vec3 texCoord, float size) {
    float sliceSize = 1.0 / size;
    float slicePixelSize = sliceSize / size;
    float width = size - 1.0;
    float sliceInnerSize = slicePixelSize * width;
    float zSlice0 = floor(texCoord.z * width);
    float zSlice1 = min(zSlice0 + 1.0, width);
    float xOffset = slicePixelSize * 0.5 + texCoord.x * sliceInnerSize;
    float yRange = (texCoord.y * width + 0.5) / size;
    float s0 = xOffset + (zSlice0 * sliceSize);
    float s1 = xOffset + (zSlice1 * sliceSize);
    vec2 texPos1 = vec2(s0, yRange);
    vec2 texPos2 = vec2(s1, yRange);
    vec4 slice0Color = texture(u_lut_texture, texPos1);
    vec4 slice1Color = texture(u_lut_texture, texPos2);
    float zOffset = mod(texCoord.z * width, 1.0);
    return mix(slice0Color, slice1Color, zOffset);
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    vec4 originalColor = texture(u_texture_input, textureCoordinate);
    vec4 newColor = sampleAs3DTexture(originalColor.xyz, inputLutSize);
    fragColor = mix(originalColor, vec4(newColor.rgb, originalColor.w), inputIntensity);
}
