part of 'splash_cubit.dart';

class SplashState extends Equatable {
  const SplashState({
    this.showingVersion = '',
    this.openNextPage = false,
  });

  final String showingVersion;
  final bool openNextPage;

  SplashState copyWith({
    String? showingVersion,
    bool? openNextPage,
  }) =>
      SplashState(
        showingVersion: showingVersion ?? this.showingVersion,
        openNextPage: openNextPage ?? this.openNextPage,
      );

  @override
  List<Object?> get props => [
        showingVersion,
        openNextPage,
      ];
}

