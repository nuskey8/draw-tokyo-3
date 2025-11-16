#version 300 es
precision highp float;

uniform float time;
uniform float bpm;
uniform sampler2D prevPass;
uniform vec2 resolution;
uniform sampler2D midiControls;

#define PI 3.141596

out vec4 outColor;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float readMidiControl(int index) {
    int width = textureSize(midiControls, 0).x;
    float u = (float(index) + 0.5) / float(width);
    float v = 0.5;
    return texture(midiControls, vec2(u, v)).r;
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    float beatPeriod = 60.0 / bpm;
    float beatPhase = mod(time, beatPeriod) / beatPeriod;
    float intensity = 0.5 * clamp(tan(beatPhase * PI), -5., 5.) * readMidiControl(72);

    float jitterStrength = 20.0 * intensity;

    float angle = rand(gl_FragCoord.xy) * 2. * PI;
    float radius = rand(gl_FragCoord.xy + 0.123) * jitterStrength / resolution.x;

    vec2 jitter = vec2(cos(angle), sin(angle)) * radius;

    vec2 jitteredUV = uv + jitter;

    vec4 color = texture(prevPass, jitteredUV);
    outColor = color;
}