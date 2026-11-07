part of 'splash_cubit.dart';

class SplashState extends Equatable {
  const SplashState({
    this.showingVersion = '',
    this.openNextPage = false,
    this.showUpdatePopup,
    this.versionIsAllowed = false,
    this.loadingProgress = 0,
  });

  final String showingVersion;
  final bool openNextPage;
  final UpdateInfo? showUpdatePopup;
  final bool versionIsAllowed;

  /// How much of what the splash waits for is loaded, 0..1
  final double loadingProgress;

  SplashState copyWith({
    String? showingVersion,
    bool? openNextPage,
    ValueWrapper<UpdateInfo>? showUpdatePopup,
    bool? versionIsAllowed,
    double? loadingProgress,
  }) => SplashState(
    showingVersion: showingVersion ?? this.showingVersion,
    openNextPage: openNextPage ?? this.openNextPage,
    showUpdatePopup: showUpdatePopup != null
        ? showUpdatePopup.value
        : this.showUpdatePopup,
    versionIsAllowed: versionIsAllowed ?? this.versionIsAllowed,
    loadingProgress: loadingProgress ?? this.loadingProgress,
  );

  @override
  List<Object?> get props => [
    showingVersion,
    openNextPage,
    showUpdatePopup,
    versionIsAllowed,
    loadingProgress,
  ];
}

class UpdateInfo with Equatable {
  final bool forced;
  final String storeLink;

  UpdateInfo({required this.forced, required this.storeLink});

  @override
  List<Object?> get props => [forced, storeLink];
}
