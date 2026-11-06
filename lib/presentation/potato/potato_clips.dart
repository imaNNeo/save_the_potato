import 'dart:ui' show lerpDouble;

import 'potato_pose.dart';

/// One keyframe: at [frame] (60 frames per second) the prop has [value].
typedef PotatoKey = (int frame, double value);

/// A short keyframed animation of the potato's face.
///
/// Each track moves one [PotatoProp] linearly between its keys. Before the
/// first key a track holds the first value, after the last key it holds the
/// last value. Props without a track are left untouched.
class PotatoClip {
  const PotatoClip({
    required this.frames,
    required this.tracks,
    this.loop = false,
  });

  static const fps = 60.0;

  /// Length of the clip in frames at [fps].
  final int frames;
  final Map<PotatoProp, List<PotatoKey>> tracks;
  final bool loop;

  double get duration => frames / fps;

  /// Writes the clip's values at [time] (in seconds) into [pose].
  void apply(PotatoPose pose, double time) {
    final frame = (loop ? time % duration : time.clamp(0, duration)) * fps;
    tracks.forEach((prop, keys) => pose[prop] = _valueAt(keys, frame));
  }

  static double _valueAt(List<PotatoKey> keys, double frame) {
    if (frame <= keys.first.$1) return keys.first.$2;
    for (var i = 1; i < keys.length; i++) {
      final (toFrame, toValue) = keys[i];
      if (frame <= toFrame) {
        final (fromFrame, fromValue) = keys[i - 1];
        final t = (frame - fromFrame) / (toFrame - fromFrame);
        return lerpDouble(fromValue, toValue, t)!;
      }
    }
    return keys.last.$2;
  }
}

/// All potato animations. The timings and values match the animations of
/// the original Rive file one to one.
abstract final class PotatoClips {
  /// Looping idle: the eye sparkles blink once every 3 seconds.
  static const idle = PotatoClip(
    frames: 180,
    loop: true,
    tracks: {
      PotatoProp.sparkleScaleY: [
        (0, 1.1259),
        (25, 1.1259),
        (33, 0),
        (40, 1.13),
      ],
    },
  );

  /// Played once on the splash screen: the sparkles pop in, then the potato
  /// looks left, right, and back to the center.
  static const intro = PotatoClip(
    frames: 120,
    tracks: {
      PotatoProp.sparkleX: [
        (0, 0),
        (44, 0),
        (58, -6.3437),
        (72, -6.3437),
        (95, 7.7958),
        (107, 7.7958),
        (113, 0),
      ],
      PotatoProp.sparkleScaleY: [(0, 0), (22, 0), (26, 1.13)],
    },
  );

  /// The sparkles shrink and the smile turns into a zigzag.
  static const scared = PotatoClip(
    frames: 11,
    tracks: {
      PotatoProp.sparkleScaleX: [(0, 0.96), (11, 0.4)],
      PotatoProp.sparkleScaleY: [(0, 1.13), (11, 0.4)],
      PotatoProp.zigzagOpacity: [(0, 0), (11, 1)],
      PotatoProp.smileOpacity: [(0, 1), (11, 0)],
    },
  );

  /// [scared] played backwards.
  static const calmDown = PotatoClip(
    frames: 11,
    tracks: {
      PotatoProp.sparkleScaleX: [(0, 0.4), (11, 0.96)],
      PotatoProp.sparkleScaleY: [(0, 0.4), (11, 1.13)],
      PotatoProp.zigzagOpacity: [(0, 1), (11, 0)],
      PotatoProp.smileOpacity: [(0, 0), (11, 1)],
    },
  );

  /// Big green sparkles, played when a motivation word shows up.
  static const amazed = PotatoClip(
    frames: 51,
    tracks: {
      PotatoProp.sparkleScaleX: [(0, 0.9596), (19, 3), (40, 3), (51, 0.96)],
      PotatoProp.sparkleScaleY: [(0, 0.96), (19, 3), (40, 3), (51, 0.9604)],
      PotatoProp.sparkleGreen: [(0, 0), (5, 1), (46, 1), (51, 0)],
      PotatoProp.sparkleOutline: [(0, 1), (19, 3), (46, 3), (51, 1)],
    },
  );

