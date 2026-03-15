import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ClearSkyScoreBadge extends StatelessWidget {
  final int score;
  final bool large;

  const ClearSkyScoreBadge({super.key, required this.score, this.large = false});

  String _scoreEmoji(int s) {
    if (s >= 90) return '🤩';
    if (s >= 80) return '😄';
    if (s >= 65) return '🙂';
    if (s >= 50) return '😐';
    if (s >= 35) return '😟';
    if (s >= 20) return '😢';
    return '😭';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    final emojiSize = large ? 26.0 : 22.0;
    final pctSize = large ? 11.0 : 9.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _scoreEmoji(score),
          style: TextStyle(fontSize: emojiSize, height: 1.1),
        ),
        Text(
          '$score%',
          style: TextStyle(
            color: color,
            fontSize: pctSize,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
