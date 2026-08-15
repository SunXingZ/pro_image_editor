#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

layout(location = 2) uniform mat4 inputColorMatrix;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    lowp vec4 textureColor = texture(u_texture_input, textureCoordinate);
    fragColor = textureColor * inputColorMatrix;
}
