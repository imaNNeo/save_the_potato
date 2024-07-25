import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/main.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/presentation/pages/fade_route.dart';
import 'package:save_the_potato/presentation/widgets/background_stars.dart';
import 'package:save_the_potato/presentation/widgets/debug_panel.dart';
import 'package:save_the_potato/presentation/widgets/game_over_ui.dart';
import 'package:save_the_potato/presentation/widgets/game_paused_ui.dart';
import 'package:save_the_potato/presentation/widgets/high_score_widget.dart';
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

  late GameCubit _gameCubit;
  late SettingsCubit _settingsCubit;

  late StreamSubscription _streamSubscription;

  late PlayingState _previousState;

  OverlayEntry? _generalLoadingEntry;

  late StreamSubscription _generalLoadingSubscription;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    pageRootKey = UniqueKey();
    _gameCubit = context.read<GameCubit>();
    _settingsCubit = context.read<SettingsCubit>();
    _gameCubit.startToShowGuide();
    _game = PotatoGame(_gameCubit, _settingsCubit);
    _previousState = _gameCubit.state.playingState;
    _streamSubscription = _gameCubit.stream.listen((state) {
      if ((_previousState.isNone || _previousState.isGameOver) &&
          (state.playingState.isPlaying || state.playingState.isGuide)) {
        setState(() {
          _game = PotatoGame(_gameCubit, _settingsCubit);
        });
      }
      _previousState = state.playingState;
    });

    _generalLoadingSubscription =
        context.read<ScoresCubit>().stream.listen((state) {
      if (state.showAuthDialog) {
        BaseDialog.showAuthDialog(context);
      }
      if (state.showNicknameDialog) {
        BaseDialog.showNicknameDialog(context);
      }
      if (state.scoreShareLoading) {
        if (_generalLoadingEntry == null) {
          _generalLoadingEntry = OverlayEntry(
            builder: (context) => const LoadingOverlay(),
          );
          Overlay.of(context).insert(_generalLoadingEntry!);
        }
      } else {
        _generalLoadingEntry?.remove();
        _generalLoadingEntry = null;
      }
    });
    super.initState();
  }

  void _restartGameWidgets() {
    setState(() {
      pageRootKey = UniqueKey();
      _game = PotatoGame(_gameCubit, _settingsCubit);
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
      listener: (context, state) {
        if (state.restartGame) {
          _restartGameWidgets();
        }
        if (state.onNewHighScore != null) {
          context.read<ScoresCubit>().tryToRefreshLeaderboard();
          Navigator.of(context).push(
            FadeRoute(
              page: NewRankCelebrationPage(
                scoreEntity: state.onNewHighScore!,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.playingState.isPlaying,
          onPopInvoked: (didPop) async {
            if (didPop) {
              return;
            }
            _gameCubit.pauseGame(manually: true);
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                AnimatedBackgroundStars(
                  backgroundColor:
                      GameColors.starsBackground[state.gameDifficultyModeIndex],
                  starsColor:
                      GameColors.starsColors[state.gameDifficultyModeIndex],
                  starsTimeScale: 0.5 + (state.difficultyLinear * 1.5),
                ),
                gameWidget,
                const Align(
                  alignment: Alignment.topCenter,
                  child: PotatoTopBar(),
                ),
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: DebugPanel(),
                ),
                RotationControls(
                  showGuide: state.playingState.isGuide,
                  onLeftDown: _gameCubit.onLeftTapDown,
                  onLeftUp: _gameCubit.onLeftTapUp,
                  onRightDown: _gameCubit.onRightTapDown,
                  onRightUp: _gameCubit.onRightTapUp,
                ),
                if (state.playingState.isPaused) const GamePausedUI(),
                if (state.showGameOverUI) const GameOverUI(),
                const Align(
                  alignment: Alignment.topRight,
                  child: SettingsPauseIcon(),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: HighScoreWidget(),
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
    routeObserver.subscribe(
      this,
      ModalRoute.of(context) as PageRoute<dynamic>,
    );
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
