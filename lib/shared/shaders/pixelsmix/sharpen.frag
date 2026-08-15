#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

layout(location = 2) uniform float inputFactor;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    vec2 step = 1.0 / u_size;

    vec3 texA = texture(u_texture_input, textureCoordinate + vec2(-step.x, -step.y) * 1.5).rgb;
    vec3 texB = texture(u_texture_input, textureCoordinate + vec2( step.x, -step.y) * 1.5).rgb;
    vec3 texC = texture(u_texture_input, textureCoordinate + vec2(-step.x,  step.y) * 1.5).rgb;
    vec3 texD = texture(u_texture_input, textureCoordinate + vec2( step.x,  step.y) * 1.5).rgb;

    vec3 around = 0.25 * (texA + texB + texC + texD);
    vec3 center  = texture(u_texture_input, textureCoordinate).rgb;
    vec3 col = center + (center - around) * inputFactor;

    fragColor = vec4(col, 1.0);
}
