#version 300 es
precision mediump float;

out vec4 fragColor;

uniform float time;
uniform vec2 resolution;
uniform sampler2D prevPass;
uniform sampler2D spectrum;
uniform sampler2D waveform;
uniform sampler2D midiControls;

const int numLines = 1;
const float amplitude = 0.8;
const float thickness_px = 2.5;
const vec3 lineColor = vec3(1.0);
const vec3 bgColor = vec3(0.0);

mat3 rotationMatrixY(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

mat3 rotationMatrixX(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

vec2 catmullRom(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return 0.5 * (
        (2.0 * p1) +
        (-p0 + p2) * t +
        (2.0*p0 - 5.0*p1 + 4.0*p2 - p3) * t2 +
        (-p0 + 3.0*p1 - 3.0*p2 + p3) * t3
    );
}


float waveformY(int idx) {
    const int NUM_POINTS = 128;
    float x = float(idx) / float(NUM_POINTS - 1);
    float y = texture(waveform, vec2(x, 0.5)).r;
    return 0.5 + (y - 0.5);
}


float readMidiControl(int index) {
    int width = textureSize(midiControls, 0).x;
    float u = (float(index) + 0.5) / float(width);
    float v = 0.5;
    return texture(midiControls, vec2(u, v)).r;
}

void main() {
    vec2 r = resolution;
    vec2 uv = gl_FragCoord.xy / r;
    vec4 frag = texture(prevPass, uv);
    
    for (int i = 0; i < numLines; ++i) {
        float offset = (numLines == 1 
                        ? 0.5
                        : float(i) / float(numLines - 1));
        offset = mix(0.1, 0.9, offset);
        float yCenter = offset;
    
        float x0 = uv.x;
        float x1 = uv.x + 1.0 / resolution.x;
    
        float y0 = texture(waveform, vec2(x0, 0.5)).r;
        float y1 = texture(waveform, vec2(x1, 0.5)).r;
    
        y0 = yCenter + (y0 - 0.5) * amplitude;
        y1 = yCenter + (y1 - 0.5) * amplitude;
    
        vec2 a = vec2(x0, y0);
        vec2 b = vec2(x1, y1);
        vec2 ab = b - a;
        float t = clamp(dot(uv - a, ab) / dot(ab, ab), 0.0, 1.0);
        vec2 closest = a + ab * t;
        float dist = length(uv - closest);
    
        float thickness = thickness_px / resolution.y;
        float alpha = 1. - step(thickness, dist);
    
        frag += vec4(mix(bgColor, lineColor, alpha), 1.0);
    }
    
    fragColor = frag;
}