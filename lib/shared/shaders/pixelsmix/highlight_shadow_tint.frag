#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

layout(location = 2) uniform float inputShadowTintIntensity;
layout(location = 3) uniform float inputHighlightTintIntensity;
layout(location = 4) uniform vec3 inputShadowTintColor;
layout(location = 7) uniform vec3 inputHighlightTintColor;

const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    lowp vec4 textureColor = texture(u_texture_input, textureCoordinate);
    highp float luminance = dot(textureColor.rgb, luminanceWeighting);

    highp vec4 shadowResult = mix(textureColor, max(textureColor, vec4(mix(inputShadowTintColor.rgb, textureColor.rgb, luminance), textureColor.a)), inputShadowTintIntensity);
    highp vec4 highlightResult = mix(textureColor, min(shadowResult, vec4(mix(shadowResult.rgb, inputHighlightTintColor.rgb, luminance), textureColor.a)), inputHighlightTintIntensity);

    fragColor = vec4(mix(shadowResult.rgb, highlightResult.rgb, luminance), textureColor.a);
}
