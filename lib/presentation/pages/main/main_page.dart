import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/main.dart';
import 'package:save_the_potato/presentation/background_reactions.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/presentation/pages/fade_route.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';
import 'package:save_the_potato/presentation/pages/splash/splash_stage.dart';
import 'package:save_the_potato/presentation/widgets/potato_initialize.dart';
import 'package:save_the_potato/presentation/widgets/background_stars.dart';
import 'package:save_the_potato/presentation/widgets/debug_panel.dart';
import 'package:save_the_potato/presentation/widgets/game_over_ui.dart';
import 'package:save_the_potato/presentation/widgets/game_paused_ui.dart';
import 'package:save_the_potato/presentation/widgets/high_score_widget.dart';
import 'package:save_the_potato/presentation/widgets/level_cleared_ui.dart';
import 'package:save_the_potato/presentation/widgets/level_select.dart';
import 'package:save_the_potato/presentation/widgets/mode_switcher.dart';
import 'package:save_the_potato/presentation/widgets/loading_overlay.dart';
import 'package:save_the_potato/presentation/widgets/new_rank_celebration_page.dart';
import 'package:save_the_potato/presentation/widgets/potato_top_bar.dart';
import 'package:save_the_potato/presentation/widgets/rotating_controls.dart';
import 'package:save_the_potato/presentation/widgets/settings_pause_icon.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late Key pageRootKey;

  late PotatoGame _game;

  /// The game makes the stars background react to what happens in it
  final _backgroundReactions = BackgroundReactions();

  late GameCubit _gameCubit;
  late SettingsCubit _settingsCubit;

  late StreamSubscription _streamSubscription;

  late PlayingState _previousState;

  OverlayEntry? _generalLoadingEntry;

  /// Stands in for the potato until the game draws its own, so opening this
  /// page never shows the stars without the potato.
  bool _potatoCover = true;

  late StreamSubscription _generalLoadingSubscription;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    pageRootKey = UniqueKey();
    _gameCubit = context.read<GameCubit>();
    _settingsCubit = context.read<SettingsCubit>();
    _gameCubit.startToShowGuide();
    _game = PotatoGame(_gameCubit, _settingsCubit, _backgroundReactions);
    _removePotatoCoverWhenReady(_game);
    _previousState = _gameCubit.state.playingState;
    _streamSubscription = _gameCubit.stream.listen((state) {
      if ((_previousState.isNone || _previousState.isGameOver) &&
          (state.playingState.isPlaying || state.playingState.isGuide)) {
        setState(() {
          _game = PotatoGame(_gameCubit, _settingsCubit, _backgroundReactions);
        });
      }
      _previousState = state.playingState;
    });

    final scoresCubit = context.read<ScoresCubit>();
    _generalLoadingSubscription = scoresCubit.stream.listen((state) {
      if (!mounted) return;
      if (state.showAuthDialog) {
        // ignore: use_build_context_synchronously
        BaseDialog.showAuthDialog(context);
      }
      if (state.showNicknameDialog) {
        // ignore: use_build_context_synchronously
        BaseDialog.showNicknameDialog(context);
      }
      if (state.scoreShareLoading) {
        if (_generalLoadingEntry == null) {
          _generalLoadingEntry = OverlayEntry(
            builder: (context) => const LoadingOverlay(),
          );
          // ignore: use_build_context_synchronously
          Overlay.of(context).insert(_generalLoadingEntry!);
        }
      } else {
        _generalLoadingEntry?.remove();
        _generalLoadingEntry = null;
      }
    });
    super.initState();
  }

  Future<void> _removePotatoCoverWhenReady(PotatoGame game) async {
    await game.potatoReady;
    // The potato is drawn on the next frame, then the cover can go
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _potatoCover = false);
  }

  void _restartGameWidgets() {
    setState(() {
      pageRootKey = UniqueKey();
      _game = PotatoGame(_gameCubit, _settingsCubit, _backgroundReactions);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (_gameCubit.state.playingState.isPlaying) {
          _gameCubit.pauseGame(manually: false);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameWidget = GameWidget(game: _game);
    return BlocConsumer<GameCubit, GameState>(
      key: pageRootKey,
      // GameState changes every frame while playing, only react to what
      // this page uses.
      listenWhen: (previous, current) =>
          previous.restartGame != current.restartGame ||
          previous.onNewHighScore != current.onNewHighScore,
      buildWhen: (previous, current) =>
          previous.playingState != current.playingState ||
          previous.showGameOverUI != current.showGameOverUI ||
          previous.tutorialHint != current.tutorialHint ||
          previous.level != current.level ||
          previous.levelsCleared != current.levelsCleared,
      listener: (context, state) {
        if (state.restartGame) {
          _restartGameWidgets();
        }
        if (state.onNewHighScore != null) {
          context.read<ScoresCubit>().tryToRefreshLeaderboard();
          Navigator.of(context).push(
            FadeRoute(
              page: NewRankCelebrationPage(scoreEntity: state.onNewHighScore!),
            ),
          );
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.playingState.isPlaying,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) {
              return;
            }
            _gameCubit.pauseGame(manually: true);
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                _MainPageBackground(reactions: _backgroundReactions),
                gameWidget,
                _PotatoCover(visible: _potatoCover),
                const Align(
                  alignment: Alignment.topCenter,
                  child: PotatoTopBar(),
                ),
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: DebugPanel(),
                ),
                RotationControls(
                  // A locked level can't be started, so no HOLD hint
                  // The home screen has a START button instead
                  showGuide: false,
                  hint: state.playingState.isPlaying ? state.tutorialHint : 0,
                  onLeftDown: _gameCubit.onLeftTapDown,
                  onLeftUp: _gameCubit.onLeftTapUp,
                  onRightDown: _gameCubit.onRightTapDown,
                  onRightUp: _gameCubit.onRightTapUp,
                ),
                if (state.playingState.isGuide) const LevelSelect(),
                if (state.playingState.isPaused) const GamePausedUI(),
                if (state.showGameOverUI && state.playingState.isGameOver)
                  const GameOverUI(),
                if (state.showGameOverUI &&
                    state.playingState is PlayingStateLevelCleared)
                  LevelClearedUI(
                    level:
                        (state.playingState as PlayingStateLevelCleared).level,
                  ),
                const Align(
                  alignment: Alignment.topRight,
                  child: SettingsPauseIcon(),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: state.isLevelsMode
                      ? const LevelsProgressBadge()
                      : const HighScoreWidget(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  void didPushNext() {
    /// this page is not visible anymore,
    /// we need to pause the game if it is playing
    _pauseIfPlaying();
  }

  void _pauseIfPlaying() {
    if (_gameCubit.state.playingState.isPlaying) {
      _gameCubit.pauseGame(manually: false);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _streamSubscription.cancel();
    _generalLoadingSubscription.cancel();
    _backgroundReactions.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// The splash potato at exactly the spot and size of the game potato
class _PotatoCover extends StatelessWidget {
  const _PotatoCover({required this.visible});

  final bool visible;

  /// Like the game potato on the start screen
  static void _wearHeadphones(PotatoPose pose, double _) =>
      pose[PotatoProp.headphones] = 1;

  @override
  Widget build(BuildContext context) {
    final size = GamePotatoFrame.splashPotatoSize(MediaQuery.sizeOf(context));
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: Center(
          child: SplashPotato(
            size: size,
            intro: false,
            decorate: _wearHeadphones,
          ),
        ),
      ),
    );
  }
}

class _MainPageBackground extends StatelessWidget {
  const _MainPageBackground({required this.reactions});

  final BackgroundReactions reactions;

  /// The stars speed follows the difficulty, but only in these steps, so
  /// this widget rebuilds a handful of times per round, not every frame.
  static const _speedSteps = 20;

  @override
  Widget build(BuildContext context) {
    final starsSize = min(MediaQuery.sizeOf(context).width * 0.1, 80.0);
    return BlocSelector<GameCubit, GameState, (int, double, int?)>(
      selector: (state) => (
        state.gameDifficultyModeIndex,
        switch (state.playingState) {
          PlayingStateGuide() || PlayingStatePlaying() =>
            0.5 +
                (state.difficultyLinear * _speedSteps).floor() /
                    _speedSteps *
                    1.5,
          PlayingStateNone() ||
          PlayingStatePaused() ||
          PlayingStateGameOver() ||
          PlayingStateLevelCleared() => 0.0,
        },
        state.level,
      ),
      builder: (context, values) {
        final (modeIndex, timeScale, level) = values;
        // A level's sky takes the colors of its song
        final songColors = level == null ? null : Levels.songOf(level).colors;
        return AnimatedBackgroundStars(
          backgroundColor: songColors == null
              ? GameColors.starsBackground[modeIndex]
              : Color.lerp(Color(songColors[1]), Colors.black, 0.45)!,
          starsColor: songColors == null
              ? GameColors.starsColors[modeIndex]
              : Color(songColors[0]),
          starsTimeScale: timeScale,
          starsSize: starsSize,
          reactions: reactions,
        );
      },
    );
  }
}
