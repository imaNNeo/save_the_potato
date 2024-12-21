import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/extensions/string_extensions.dart';
import 'package:toastification/toastification.dart';

import 'errors/domain_error.dart';

/// Responsible to hold the information to show a message in presentation layer,
/// So we can have a reference of this class in our domain layer
/// When presentation wants to show it, we need to pass the context to parse it
/// At this time, we only have [RawTextMessage].
/// Later we can add [LocalizedMessage] which needs context to parse the localized message
abstract class PresentationMessage with EquatableMixin {
  String parse(BuildContext context);

  void showAsToast(
    BuildContext context, {
    ToastificationType type = ToastificationType.info,
    AlignmentGeometry alignment = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 5),
    ToastificationStyle style = ToastificationStyle.flatColored,
  }) =>
      toastification.show(
        context: context,
        autoCloseDuration: duration,
        title: Text(parse(context)),
        type: type,
        alignment: alignment,
        style: style,
      );

  static const empty = RawTextMessage('');

  const PresentationMessage();

  bool get isNotEmpty => !isEmpty;

  bool get isEmpty => switch (this) {
        RawTextMessage(rawText: String rawText) => rawText.isBlank,
        PresentationMessage() => throw UnimplementedError(),
      };

  static PresentationMessage raw(String rawText) => RawTextMessage(rawText);

  static PresentationMessage fromError(dynamic e) {
    if (e is! DomainError) {
      return const RawTextMessage('Unknown error');
    }
    return switch (e) {
      NetworkError() => const RawTextMessage('Network error'),
      ServerError(errorEntry: ServerErrorEntry error) =>
        error.detailsOrMessage.isNotNullOrBlank
            ? PresentationMessage.raw(error.detailsOrMessage!)
            : PresentationMessage.raw('Server error'),
      ServerError(errorEntry: null) => PresentationMessage.raw('Server error'),
      UnknownError() =>
        const RawTextMessage('Unknown error'),
    };
  }
}

class RawTextMessage extends PresentationMessage {
  final String rawText;

  const RawTextMessage(this.rawText);

  @override
  String parse(BuildContext context) => rawText;

  @override
  List<Object?> get props => [rawText];
}
