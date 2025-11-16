#version 300 es
precision highp float;

uniform vec2 resolution;
uniform float time;
uniform float bpm;
uniform float audioLevel;

out vec4 outColor;

const int TILES_X = 1;
const int TILES_Y = 1;
const float CAMERA_Z = -3.0;
const float CUBE_SIZE = 0.8;
const int RAYMARCH_STEPS = 128;
const float RAYMARCH_MAX_DIST = 7.0;
const float RAYMARCH_MIN_STEP = 0.005;
const float RAYMARCH_STEP_SCALE = 0.5;
const float LINE_WIDTH_PX = 2.5;
const float ALPHA = 1.0;

float period(float bpm) { return 60.0 / bpm; }
float beatIndex(float t, float bpm) { return floor(t / period(bpm)); }
float beatPhase(float t, float bpm) { return fract(t / period(bpm)); }

float hash(vec3 v) {
    return fract(sin(dot(v, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}
vec3 randomAxis(vec3 seed) {
    float r1 = hash(seed);
    float r2 = hash(seed + 31.1);
    float r3 = hash(seed + 57.8);
    return normalize(vec3(r1 * 2.0 - 1.0, r2 * 2.0 - 1.0, r3 * 2.0 - 1.0));
}
float easeInOut(float x) {
    return 0.5 * (1.0 - cos(3.14159265 * x));
}
mat3 rotationAxis(vec3 axis, float angle) {
    float c = cos(angle), s = sin(angle), ic = 1.0 - c;
    return mat3(
        c + axis.x*axis.x*ic,       axis.x*axis.y*ic - axis.z*s, axis.x*axis.z*ic + axis.y*s,
        axis.y*axis.x*ic + axis.z*s, c + axis.y*axis.y*ic,       axis.y*axis.z*ic - axis.x*s,
        axis.z*axis.x*ic - axis.y*s, axis.z*axis.y*ic + axis.x*s, c + axis.z*axis.z*ic
    );
}

float minCubeEdgeDist(vec3 p, float s) {
    float minDist = 1e5;
    for(int i=0; i<3; i++) {
        for(int sign1=-1; sign1<=1; sign1+=2) {
            for(int sign2=-1; sign2<=1; sign2+=2) {
                vec3 a = vec3(0.0);
                vec3 b = vec3(0.0);
                if(i == 0) {
                    a = vec3(-s, float(sign1)*s, float(sign2)*s);
                    b = vec3( s, float(sign1)*s, float(sign2)*s);
                }
                if(i == 1) {
                    a = vec3(float(sign1)*s, -s, float(sign2)*s);
                    b = vec3(float(sign1)*s,  s, float(sign2)*s);
                }
                if(i == 2) {
                    a = vec3(float(sign1)*s, float(sign2)*s, -s);
                    b = vec3(float(sign1)*s, float(sign2)*s,  s);
                }
                vec3 ab = b - a;
                float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
                vec3 closest = a + ab * t;
                float dist = length(p - closest);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

void main() {
    vec2 tileResolution = resolution / vec2(float(TILES_X), float(TILES_Y));
    float aspect = tileResolution.x / tileResolution.y;
    float tileShort = min(tileResolution.x, tileResolution.y);

    vec2 uv = gl_FragCoord.xy / resolution;
    vec2 tile = floor(uv * vec2(float(TILES_X), float(TILES_Y)));

    vec2 localUV = fract(uv * vec2(float(TILES_X), float(TILES_Y))) * 2.0 - 1.0;
    localUV.x *= aspect;

    vec3 ro = vec3(0.0, 0.0, CAMERA_Z);
    vec3 rd = normalize(vec3(localUV, 2.0));

    float per = period(bpm);
    float idx = beatIndex(time, bpm);
    float phase = beatPhase(time, bpm);
    vec3 seedPrev = vec3(tile, idx);
    vec3 seedNext = vec3(tile, idx + 1.0);
    vec3 axisPrev = randomAxis(seedPrev);
    vec3 axisNext = randomAxis(seedNext);
    float anglePrev = hash(seedPrev + 100.0) * 6.2831853;
    float angleNext = hash(seedNext + 100.0) * 6.2831853;
    float tInterp = easeInOut(phase);
    vec3 axis = normalize(mix(axisPrev, axisNext, tInterp));

    float angle = 0.;
        mix(anglePrev, angleNext, tInterp);
    mat3 rot = rotationAxis(axis, angle);

    float cubeSize = CUBE_SIZE * (0.0 + audioLevel * 4.);
    float lineWidth = LINE_WIDTH_PX * (2.0 / tileShort);

    float t = 0.0;
    bool hit = false;
    float edgeDist = 0.0;
    vec3 p;
    for(int i=0; i<RAYMARCH_STEPS; i++) {
        p = ro + rd * t;
        p = rot * p;
        edgeDist = minCubeEdgeDist(p, cubeSize);
        if(edgeDist < lineWidth) {
            hit = true;
            break;
        }
        t += max(edgeDist * RAYMARCH_STEP_SCALE, RAYMARCH_MIN_STEP);
        if(t > RAYMARCH_MAX_DIST) break;
    }

    if(hit) {
        outColor = vec4(1.0, 1.0, 1.0, 1.0) * ALPHA;
    } else {
        outColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}