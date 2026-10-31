#version 460 core

#include <flutter/runtime_effect.glsl>

// The life bar at the top (see `LifeBar`): a capsule of flowing energy that
// fills from the left. The chunk lost on a miss stays for a moment and
// crumbles away.

uniform vec2 uSize;
// x, y, width, height of the capsule, in pixels
uniform vec4 uBar;
uniform float uTime;
// From 0 to 1, how much is filled
uniform float uFill;
// Where the chunk that was just lost ends, and how much of it is left
uniform float uGhost;
uniform float uGhostAlpha;
// 1 right after a block, fades out
uniform float uFlash;
// 1 right after a miss, fades out
uniform float uHit;
// 1 when a new stage is reached, goes down to 0 while a shine sweeps across
uniform float uLevelUp;
// 1 while in the danger stage
uniform float uDanger;
// 1 while the bar is full
uniform float uFull;
uniform vec3 uColor;
uniform float uOpacity;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.03;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 frag = FlutterFragCoord().xy;
    float r = uBar.w * 0.5;
    vec2 center = uBar.xy + uBar.zw * 0.5;
    vec2 q = frag - center;
    // Distance to the capsule, negative inside
    float dist = length(vec2(max(abs(q.x) - (uBar.z * 0.5 - r), 0.0), q.y)) - r;
    float inside = clamp(0.5 - dist, 0.0, 1.0);

    float x = (frag.x - uBar.x) / uBar.z;
    float y = (frag.y - uBar.y) / uBar.w;
    float aspect = uBar.z / uBar.w;

    // The front of the fill wobbles like a liquid
    float wobble = sin(y * 9.0 + uTime * 7.0) * 0.5 + noise(vec2(y * 4.0, uTime * 3.0)) - 0.5;
    float edge = uFill + wobble * 6.0 / uBar.z * step(0.001, uFill) * (1.0 - uFull);
    float inFill = clamp((edge - x) * uBar.z + 0.5, 0.0, 1.0);

    // Flowing energy
    float n = fbm(vec2(x * aspect * 0.9 - uTime * 1.6, y * 1.8 + uTime * 0.4));
    float band = 1.0 - pow(abs(y - 0.42) * 2.0, 2.0);
    float pulse = 0.5 + 0.5 * sin(uTime * 11.0);
    float bright = (0.55 + 0.7 * n) * (0.65 + 0.5 * band);
    bright *= mix(1.0, 0.55 + 0.75 * pulse, uDanger);
    vec3 fill = uColor * bright;
    fill += vec3(1.0) * smoothstep(0.55, 0.85, n) * (0.25 + 0.55 * uFull) * band;
    // White hot front
    float front = exp(-max(edge - x, 0.0) * uBar.z / 7.0) * (0.5 + 0.8 * uFlash);
    fill += mix(uColor, vec3(1.0), 0.6) * front * (1.0 - uFull);
    fill += (uColor * 0.8 + 0.3) * uFlash * 0.6;
    // Twinkles when it's full
    vec2 sp = vec2(x * uBar.z - uTime * 14.0, y * uBar.w) / 6.0;
    vec2 cell = floor(sp);
    float h = hash(cell);
    vec2 star = vec2(hash(cell + 3.1), hash(cell + 7.7)) * 0.5 + 0.25;
    float twinkle = pow(0.5 + 0.5 * sin(uTime * 5.0 + h * 40.0), 6.0);
    fill += vec3(1.0) * smoothstep(0.3, 0.0, length(fract(sp) - star)) * step(0.65, h) * twinkle * uFull;
    // A shine sweeping across when a stage is reached
    float sweepX = (1.0 - uLevelUp) * 1.4 - 0.2;
    fill += vec3(1.0) * exp(-pow((x - sweepX) * aspect * 0.6, 2.0)) * uLevelUp * 1.2;

    // The empty part, with marks where the stages start
    vec3 track = vec3(0.07, 0.07, 0.1);
    track = mix(track, vec3(0.35, 0.03, 0.06), (1.0 - step(0.2, x)) * (0.5 + 0.5 * uDanger * pulse));
    float ticks = 0.0;
    ticks += 1.0 - smoothstep(0.6, 1.4, abs(x - 0.2) * uBar.z);
    ticks += 1.0 - smoothstep(0.6, 1.4, abs(x - 0.5) * uBar.z);
    ticks += 1.0 - smoothstep(0.6, 1.4, abs(x - 0.8) * uBar.z);
    track += vec3(0.35) * ticks;
    track = mix(track, vec3(0.9, 0.15, 0.2), uHit * 0.6);

    // The chunk that was just lost, crumbling away
    float inGhost = step(edge, x) * step(x, uGhost);
    float crumble = step(fbm(vec2(x * aspect * 3.0, y * 3.0)) * 0.8 + 0.1, uGhostAlpha);
    vec3 ghost = mix(vec3(1.0), vec3(1.0, 0.25, 0.3), 1.0 - uGhostAlpha);
    float ghostA = inGhost * crumble * uGhostAlpha;

    vec3 rgb = mix(track, fill, inFill);
    float a = mix(0.7, 1.0, inFill);
    rgb = mix(rgb, ghost, ghostA);
    a = max(a, ghostA);

    // Thin rim
    float rim = 1.0 - smoothstep(0.0, 1.5, abs(dist + 0.75));
    rgb = mix(rgb, mix(uColor, vec3(1.0), 0.5), rim * 0.55);

    // Glow around the filled part
    float glowAmount = 0.22 + 0.25 * uFlash + 0.35 * uFull + 0.5 * uLevelUp + 0.25 * uDanger * pulse;
    float glowSide = smoothstep(edge + 0.06, edge - 0.02, x);
    // Fades out before the edges of the canvas so it never looks cut
    vec2 toEdge = min(frag, uSize - frag);
    float room = smoothstep(2.0, 12.0, min(toEdge.x, toEdge.y));
    float glow = exp(-max(dist, 0.0) / (4.0 + 3.0 * uFull + 4.0 * uLevelUp)) * glowAmount * glowSide * room;
    vec3 glowColor = uColor * glow + vec3(0.9, 0.15, 0.2) * exp(-max(dist, 0.0) / 6.0) * uHit * 0.7 * room;
    float glowA = clamp(max(glow, uHit * 0.5 * exp(-max(dist, 0.0) / 6.0) * room), 0.0, 1.0);

    vec4 color = vec4(rgb * a, a) * inside + vec4(glowColor, glowA) * (1.0 - inside);
    fragColor = color * uOpacity;
}
