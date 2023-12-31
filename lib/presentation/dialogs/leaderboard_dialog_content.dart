import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';

class LeaderboardDialogContent extends StatelessWidget {
  const LeaderboardDialogContent({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: state.isAnonymous ? 320 : 680,
          ),
          width: double.infinity,
          child: Stack(
            children: [
              // ListView.builder(
              //   itemBuilder: (context, index) {
              //     return ScoreRow(
              //       playerName: 'Player $index',
              //       playerScore: '00:0$index',
              //       isMe: index == 0,
              //     );
              //   },
              //   itemCount: 10,
              // ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 104,
                        color: Colors.yellow,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'LOGIN TO SAVE YOUR SCORE',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: context.read<AuthCubit>().login,
                        child: const Text('LOGIN'),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class ScoreRow extends StatelessWidget {
  const ScoreRow({
    super.key,
    required this.playerName,
    required this.playerScore,
    required this.isMe,
  }) : super();

  final String playerName;
  final String playerScore;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: isMe ? 4 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            playerName,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.white.withOpacity(0.8),
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          Expanded(child: Container()),
          Text(
            playerScore,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.white.withOpacity(0.8),
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
