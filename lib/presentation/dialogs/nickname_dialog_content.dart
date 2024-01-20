import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/configs/configs_cubit.dart';
import 'package:save_the_potato/presentation/formatters/custom_regex_formatter.dart';
import 'package:toastification/toastification.dart';

class NicknameDialogContent extends StatefulWidget {
  const NicknameDialogContent({super.key}) : super();

  @override
  State<NicknameDialogContent> createState() => _NicknameDialogContentState();
}

class _NicknameDialogContentState extends State<NicknameDialogContent> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    _controller.text = context.read<AuthCubit>().state.user!.nickname;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigsCubit, ConfigsState>(
      builder: (context, configsState) {
        return BlocConsumer<AuthCubit, AuthState>(
          listener: (_, authState) {
            if (authState.updateUserError.isNotEmpty) {
              authState.updateUserError.showAsToast(
                context,
                alignment: Alignment.topCenter,
                type: ToastificationType.warning,
              );
            }
            if (authState.updateUserSucceeds.isNotEmpty) {
              authState.updateUserSucceeds.showAsToast(
                context,
                type: ToastificationType.success,
              );
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    hintStyle: TextStyle(color: Colors.grey[800]),
                    hintText: 'Your nickname',
                    fillColor: Colors.transparent,
                    counterText: '',
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: configsState.gameConfig.nicknameMaxLength,
                  inputFormatters: [
                    CustomRegexFormatter(
                      configsState.gameConfig.nicknameAllowedRegex,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: 118,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_controller.text.isEmpty ||
                          _controller.text == state.user!.nickname) {
                        Navigator.of(context).pop();
                        return;
                      }
                      context
                          .read<AuthCubit>()
                          .updateNickname(_controller.text);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: state.updateUserLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontSize: 20),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
