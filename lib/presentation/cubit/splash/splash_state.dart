part of 'splash_cubit.dart';

class SplashState extends Equatable {
  const SplashState({
    this.showingVersion = '',
    this.openNextPage = false,
    this.showUpdatePopup,
    this.versionIsAllowed = false,
  });

  final String showingVersion;
  final bool openNextPage;
  final UpdateInfo? showUpdatePopup;
  final bool versionIsAllowed;

  SplashState copyWith({
    String? showingVersion,
    bool? openNextPage,
    ValueWrapper<UpdateInfo>? showUpdatePopup,
    bool? versionIsAllowed,
  }) =>
      SplashState(
        showingVersion: showingVersion ?? this.showingVersion,
        openNextPage: openNextPage ?? this.openNextPage,
        showUpdatePopup: showUpdatePopup != null
            ? showUpdatePopup.value
            : this.showUpdatePopup,
        versionIsAllowed: versionIsAllowed ?? this.versionIsAllowed,
      );

  @override
  List<Object?> get props => [
        showingVersion,
        openNextPage,
        showUpdatePopup,
        versionIsAllowed,
      ];
}

class UpdateInfo with EquatableMixin {
  final bool forced;
  final String storeLink;

  UpdateInfo({
    required this.forced,
    required this.storeLink,
  });

  @override
  List<Object?> get props => [
        forced,
        storeLink,
      ];
}
