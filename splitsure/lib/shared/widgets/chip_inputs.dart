import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Free-text tags (genres, skills, instruments…): type, press Enter or comma to add.
class TagInput extends StatefulWidget {
  final String label;
  final String? hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final List<String> suggestions;
  final int max;

  const TagInput({
    super.key,
    required this.label,
    this.hint,
    required this.values,
    required this.onChanged,
    this.suggestions = const [],
    this.max = 20,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final next = [...widget.values];
    for (final p in parts) {
      if (next.length >= widget.max) break;
      if (!next.any((v) => v.toLowerCase() == p.toLowerCase())) next.add(p);
    }
    _ctrl.clear();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final unused = widget.suggestions
        .where((s) => !widget.values.any((v) => v.toLowerCase() == s.toLowerCase()))
        .take(10)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _ctrl,
        textInputAction: TextInputAction.done,
        onSubmitted: _add,
        onChanged: (v) {
          if (v.endsWith(',')) _add(v);
        },
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          suffixIcon: IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _add(_ctrl.text)),
        ),
      ),
      if (widget.values.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in widget.values)
            Chip(
              label: Text(v),
              backgroundColor: AppColors.teal.withValues(alpha: 0.1),
              side: BorderSide.none,
              labelStyle: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w600, fontSize: 12.5),
              onDeleted: () => widget.onChanged([...widget.values]..remove(v)),
              deleteIconColor: AppColors.mutedText,
            ),
        ]),
      ],
      if (unused.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final s in unused)
            ActionChip(
              label: Text('+ $s', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.cardBorder),
              onPressed: () => _add(s),
            ),
        ]),
      ],
    ]);
  }
}

/// Pick several values from a fixed list.
class MultiChoiceChips<T> extends StatelessWidget {
  final List<T> options;
  final List<T> selected;
  final String Function(T) label;
  final ValueChanged<List<T>> onChanged;
  final int? max;

  const MultiChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in options)
        FilterChip(
          label: Text(label(o)),
          selected: selected.contains(o),
          showCheckmark: false,
          selectedColor: AppColors.teal,
          backgroundColor: Colors.white,
          side: BorderSide(color: selected.contains(o) ? AppColors.teal : AppColors.cardBorder),
          labelStyle: TextStyle(
            color: selected.contains(o) ? Colors.white : AppColors.deepNavy,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
          onSelected: (on) {
            if (on && max != null && selected.length >= max!) return;
            onChanged(on ? [...selected, o] : ([...selected]..remove(o)));
          },
        ),
    ]);
  }
}

/// Pick exactly one value from a fixed list.
class SingleChoiceChips<T> extends StatelessWidget {
  final List<T> options;
  final T? value;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const SingleChoiceChips({super.key, required this.options, required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in options)
        ChoiceChip(
          label: Text(label(o)),
          selected: value == o,
          showCheckmark: false,
          selectedColor: AppColors.deepNavy,
          backgroundColor: Colors.white,
          side: BorderSide(color: value == o ? AppColors.deepNavy : AppColors.cardBorder),
          labelStyle: TextStyle(
            color: value == o ? Colors.white : AppColors.deepNavy,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
          onSelected: (_) => onChanged(o),
        ),
    ]);
  }
}
