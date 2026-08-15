#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

layout(location = 2) uniform float inputHazeDistance;
layout(location = 3) uniform float inputSlope;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    highp vec4 color = vec4(1.0);
    highp float d = textureCoordinate.y * inputSlope + inputHazeDistance;
    highp vec4 c = texture(u_texture_input, textureCoordinate);
    c = (c - d * color) / (1.0 - d);
    fragColor = c;
}
