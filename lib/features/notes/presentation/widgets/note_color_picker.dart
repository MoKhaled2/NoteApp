import 'package:flutter/material.dart';

class NoteColorPicker extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorChanged;

  const NoteColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  static const List<int> colors = [
    0xFFFFFFFF, // White
    0xFFF28B82, // Red
    0xFFFBBC04, // Orange
    0xFFFFF475, // Yellow
    0xFFCCFF90, // Green
    0xFFA7FFEB, // Teal
    0xFFCBF0F8, // Cyan
    0xFFAECBFA, // Blue
    0xFFD7AEFB, // Purple
    0xFFFDCFE8, // Pink
    0xFFE6C9A8, // Brown
    0xFFE8EAED, // Grey
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = color == selectedColor;
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(color).withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.black54)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
