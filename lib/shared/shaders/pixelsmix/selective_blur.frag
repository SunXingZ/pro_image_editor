#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;
uniform sampler2D u_blurred_texture;

layout(location = 2) uniform float inputExcludeCircleRadius;
layout(location = 3) uniform vec2 inputExcludeCirclePoint;
layout(location = 5) uniform float inputExcludeBlurSize;
layout(location = 6) uniform float inputAspectRatio;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    lowp vec4 sharpImageColor = texture(u_texture_input, textureCoordinate);
    lowp vec4 blurredImageColor = texture(u_blurred_texture, textureCoordinate);

    highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * inputAspectRatio + 0.5 - 0.5 * inputAspectRatio));
    highp float distanceFromCenter = distance(inputExcludeCirclePoint, textureCoordinateToUse);

    fragColor = mix(sharpImageColor, blurredImageColor, smoothstep(inputExcludeCircleRadius - inputExcludeBlurSize, inputExcludeCircleRadius, distanceFromCenter));
}
