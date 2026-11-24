import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/passport.dart';

/// Add / edit / delete one portfolio entry (saved immediately).
Future<void> showPortfolioItemSheet(BuildContext context, WidgetRef ref, {PortfolioItem? existing, int sortOrder = 0}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _PortfolioSheet(existing: existing, sortOrder: sortOrder, onSaved: () => ref.invalidate(myPortfolioProvider)),
  );
}

class _PortfolioSheet extends StatefulWidget {
  final PortfolioItem? existing;
  final int sortOrder;
  final VoidCallback onSaved;
  const _PortfolioSheet({this.existing, required this.sortOrder, required this.onSaved});

  @override
  State<_PortfolioSheet> createState() => _PortfolioSheetState();
}

class _PortfolioSheetState extends State<_PortfolioSheet> {
  late String _kind = widget.existing?.kind ?? 'release';
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _role = TextEditingController(text: widget.existing?.role);
  late final _year = TextEditingController(text: widget.existing?.year?.toString());
  late final _url = TextEditingController(text: widget.existing?.url);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late String? _image = widget.existing?.imageUrl;
  late bool _public = widget.existing?.isPublic ?? true;
  bool _busy = false;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void dispose() {
    for (final c in [_title, _role, _year, _url, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked =
        await afterTap(() => ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85));
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final url = await uploadPassportImage(await picked.readAsBytes(), picked.name.split('.').last.toLowerCase());
      if (mounted) setState(() => _image = url);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_title.text.trim().isEmpty) {
      showError(context, '${l10n.itemTitle}: ${l10n.requiredField}');
      return;
    }
    setState(() => _busy = true);
    final row = PortfolioItem(
      kind: _kind,
      title: _title.text.trim(),
      role: _role.text.trim().isEmpty ? null : _role.text.trim(),
      year: int.tryParse(_year.text.trim()),
      url: _url.text.trim().isEmpty ? null : _url.text.trim(),
      imageUrl: _image,
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      isPublic: _public,
      sortOrder: widget.existing?.sortOrder ?? widget.sortOrder,
    ).toRow();
    try {
      if (widget.existing?.id != null) {
        await _db.from('passport_portfolio_items').update(row).eq('id', widget.existing!.id!);
      } else {
        await _db.from('passport_portfolio_items').insert(row);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await _db.from('passport_portfolio_items').delete().eq('id', widget.existing!.id!);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.existing == null ? l10n.addPortfolioItem : l10n.editPortfolioItem,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.portfolioKind),
                      items: [
                        for (final k in kPortfolioKinds)
                          DropdownMenuItem(value: k, child: Text(portfolioKindLabel(l10n, k)))
                      ],
                      onChanged: (v) => setState(() => _kind = v ?? _kind),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _title, decoration: InputDecoration(labelText: '${l10n.itemTitle} *')),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          flex: 2,
                          child: TextField(
                              controller: _role, decoration: InputDecoration(labelText: l10n.itemRoleOptional))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _year,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4)
                          ],
                          decoration: InputDecoration(labelText: l10n.itemYear),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _url,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(labelText: l10n.itemLink)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _desc,
                        maxLines: 3,
                        maxLength: 400,
                        decoration: InputDecoration(labelText: l10n.itemDescription)),
                    Row(children: [
                      if (_image != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(_image!, width: 56, height: 56, fit: BoxFit.cover),
                          ),
                        ),
                      // Expanded: the theme gives buttons infinite min width, which a Row can't lay out.
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _pickImage,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
                              : const Icon(Icons.image_outlined),
                          label: Text(l10n.addImage),
                        ),
                      ),
                    ]),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.teal,
                      title: Text(l10n.showOnPublicPassport, style: const TextStyle(fontSize: 14)),
                      value: _public,
                      onChanged: (v) => setState(() => _public = v),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (widget.existing != null)
                        IconButton(
                          onPressed: _busy ? null : _delete,
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          tooltip: l10n.delete,
                        ),
                      const Spacer(),
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                        onPressed: _busy ? null : _save,
                        child: Text(l10n.save),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
