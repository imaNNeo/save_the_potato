import 'potato_clips.dart';
import 'potato_pose.dart';

/// What the potato is doing right now.
enum PotatoMood { intro, idle, scared, reacting, dead }

/// Plays the potato's animations and decides which one comes next.
///
/// This replaces the Rive state machine and follows the same rules:
/// - from [PotatoMood.idle] every reaction can start;
/// - while scared, the potato only calms down, dies or gets amazed;
/// - a reaction (hit, heart, amazed) plays to the end, then goes back to idle;
/// - a dead potato stays dead until [respawn].
///
/// One difference: [die] now always works. With Rive a game over that came
/// while a hit animation was still playing was ignored, so the potato could
/// end the game smiling.
class PotatoAnimator {
  PotatoAnimator({bool intro = false}) {
    if (intro) {
      _play(PotatoClips.intro, PotatoMood.intro);
    } else {
      _play(PotatoClips.idle, PotatoMood.idle);
    }
  }

  /// The face to draw. Updated by [update].
  final PotatoPose pose = PotatoPose();

  PotatoMood get mood => _mood;
  PotatoMood _mood = PotatoMood.idle;

  PotatoClip get clip => _clip;
  late PotatoClip _clip;
  double _time = 0;

  /// Clips that play, one after another, once the current clip ends.
  /// When the queue is empty the potato settles in [_afterQueue].
  final List<PotatoClip> _queue = [];
  PotatoMood _afterQueue = PotatoMood.idle;

  void update(double dt) {
    _time += dt;
    if (!_clip.loop && _time >= _clip.duration) {
      // Show the final frame of the finished clip before moving on, so a
      // short clip never gets skipped by a long frame.
      _clip.apply(pose, _clip.duration);
      _next(_time - _clip.duration);
    }
    _clip.apply(pose, _time);
  }

  void fireHit() => _react(PotatoClips.fireHit);

  void iceHit() => _react(PotatoClips.iceHit);

  void heartHit() => _react(PotatoClips.heartHit);

  void amazed() {
    switch (_mood) {
      case PotatoMood.idle:
        _react(PotatoClips.amazed);
      case PotatoMood.scared:
        _play(PotatoClips.calmDown, PotatoMood.reacting);
        _then([PotatoClips.amazed], PotatoMood.idle);
      case PotatoMood.intro || PotatoMood.reacting || PotatoMood.dead:
        break;
    }
  }

  void scared() {
    if (_mood == PotatoMood.idle) {
      _play(PotatoClips.scared, PotatoMood.scared);
    }
  }

  /// Goes back to idle after being scared.
  void calmDown() {
    if (_mood == PotatoMood.scared) {
      _play(PotatoClips.calmDown, PotatoMood.reacting);
    }
  }

  void die() {
    switch (_mood) {
      case PotatoMood.dead:
        break;
      case PotatoMood.scared:
        _play(PotatoClips.calmDown, PotatoMood.reacting);
        _then([PotatoClips.die], PotatoMood.dead);
      case PotatoMood.intro || PotatoMood.idle || PotatoMood.reacting:
        _play(PotatoClips.die, PotatoMood.dead);
    }
  }

  void respawn() {
    if (_mood == PotatoMood.dead) {
      _play(PotatoClips.respawn, PotatoMood.reacting);
      _then([PotatoClips.amazed], PotatoMood.idle);
    }
  }

  void _react(PotatoClip clip) {
    if (_mood == PotatoMood.idle) {
      _play(clip, PotatoMood.reacting);
    }
  }

  void _play(PotatoClip clip, PotatoMood mood) {
    _clip = clip;
    _mood = mood;
    _time = 0;
    _queue.clear();
    _afterQueue = switch (mood) {
      PotatoMood.dead => PotatoMood.dead,
      PotatoMood.scared => PotatoMood.scared,
      _ => PotatoMood.idle,
    };
    _clip.apply(pose, 0);
  }

  void _then(List<PotatoClip> clips, PotatoMood settleIn) {
    _queue.addAll(clips);
    _afterQueue = settleIn;
  }

  void _next(double leftover) {
    if (_queue.isNotEmpty) {
      _clip = _queue.removeAt(0);
      _time = leftover;
      if (_queue.isEmpty && _afterQueue == PotatoMood.dead) {
        _mood = PotatoMood.dead;
      }
      return;
    }
    if (_afterQueue == PotatoMood.idle) {
      _clip = PotatoClips.idle;
      _mood = PotatoMood.idle;
      _time = leftover;
    } else {
      // Hold the last frame (scared face, dead face).
      _time = _clip.duration;
    }
  }
}
