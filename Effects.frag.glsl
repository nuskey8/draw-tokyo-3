#version 300 es
precision mediump float;

out vec4 fragColor;

uniform sampler2D prevPass;
uniform sampler2D prevFrame;
uniform float time;
uniform vec2 resolution;
uniform sampler2D midiNotes;
uniform sampler2D midiControls;

float readMidiControl(int index) {
    int width = textureSize(midiControls, 0).x;
    float u = (float(index) + 0.5) / float(width);
    float v = 0.5;
    return texture(midiControls, vec2(u, v)).r;
}


float readMidiNote(int index) {
    int width = textureSize(midiNotes, 0).x;
    float u = (float(index) + 0.5) / float(width);
    float v = 0.5;
    return texture(midiNotes, vec2(u, v)).r;
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    vec4 color = texture(prevPass, uv);

    // Flash
    if (readMidiNote(36) > 0.) {
        color += vec4(vec3(0.6), 0.);
    }

    color += texture(prevFrame, uv) * readMidiControl(74);
    
    // Blackout
    if (readMidiNote(38) > 0.) {
        fragColor = vec4(0.);
    } else {
        fragColor = color;
    }
}