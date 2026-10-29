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


uniform float iTime;
uniform vec2 iResolution;
uniform vec3 backgroundColor;
uniform vec3 starColor;
uniform float starSize;

// Reactions to the game, see `BackgroundReactions`
uniform float heat;
uniform float power;
uniform float hit;
// How far the stars have swirled around the center, in radians
uniform float swirl;
uniform vec2 shake;
// rgb: color of the glow around the potato, a: how much it flashes
uniform vec4 glow;
// Shockwaves rolling out, see `BackgroundWave`.
// wave: x radius, y 1 / its half width (0 when there's none), zw the
// direction it's strongest in, as long as how much it's focused on it.
// waveColor: rgb its color times its intensity, a 1 - its focus.
uniform vec4 wave0;
uniform vec4 waveColor0;
uniform vec4 wave1;
uniform vec4 waveColor1;
uniform vec4 wave2;
uniform vec4 waveColor2;
uniform vec4 wave3;
uniform vec4 waveColor3;

// Three random numbers from 0 to 1 for star [i]. Only multiplications, a lot
// cheaper than the usual fract(sin(...)) hash (Dave Hoskins' hash31).
vec3 rand3(float i) {
    vec3 p = fract(vec3(i + 0.5) * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yzx + 33.33);
    return fract((p.xxy + p.yzz) * p.zyx);
}

float saturate(float v) {
    return clamp(v, 0.0, 1.0);
}

vec3 renderBackground(vec2 uv) {
    float dist = length(uv) * 5.0;
    return saturate(1.0 / (dist + 1.5)) * backgroundColor;
}

// How strong [wave] is at [p] (in world units, [r] away from the center)
// How strong a wave is at [n] (the direction from the center), [r] away
vec3 waveAt(vec2 n, float r, vec4 wave, vec4 color) {
    float d = min(abs(r - wave.x) * wave.y, 1.0);
    float ring = 1.0 - d * d;
    float directional = saturate(color.a + dot(n, wave.zw));
    return color.rgb * (ring * ring * directional);
}

// [stretch] is how much to squash the distance behind (x) and in front of
// (y) the star, to stretch it into a streak
float renderStar(vec2 uv, float i, float aspect, vec2 stretch) {
    float maxDistance = aspect;

    // setup radius
    vec3 random = rand3(i);
    float radiusrand = random.x;
    float rad = MIN_RADIUS + radiusrand * (MAX_RADIUS - MIN_RADIUS);

    // compute star position, somewhere inside its own sector
    float startr = random.y * maxDistance;
    float speed = radiusrand * MAX_MOVEMENT_SPEED;
    float r = mod(startr + iTime * speed, max(1.0, maxDistance));
    float theta = (i + random.z) / STAR_COUNT * TWOPI + swirl;
    vec2 dir = vec2(cos(theta), sin(theta));
    vec2 pos = r * vec2(dir.x * aspect, dir.y);

    // blending/effects, stretched behind the star (towards the center) when
    // powered up, like flying at warp speed
    vec2 diff = uv - pos;
    float along = dot(diff, dir);
    along *= along < 0.0 ? stretch.x : stretch.y;
    float across = dir.x * diff.y - dir.y * diff.x;
    float dist = length(vec2(along, across));
    float distTraveled = r / maxDistance;
    float shape = saturate(distTraveled * rad / ((100.0 - min(starSize, 100.0)) * dist) - 0.08);

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
    vec2 n = p / max(r, 1.0);
    waveLight = waveAt(n, r, wave0, waveColor0) +
        waveAt(n, r, wave1, waveColor1) +
        waveAt(n, r, wave2, waveColor2) +
        waveAt(n, r, wave3, waveColor3);
    waves = max(waveLight.r, max(waveLight.g, waveLight.b));

    // The waves push the stars out as they roll by
    vec2 starUv = uv * (1.0 - min(waves, 1.5) * 0.06);

    // Star positions are laid out before stretching x by the aspect ratio,
    // so find the sector in that unstretched space.
    // The stars swirling around the center is the same as the pixel turning
    // the other way
    float angle = mod(atan(starUv.y, starUv.x / aspect) - swirl, TWOPI);
    float sector = floor(angle / TWOPI * STAR_COUNT);

    vec2 stretch = vec2(1.0 / (1.0 + power * 5.0), 1.0 / (1.0 + power * 0.75));
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
