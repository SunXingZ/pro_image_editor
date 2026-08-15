#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

uniform sampler2D u_texture_input;
uniform sampler2D u_curve_texture;

layout(location = 0) uniform vec2 u_size;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    lowp vec4 textureColor = texture(u_texture_input, textureCoordinate);
    lowp float redCurveValue = texture(u_curve_texture, vec2(textureColor.r, 0.0)).r;
    lowp float greenCurveValue = texture(u_curve_texture, vec2(textureColor.g, 0.0)).g;
    lowp float blueCurveValue = texture(u_curve_texture, vec2(textureColor.b, 0.0)).b;

    fragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
}
