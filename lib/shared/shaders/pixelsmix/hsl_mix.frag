#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

layout(location = 0) uniform vec2 u_size;

uniform sampler2D u_texture_input;

#define orange (0.08281581103801725)
#define yellow (0.16666667163372034)
#define green (0.3333333432674407)
#define lightgreen (0.5)
#define blue (0.6666666865348814)
#define purple (0.7494824528694153)
#define fuchsia (0.8333333134651184)

layout(location = 2) uniform vec3 inputRedShift;
layout(location = 5) uniform vec3 inputOrangeShift;
layout(location = 8) uniform vec3 inputYellowShift;
layout(location = 11) uniform vec3 inputGreenShift;
layout(location = 14) uniform vec3 inputLightgreenShift;
layout(location = 17) uniform vec3 inputBlueShift;
layout(location = 20) uniform vec3 inputPurpleShift;
layout(location = 23) uniform vec3 inputFuchsiaShift;

vec3 RGB2HSV(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 HSV2RGB(vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);
  rgb = rgb*rgb*(3.0-2.0*rgb);
  return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 smoothTreatment(vec3 hsv, float hueEdge0, float hueEdge1, vec3 shiftEdge0, vec3 shiftEdge1) {
  float smoothedHue = smoothstep(hueEdge0, hueEdge1, hsv.x);
  float hue = hsv.x + (shiftEdge0.x + ((shiftEdge1.x - shiftEdge0.x) * smoothedHue));
  float sat = hsv.y * (shiftEdge0.y + ((shiftEdge1.y - shiftEdge0.y) * smoothedHue));
  float lum = hsv.z * (shiftEdge0.z + ((shiftEdge1.z - shiftEdge0.z) * smoothedHue));
  hue = clamp(hue, hueEdge0, hueEdge1);
  sat = clamp(sat, 0.0, 1.0);
  lum = clamp(lum, 0.0, 1.0);
  vec3 dst = vec3(hue, sat, lum);
  return mix(hsv, dst, hsv.y);
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / u_size;
    vec4 src = texture(u_texture_input, textureCoordinate);
    vec3 hsv = RGB2HSV(src.rgb);

    if (hsv.x < orange) {
        hsv = smoothTreatment(hsv, 0.0, orange, inputRedShift, inputOrangeShift);
    } else if (hsv.x >= orange && hsv.x < yellow) {
        hsv = smoothTreatment(hsv, orange, yellow, inputOrangeShift, inputYellowShift);
    } else if (hsv.x >= yellow && hsv.x < green) {
        hsv = smoothTreatment(hsv, yellow, green, inputYellowShift, inputGreenShift);
    } else if (hsv.x >= green && hsv.x < lightgreen) {
        hsv = smoothTreatment(hsv, green, lightgreen, inputGreenShift, inputLightgreenShift);
    } else if (hsv.x >= lightgreen && hsv.x < blue) {
        hsv = smoothTreatment(hsv, lightgreen, blue, inputLightgreenShift, inputBlueShift);
    } else if (hsv.x >= blue && hsv.x < purple) {
        hsv = smoothTreatment(hsv, blue, purple, inputBlueShift, inputPurpleShift);
    } else if (hsv.x >= purple && hsv.x < fuchsia) {
        hsv = smoothTreatment(hsv, purple, fuchsia, inputPurpleShift, inputFuchsiaShift);
    } else {
        hsv = smoothTreatment(hsv, fuchsia, 1.0, inputFuchsiaShift, inputRedShift);
    }

    fragColor = vec4(HSV2RGB(hsv), 1.0);
}