  /// The sparkles go out and the smile turns into a frown.
  static const die = PotatoClip(
    frames: 60,
    tracks: {
      PotatoProp.sparkleScaleY: [(0, 1.1259), (38, 1.1259), (57, 0)],
      PotatoProp.mouthOpacity: [(0, 1), (13, 1), (24, 0)],
      PotatoProp.tongueOpacity: [(0, 1), (13, 1), (24, 0)],
      PotatoProp.smileScaleY: [(13, 1), (24, 0)],
      PotatoProp.frownScaleY: [(24, 0), (35, 0.76)],
      PotatoProp.frownOpacity: [(0, 0), (13, 0), (35, 1)],
    },
  );

  /// Brings a dead potato back to life.
  static const respawn = PotatoClip(
    frames: 33,
    tracks: {
      PotatoProp.sparkleScaleY: [(0, 0), (8, 1.1259)],
      PotatoProp.mouthOpacity: [(19, 0), (26, 1)],
      PotatoProp.tongueOpacity: [(19, 0), (26, 1)],
      PotatoProp.smileScaleY: [(19, 0), (26, 1)],
      PotatoProp.frownScaleY: [(12, 0.76), (19, 0)],
      PotatoProp.frownOpacity: [(12, 1), (26, 0)],
    },
  );

  /// Hearts grow over the eyes, then shrink away.
  static const heartHit = PotatoClip(
    frames: 60,
    tracks: {
      PotatoProp.heartScale: [(0, 1), (25, 3.265), (31, 3.265), (60, 0)],
      PotatoProp.heartOpacity: [(0, 0), (4, 1)],
    },
  );

  /// Ouch, hot! The skin flashes red and the face winces.
  static const fireHit = PotatoClip(
    frames: 60,
    tracks: {
      ..._winceTracks,
      PotatoProp.mouthY: [(2, -9.435), (5, 4.1665), (25, 4.1665), (29, -9.44)],
      PotatoProp.mouthScaleX: [(2, 0.9486), (5, 0.6499), (35, 0.95)],
      PotatoProp.mouthScaleY: [(2, 1), (5, 0.3095), (35, 1)],
      PotatoProp.zigzagOpacity: [(5, 0), (19, 1), (31, 0)],
      PotatoProp.fireTint: [(2, 0), (6, 1), (21, 1), (35, 0)],
    },
  );

  /// Ouch, cold! The skin flashes blue and the face winces.
  static const iceHit = PotatoClip(
    frames: 60,
    tracks: {
      ..._winceTracks,
      PotatoProp.mouthY: [(2, -9.435), (5, 3.8228), (24, 3.82), (35, -9.44)],
      PotatoProp.mouthScaleX: [
        (2, 0.9486),
        (5, 0.6499),
        (24, 0.75),
        (35, 0.95),
      ],
      PotatoProp.mouthScaleY: [(2, 1), (5, 0.3095), (24, 0.54), (35, 1)],
      PotatoProp.zigzagOpacity: [(5, 0), (18, 1), (33, 0)],
      PotatoProp.iceTint: [(2, 0), (6, 1), (21, 1), (35, 0)],
    },
  );

  /// The part of a hit that is the same for fire and ice.
  static const _winceTracks = <PotatoProp, List<PotatoKey>>{
    PotatoProp.sparkleSize: [(2, 1), (12, 0.41), (21, 0.41), (35, 1)],
    PotatoProp.leftBrowAngle: [
      (2, -0.3539),
      (13, -0.6692),
      (24, -0.6692),
      (35, -0.3539),
    ],
    PotatoProp.rightBrowAngle: [
      (2, 0.3249),
      (13, 0.6541),
      (24, 0.6541),
      (35, 0.3249),
    ],
    PotatoProp.mouthOpacity: [(2, 1), (13, 0), (24, 0), (35, 1)],
    PotatoProp.tongueOpacity: [(2, 1), (5, 0), (29, 0), (35, 1)],
  };
}
