import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/hourly_slot.dart';
import '../../theme/app_theme.dart';

class HourlyConditionsGrid extends StatelessWidget {
  final List<HourlySlot> slots;
  final int selectedIndex;
  final void Function(int index) onRowTap;

  const HourlyConditionsGrid({
    super.key,
    required this.slots,
    this.selectedIndex = 0,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No dark hours available for this date.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        _HeaderRow(),
        const SizedBox(height: 4),
        const Divider(height: 1),
        const SizedBox(height: 4),
        // Data rows — scrollable so long nights don't overflow the 220px container
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slots.asMap().entries.map((e) => _SlotRow(
                    slot: e.value,
                    isSelected: e.key == selectedIndex,
                    onTap: () => onRowTap(e.key),
                  )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Cell('TIME', flex: 2, header: true),
        _Cell('CLOUD', flex: 2, header: true),
        _Cell('VISIBILITY', flex: 2, header: true),
        _Cell('TRANSP', flex: 2, header: true),
        _Cell('HUM', flex: 1, header: true),
        _Cell('WIND', flex: 2, header: true),
        _Cell('SCORE', flex: 2, header: true),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  final HourlySlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SlotRow({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = slot.clearSkyScore;
    final scoreColor = AppColors.scoreColor(score);
    final timeStr = DateFormat('HH:mm').format(slot.time.toLocal());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            // Time
            _Cell(timeStr, flex: 2),
            // Cloud cover bar
            Expanded(
              flex: 2,
              child: _CloudBar(pct: slot.cloudCoverTotal),
            ),
            // Visibility (seeing) dots — RAG coloured
            Expanded(
              flex: 2,
              child: _DotRating(value: slot.seeing, max: 5, useRag: true),
            ),
            // Transparency dots — RAG coloured
            Expanded(
              flex: 2,
              child: _DotRating(value: slot.transparency, max: 5, useRag: true),
            ),
            // Humidity
            _Cell(
              '${slot.humidity}%',
              flex: 1,
              color: slot.isDewRisk ? AppColors.scoreAmber : AppColors.textSecondary,
            ),
            // Wind
            _Cell(
              '${slot.windSpeedKnots.round()} kn',
              flex: 2,
              color: slot.isWindy ? AppColors.scoreAmber : AppColors.textSecondary,
            ),
            // Score
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$score',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool header;
  final Color? color;

  const _Cell(this.text, {required this.flex, this.header = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: header
              ? AppColors.textMuted
              : (color ?? AppColors.textSecondary),
          fontSize: header ? 9 : 11,
          fontWeight: header ? FontWeight.w600 : FontWeight.normal,
          letterSpacing: header ? 0.5 : 0,
        ),
      ),
    );
  }
}

class _CloudBar extends StatelessWidget {
  final int pct;
  const _CloudBar({required this.pct});

  Color get _barColor {
    if (pct <= 20) return AppColors.scoreExcellent;
    if (pct <= 40) return AppColors.scoreGood;
    if (pct <= 60) return AppColors.scoreFair;
    if (pct <= 80) return AppColors.scoreAmber;
    return AppColors.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$pct%',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _DotRating extends StatelessWidget {
  final int value;
  final int max;
  final bool useRag;
  const _DotRating({required this.value, required this.max, this.useRag = false});

  Color _filledColor() {
    if (!useRag) return AppColors.primary;
    if (value <= 2) return Colors.red.shade400;
    if (value == 3) return Colors.amber.shade400;
    return Colors.green.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final filledColor = _filledColor();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (i) {
        final filled = i < value;
        final color = filled ? filledColor : AppColors.surfaceBorder;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
