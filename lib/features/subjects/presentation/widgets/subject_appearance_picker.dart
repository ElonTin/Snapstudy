import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/features/subjects/domain/constants/subject_presets.dart';

class SubjectAppearancePicker extends StatelessWidget {
  const SubjectAppearancePicker({
    super.key,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onColorChanged,
    required this.onIconChanged,
  });

  final Color selectedColor;
  final IconData selectedIcon;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<IconData> onIconChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Màu sắc', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: SubjectPresets.colors.map((color) {
            final selected = color.toARGB32() == selectedColor.toARGB32();
            return GestureDetector(
              onTap: () => onColorChanged(color),
              child: AnimatedContainer(
                duration: AppConstants.animationDuration,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Biểu tượng', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: SubjectPresets.icons.map((icon) {
            final selected = icon.codePoint == selectedIcon.codePoint;
            return GestureDetector(
              onTap: () => onIconChanged(icon),
              child: AnimatedContainer(
                duration: AppConstants.animationDuration,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? selectedColor.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? selectedColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? selectedColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
