#version 300 es
precision highp float;

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;
uniform float bpm;
uniform sampler2D prevPass;
uniform sampler2D midiControls;

float hashf(float n) { return fract(sin(n) * 43758.5453123); }

float readMidiControl(int index) {
    int width = textureSize(midiControls, 0).x;
    float u = (float(index) + 0.5) / float(width);
    float v = 0.5;
    return texture(midiControls, vec2(u, v)).r;
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 src = texture(prevPass, uv);

    const int STRIP_COUNT = 6;
    float INVERT_PROB = 1. * readMidiControl(73);
    
    float beatPeriod = 60.0 / bpm;
    float beatPhase = mod(time, beatPeriod) / beatPeriod;
 
    float fy = uv.y * float(STRIP_COUNT);
    float stripIndexF = floor(fy);
    float localY = fract(fy);

    float tick = floor(time * beatPhase);
    float baseSeed = stripIndexF * 17.23 + tick * 13.7;

    float r = hashf(baseSeed + 0.71);
    bool stripInvert = (r < INVERT_PROB);

    if (stripInvert)
    {
        fragColor = vec4(vec3(1.0) - src.xyz, src.a);
    } 
    else
    {
        fragColor = src;
    }

}