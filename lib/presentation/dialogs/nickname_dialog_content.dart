import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';

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
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.updateUserError.isNotEmpty) {
          AppUtils.showWarningToast(context, state.updateUserError);
        }
        if (state.updateUserSucceeds.isNotEmpty) {
          AppUtils.showSuccessToast(context, state.updateUserSucceeds);
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
                hintText: "Your nickname",
                fillColor: Colors.transparent,
              ),
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
                  context.read<AuthCubit>().updateNickname(_controller.text);
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
