import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n_helpers.dart';

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Readable message from a Supabase / Postgres exception.
String friendlyError(Object e) {
  final s = e.toString();
  final m = RegExp(r'message: ([^,}]+)').firstMatch(s);
  return (m?.group(1) ?? s).trim();
}

class CoverPicker extends StatelessWidget {
  final String? url;
  final bool uploading;
  final VoidCallback onTap;
  final String label;
  final double height;

  const CoverPicker({
    super.key,
    required this.url,
    required this.uploading,
    required this.onTap,
    required this.label,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: uploading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: url != null ? AppColors.teal : AppColors.cardBorder, width: url != null ? 1.5 : 1),
            image: url != null ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null,
          ),
          child: url != null && !uploading
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: AppColors.white, size: 16),
                  ),
                )
              : Center(
                  child: uploading
                      ? const CircularProgressIndicator(color: AppColors.teal)
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: AppColors.mutedText, size: 30),
                          const SizedBox(height: 6),
                          Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 12.5)),
                        ]),
                ),
        ),
      ),
    );
  }
}

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  const DatePickerField({super.key, required this.label, required this.value, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
        );
        if (d != null) onPicked(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          suffixIcon: value != null
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => onPicked(null))
              : null,
        ),
        isEmpty: value == null,
        child: Text(value != null ? formatDate(value) : '',
            style: const TextStyle(fontSize: 14, color: AppColors.deepNavy)),
      ),
    );
  }
}

/// Section title used inside long forms.
class FormSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  const FormSectionTitle(this.title, this.icon, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: AppColors.deepNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.deepNavy, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        ]),
      ),
    ]);
  }
}
