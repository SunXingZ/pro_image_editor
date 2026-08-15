#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

layout(location = 2) uniform vec2 inputVignetteCenter;
layout(location = 4) uniform vec3 inputVignetteColor;
layout(location = 7) uniform float inputVignetteStart;
layout(location = 8) uniform float inputVignetteEnd;

float sstep(float lower, float upper, float x) {
    float t = clamp((x - lower) / (upper - lower), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    vec4 texColor = texture(u_texture_input, textureCoordinate);
    lowp float d = distance(textureCoordinate, inputVignetteCenter);
    lowp float percent = sstep(inputVignetteStart, inputVignetteEnd, d);
    fragColor = vec4(mix(texColor.rgb, inputVignetteColor, percent), texColor.a);
}
