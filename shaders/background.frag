#version 460 core

#include <flutter/runtime_effect.glsl>

#define MAX_MOVEMENT_SPEED 0.02
#define MIN_RADIUS 0.01
#define MAX_RADIUS 0.04
#define TWOPI 6.283185307

// Every star lives in its own angular sector around the center, so a pixel
// only has to look at the stars of its own and neighbouring sectors instead
// of looping over all of them. A star never reaches further than
// [NEIGHBOUR_SECTORS] sectors away (its visible size grows with its distance
// from the center), so the result matches looping over every star.
#define STAR_COUNT 50.0
#define NEIGHBOUR_SECTORS 2

#define RADIUS_SEED 1337.0
#define START_POS_SEED 2468.0
#define THETA_SEED 1675.0

uniform float iTime;
uniform vec2 iResolution;
uniform vec3 backgroundColor;
uniform vec3 starColor;
uniform float starSize;

// Reactions to the game, see `BackgroundReactions`
uniform float heat;
uniform float power;
uniform float hit;
// x: how far the stars have swirled (radians), y: how much they swirl now
uniform vec2 swirl;
uniform vec2 shake;
// rgb: color of the glow around the potato, a: how much it flashes
uniform vec4 glow;
// Shockwaves, xy: radius and intensity, zw: direction they're strongest in.
// rgb of their color is their color, a: how much it's focused on that
// direction (0 is a full ring)
uniform vec4 wave0;
uniform vec4 waveColor0;
uniform vec4 wave1;
uniform vec4 waveColor1;
uniform vec4 wave2;
uniform vec4 waveColor2;
uniform vec4 wave3;
uniform vec4 waveColor3;

float rand(float s1, float s2) {
    return fract(sin(dot(vec2(s1, s2), vec2(12.9898, 78.233))) * 43758.5453);
}

float saturate(float v) {
    return clamp(v, 0.0, 1.0);
}

vec3 renderBackground(vec2 uv) {
    float dist = length(uv) * 5.0;
    return saturate(1.0 / (dist + 1.5)) * backgroundColor;
}

// How strong [wave] is at [p] (in world units, [r] away from the center)
float waveAt(vec2 p, float r, vec4 wave, vec4 color) {
    if (wave.y <= 0.0) {
        return 0.0;
    }
    float width = 14.0 + wave.x * 0.16;
    float d = (r - wave.x) / width;
    float ring = exp(-d * d);
    float facing = dot(p, wave.zw) / max(r, 1.0);
    float directional = smoothstep(-0.3, 1.0, facing);
    return ring * wave.y * mix(1.0, directional * directional, color.a);
}

float renderStar(vec2 uv, float i, float aspect, float stretch) {
    float maxDistance = aspect;

    // setup radius
    float radiusrand = rand(i, RADIUS_SEED);
    float rad = MIN_RADIUS + radiusrand * (MAX_RADIUS - MIN_RADIUS);

    // compute star position, somewhere inside its own sector
    float startr = rand(i, START_POS_SEED) * maxDistance;
    float speed = radiusrand * MAX_MOVEMENT_SPEED;
    float r = mod(startr + iTime * speed, max(1.0, maxDistance));
    float theta = (i + rand(i, THETA_SEED)) / STAR_COUNT * TWOPI;
    vec2 pos = vec2(r * cos(theta) * aspect, r * sin(theta));

    // blending/effects, stretched behind the star (towards the center) when
    // powered up, like flying at warp speed
    vec2 diff = uv - pos;
    vec2 outward = pos / max(r, 0.0001);
    float along = dot(diff, outward);
    float across = dot(diff, vec2(-outward.y, outward.x));
    along /= along < 0.0 ? 1.0 + stretch : 1.0 + stretch * 0.15;
    float dist = length(vec2(along, across));
    float distFromStarCenter = dist / rad;
    float distTraveled = r / maxDistance;
    float shape = saturate(1.0 / ((100.0 - min(starSize, 100.0)) * (1.0 / distTraveled) * distFromStarCenter) - 0.08);

    return step(dist, rad) * shape;
}

out vec4 fragColor;

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = -1.0 + 2.0 * (FlutterFragCoord().xy / iResolution.xy);
    uv.x *= aspect;

    // The game fits 600x600 world units in the screen, centered on the potato
    float worldToUv = min(aspect, 1.0) / 300.0;
    uv -= shake * worldToUv;
    vec2 p = uv / worldToUv;
    float r = length(p);

    vec3 waveLight = vec3(0.0);
    float waves = 0.0;
    float w = waveAt(p, r, wave0, waveColor0);
    waveLight += waveColor0.rgb * w;
    waves += w;
    w = waveAt(p, r, wave1, waveColor1);
    waveLight += waveColor1.rgb * w;
    waves += w;
    w = waveAt(p, r, wave2, waveColor2);
    waveLight += waveColor2.rgb * w;
    waves += w;
    w = waveAt(p, r, wave3, waveColor3);
    waveLight += waveColor3.rgb * w;
    waves += w;

    // The waves push the stars out as they roll by
    vec2 starUv = uv * (1.0 - min(waves, 1.5) * 0.06);

    // Swirl the stars around the potato, the inner ones more
    if (swirl.x != 0.0) {
        float twist = swirl.x + swirl.y * 0.6 / (1.0 + length(starUv) * 1.5);
        float c = cos(twist);
        float s = sin(twist);
        starUv = vec2(c * starUv.x - s * starUv.y, s * starUv.x + c * starUv.y);
    }

    // Star positions are laid out before stretching x by the aspect ratio,
    // so find the sector in that unstretched space.
    float angle = atan(starUv.y, starUv.x / aspect);
    if (angle < 0.0) {
        angle += TWOPI;
    }
    float sector = floor(angle / TWOPI * STAR_COUNT);

    float stretch = power * 5.0;
    float stars = 0.0;
    for (int k = -NEIGHBOUR_SECTORS; k <= NEIGHBOUR_SECTORS; ++k) {
        stars += renderStar(starUv, mod(sector + float(k), STAR_COUNT), aspect, stretch);
    }
    stars *= 1.0 + heat * 0.6 + power * 0.8 + waves * 2.5;

    // The glow around the potato grows with the streak and flashes on blocks
    float dist = length(uv);
    float centerGlow = saturate(1.0 / (dist * (5.0 - heat * 1.5) + 1.5));
    vec3 background = centerGlow * backgroundColor;
    float glowAmount = heat * 0.18 + glow.a * 0.35;
    background += glow.rgb * centerGlow * centerGlow * glowAmount;

    // Getting hit dims everything and turns it red for a moment
    vec3 starTint = mix(starColor, vec3(1.0, 0.35, 0.35), hit * 0.8);
    vec3 color = background + starTint * stars * (1.0 - hit * 0.45);
    color += waveLight * (0.12 + 0.18 * centerGlow);
    float vignette = smoothstep(0.4, 1.6, dist);
    color = mix(color, vec3(0.45, 0.0, 0.04), hit * vignette * 0.7);

    fragColor = vec4(color, 1.0);
}
