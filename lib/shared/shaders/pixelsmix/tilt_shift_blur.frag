#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;
uniform sampler2D u_blurred_texture;

layout(location = 2) uniform float inputTopFocusLevel;
layout(location = 3) uniform float inputBottomFocusLevel;
layout(location = 4) uniform float inputFocusFallOffRate;

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    lowp vec4 sharpImageColor = texture(u_texture_input, textureCoordinate);
    lowp vec4 blurredImageColor = texture(u_blurred_texture, textureCoordinate);

    lowp float blurIntensity = 1.0 - smoothstep(inputTopFocusLevel - inputFocusFallOffRate, inputTopFocusLevel, textureCoordinate.y);
    blurIntensity += smoothstep(inputBottomFocusLevel, inputBottomFocusLevel + inputFocusFallOffRate, textureCoordinate.y);

    fragColor = mix(sharpImageColor, blurredImageColor, blurIntensity);
}
