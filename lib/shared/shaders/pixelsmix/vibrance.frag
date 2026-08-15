#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

layout(location = 2) uniform float inputFactor;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    lowp vec4 color = texture(u_texture_input, textureCoordinate);
    lowp float average = (color.r + color.g + color.b) / 3.0;
    lowp float mx = max(color.r, max(color.g, color.b));
    lowp float amt = (mx - average) * (-inputFactor * 3.0);
    color.rgb = mix(color.rgb, vec3(mx), amt);
    fragColor = color;
}
