#version 300 es
precision mediump float;

out vec4 fragColor;

uniform float time;
uniform vec2 resolution;
uniform sampler2D prevPass;
uniform sampler2D drawLogo;

void main() {
    vec2 r = resolution;
    vec2 uv = gl_FragCoord.xy / r;
    vec4 frag = texture(prevPass, uv);

    const float scale = 1.5;

    float logoAspect = 1.0;
    float winAspect = r.x / r.y;
    
    float dispW, dispH;
    if (winAspect > logoAspect) {
        dispH = scale;
        dispW = scale * logoAspect / winAspect;
    } else {
        dispW = scale;
        dispH = scale * winAspect / logoAspect;
    }

    vec2 logoMin = 0.5 - vec2(dispW, dispH) * 0.5;
    vec2 logoMax = 0.5 + vec2(dispW, dispH) * 0.5;

    vec4 logo = vec4(0.0);
    if (all(greaterThanEqual(uv, logoMin)) && all(lessThanEqual(uv, logoMax))) {
        vec2 logoUV = (uv - logoMin) / (logoMax - logoMin);
        logo = texture(drawLogo, logoUV);
    }

    frag = mix(frag, logo, logo.a);   
    
    fragColor = frag;
}