#version 300 es
precision highp float;

uniform sampler2D prevPass;
uniform vec2 resolution;
uniform sampler2D midiControls;

out vec4 fragColor;

const int BLOOM_SAMPLES = 8;
const int BLOOM_RINGS = 6;
const float BLOOM_RADIUS = 30.0;

float gaussian(float r, float sigma) {
    return exp(-r * r / (2.0 * sigma * sigma));
}

float readMidiControl(int index) {
    int width = textureSize(midiControls, 0).x;
    float u = (float(index) + 0.5) / float(width);
    float v = 0.5;
    return texture(midiControls, vec2(u, v)).r;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5) / resolution;
    vec2 texel = 1.0 / resolution;
    vec4 sum = vec4(0.0);
    float weightSum = 0.0;

    for (int ring = 0; ring < BLOOM_RINGS; ++ring) {
        float radius = float(ring + 1) / float(BLOOM_RINGS) * BLOOM_RADIUS;
        float sigma = BLOOM_RADIUS * 0.5;
        float baseWeight = gaussian(radius, sigma);

        for (int i = 0; i < BLOOM_SAMPLES; ++i) {
            float angle = float(i) * 6.2831853 / float(BLOOM_SAMPLES); // 0~2π
            vec2 offset = vec2(cos(angle), sin(angle)) * radius * texel;
            float weight = baseWeight;
            sum += texture(prevPass, uv + offset) * weight;
            weightSum += weight;
        }
    }
    vec4 bloom = sum / weightSum;

    vec4 base = texture(prevPass, uv);
    fragColor = base + bloom * readMidiControl(71) * 1.3;
}