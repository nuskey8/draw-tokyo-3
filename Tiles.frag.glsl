#version 300 es
precision highp float;

uniform float time;
uniform vec2 resolution;
uniform float bpm;
uniform sampler2D prevPass;

const int state = 1;
const float base_box_size = 0.2;
const float gap = 0.01;

out vec4 fragColor;

float easeInOut(float t) {
    return t < 0.5
        ? 2.0 * t * t
        : -1.0 + (4.0 - 2.0 * t) * t;
}

void gliderShape(int step, out int shape[9]) {
    if(step == 0) {
        // # # #
        // . . #
        // . # .
        shape[0]=1; shape[1]=1; shape[2]=1;
        shape[3]=0; shape[4]=0; shape[5]=1;
        shape[6]=0; shape[7]=1; shape[8]=0;
    } else if(step == 1) {
        // . # . 
        // . # #
        // # . #
        shape[0]=0; shape[1]=1; shape[2]=0;
        shape[3]=0; shape[4]=1; shape[5]=1;
        shape[6]=1; shape[7]=0; shape[8]=1;
    } else if(step == 2) {
        // . # # 
        // # . #      // 
        // . . #      // 
        shape[0]=0; shape[1]=1; shape[2]=1;
        shape[3]=1; shape[4]=0; shape[5]=1;
        shape[6]=0; shape[7]=0; shape[8]=1;
    } else {
        // # # .
        // . # #
        // # . .
        shape[0]=1; shape[1]=1; shape[2]=0;
        shape[3]=0; shape[4]=1; shape[5]=1;
        shape[6]=1; shape[7]=0; shape[8]=0;
    }
}

float random(vec2 p, float seed) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float minRes = min(resolution.x, resolution.y);
    vec2 uv = (gl_FragCoord.xy - resolution * 0.5) / minRes * 2.0;

    float cell = base_box_size + gap;
    vec2 grid_size = vec2(5.0 * cell - gap);
    vec2 grid_min = -grid_size * 0.5;
    vec2 rel = uv - grid_min;

    if(rel.x < 0.0 || rel.x > grid_size.x || rel.y < 0.0 || rel.y > grid_size.y){
        fragColor = texture(prevPass, gl_FragCoord.xy / resolution);
        return;
    }

    int gx = int(floor(rel.x / cell));
    int gy = int(floor(rel.y / cell));
    vec2 cell_origin = vec2(float(gx), float(gy)) * cell;
    vec2 local = rel - cell_origin;
    vec2 box_center = vec2(cell, cell) * 0.5;
    vec2 dist = local - box_center;

    float beatLen = 60.0 / bpm;
    float box_size = base_box_size;

    if(state == 0){
        box_size = base_box_size;
    }else if(state == 1){
        float offset = (4.0 - float(gx) + 4.0 - float(gy)) * 0.08;
        float beatPhase = mod(time / beatLen - offset, 1.0);
        float sizeEase = easeInOut(sin(beatPhase * 3.1415926));
        box_size = base_box_size * sizeEase;
    }else if(state == 2){
        float centerX = 2.0;
        float centerY = 2.0;
        float distFromCenter = length(vec2(float(gx), float(gy)) - vec2(centerX, centerY));
        float offset = distFromCenter * 0.18;
        float beatPhase = mod(time / beatLen - offset, 1.0);
        float sizeEase = easeInOut(sin(beatPhase * 3.1415926));
        box_size = base_box_size * sizeEase;
    }else if(state == 3){
        float offset = float(gx) * 0.08; 
        float beatPhase = mod(time / beatLen - offset, 1.0);
        float sizeEase = easeInOut(sin(beatPhase * 3.1415926));
        box_size = base_box_size * sizeEase;
    } else if(state == 4){
        float offset = float(gy) * 0.08; 
        float beatPhase = mod(time / beatLen - offset, 1.0);
        float sizeEase = easeInOut(sin(beatPhase * 3.1415926));
        box_size = base_box_size * sizeEase;
    } else if(state == 5){
        int shape[9];
        int step = int(mod(time / beatLen, 4.0));
        gliderShape(step, shape);

        if(gx >= 1 && gx <= 3 && gy >= 1 && gy <= 3) {
            int idx = (gy-1)*3 + (gx-1);
            if(shape[idx] == 1) {
                float beatPhase = mod(time / beatLen, 1.0);
                float sizeEase = easeInOut(sin(beatPhase * 3.1415926));
                box_size = base_box_size * sizeEase;
            } else {
                box_size = 0.0;
            }
        } else {
            box_size = 0.0;
        }
    } else{
        box_size = 0.0;
    }

    if(box_size > 0.0 && abs(dist.x) < box_size * 0.5 && abs(dist.y) < box_size * 0.5){
        fragColor = vec4(1.);
    }else{
        fragColor = texture(prevPass, gl_FragCoord.xy / resolution);
    }
}