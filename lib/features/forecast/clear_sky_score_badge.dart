import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ClearSkyScoreBadge extends StatelessWidget {
  final int score;
  final bool large;

  const ClearSkyScoreBadge({super.key, required this.score, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    final label = AppColors.scoreLabel(score);
    final fontSize = large ? 13.0 : 10.0;
    final scoreSize = large ? 22.0 : 17.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: scoreSize,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (large)
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }
}
