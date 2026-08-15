#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

layout(location = 2) uniform float inputAmount;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    vec4 color = texture(u_texture_input, textureCoordinate);
    float diff = (rand(textureCoordinate) - 0.5) * inputAmount;
    color.r += diff;
    color.g += diff;
    color.b += diff;
    fragColor = color;
}
