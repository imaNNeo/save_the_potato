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

float renderStar(vec2 uv, float i, float aspect) {
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

    // blending/effects
    float dist = length(uv - pos);
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

    // Star positions are laid out before stretching x by the aspect ratio,
    // so find the sector in that unstretched space.
    float angle = atan(uv.y, uv.x / aspect);
    if (angle < 0.0) {
        angle += TWOPI;
    }
    float sector = floor(angle / TWOPI * STAR_COUNT);

    float stars = 0.0;
    for (int k = -NEIGHBOUR_SECTORS; k <= NEIGHBOUR_SECTORS; ++k) {
        stars += renderStar(uv, mod(sector + float(k), STAR_COUNT), aspect);
    }

    fragColor = vec4(renderBackground(uv) + starColor * stars, 1.0);
}
