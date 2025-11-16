#version 300 es
precision mediump float;

out vec4 fragColor;

uniform float time;
uniform float bpm;
uniform vec2 resolution;
uniform sampler2D prevPass;
uniform sampler2D midiControls;

float readMidiControl(int index) {
    int width = textureSize(midiControls, 0).x;
    float u = (float(index) + 0.5) / float(width);
    float v = 0.5;
    return texture(midiControls, vec2(u, v)).r;
}

#define PI 3.141596

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    float beatPeriod = 60.0 / bpm;
    float beatPhase = mod(time, beatPeriod) / beatPeriod;

    float intensity = 0.5 * clamp(tan(beatPhase * PI), -5., 5.) * readMidiControl(70);
    
    vec2 center = vec2(0.5, 0.5);

    vec2 dir = uv - center;
    float dist = length(dir);
    float aberrBase = intensity * pow(dist, 1.3);

    float r_offset = aberrBase * 1.0;
    float g_offset = aberrBase * 0.5;
    float b_offset = -aberrBase * 1.0;

    float r = texture(prevPass, uv + dir * r_offset).r;
    float g = texture(prevPass, uv + dir * g_offset).g;
    float b = texture(prevPass, uv + dir * b_offset).b;

    fragColor = vec4(r, g, b, 1.0);
}