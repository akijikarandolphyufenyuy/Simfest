import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/services/plan_limits.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/chip_inputs.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../passport/models/passport.dart';
import '../../passport/screens/passport_screen.dart';
import '../../subscription/models/subscription.dart';
import '../models/opportunity.dart';

/// Checks the passport + posting allowance (the database enforces both too), then opens the form.
Future<void> openOpportunityForm(BuildContext context, WidgetRef ref, {Opportunity? existing}) async {
  if (existing == null) {
    if (!await requirePublishedPassport(context, ref)) return;
    if (!await canPostOpportunity()) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        await showUpgradeDialog(context, title: l10n.freePostUsedTitle, body: l10n.freePostUsedBody);
      }
      return;
    }
  }
  if (context.mounted) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => OpportunityFormScreen(existing: existing)));
  }
}

class OpportunityFormScreen extends ConsumerStatefulWidget {
  final Opportunity? existing;
  const OpportunityFormScreen({super.key, this.existing});

  @override
  ConsumerState<OpportunityFormScreen> createState() => _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends ConsumerState<OpportunityFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _location = TextEditingController(text: widget.existing?.location);
  late final _comp = TextEditingController(text: widget.existing?.compensation);
  late final _deliv = TextEditingController(text: widget.existing?.deliverables);
  late final _req = TextEditingController(text: widget.existing?.requirements);
  late final _positions = TextEditingController(text: '${widget.existing?.positions ?? 1}');
  late String _category = widget.existing?.category ?? 'recording';
  late String _type = widget.existing?.collaborationType ?? 'negotiable';
  late List<String> _roles = [...?widget.existing?.requiredRoles];
  late List<String> _skills = [...?widget.existing?.skills];
  late List<String> _genres = [...?widget.existing?.genres];
  late List<String> _links = [...?widget.existing?.referenceLinks];
  late bool _remote = widget.existing?.isRemote ?? true;
  late bool _restrict = widget.existing?.restrictToRoles ?? true;
  late DateTime? _projectDeadline = widget.existing?.projectDeadline;
  late DateTime? _appDeadline = widget.existing?.applicationDeadline;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _desc, _location, _comp, _deliv, _req, _positions]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    if (_roles.isEmpty) {
      showError(context, '${l10n.requiredRoles}: ${l10n.requiredField}');
      return;
    }
    setState(() => _saving = true);
    final row = opportunityRow(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      category: _category,
      requiredRoles: _roles,
      skills: _skills,
      genres: _genres,
      location: _t(_location),
      isRemote: _remote,
      collaborationType: _type,
      compensation: _t(_comp),
      deliverables: _t(_deliv),
      projectDeadline: _projectDeadline,
      applicationDeadline: _appDeadline,
      positions: (int.tryParse(_positions.text) ?? 1).clamp(1, 50),
      referenceLinks: _links,
      requirements: _t(_req),
      restrictToRoles: _restrict,
    );
    final db = Supabase.instance.client;
    try {
      if (widget.existing != null) {
        await db.from('collaboration_opportunities').update(row).eq('id', widget.existing!.id);
        ref.invalidate(opportunityProvider(widget.existing!.id));
      } else {
        await db.from('collaboration_opportunities').insert(row);
        ref.invalidate(entitlementProvider);
      }
      ref.invalidate(myOpportunitiesProvider);
      ref.invalidate(openOpportunitiesProvider);
      if (!mounted) return;
      showSuccess(context, widget.existing != null ? l10n.opportunityUpdated : l10n.opportunityPublished);
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      // RLS refused: the free allowance was used meanwhile (or the passport was unpublished).
      if (mounted && (e.code == '42501' || e.message.contains('row-level security'))) {
        await showUpgradeDialog(context, title: l10n.freePostUsedTitle, body: l10n.freePostUsedBody);
      } else if (mounted) {
        showError(context, friendlyError(e));
      }
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? req(String? v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null;
    const gap = SizedBox(height: 14);
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy, fontSize: 13.5)),
        );

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: GradientAppBar(title: widget.existing == null ? l10n.postOpportunity : l10n.editOpportunity),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FormSectionTitle(l10n.projectDescription, Icons.description_outlined),
                gap,
                TextFormField(
                  controller: _title,
                  maxLength: 100,
                  validator: req,
                  decoration: InputDecoration(labelText: '${l10n.opportunityTitle} *', hintText: l10n.opportunityTitleHint),
                ),
                gap,
                TextFormField(
                  controller: _desc,
                  maxLines: 5,
                  maxLength: 2000,
                  validator: req,
                  decoration: InputDecoration(labelText: '${l10n.projectDescription} *'),
                ),
                gap,
                label(l10n.projectCategory),
                SingleChoiceChips<String>(
                  options: kOpportunityCategories,
                  value: _category,
                  label: (c) => opportunityCategoryLabel(l10n, c),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 24),
                FormSectionTitle(l10n.requiredRoles, Icons.groups_2_outlined),
                gap,
                MultiChoiceChips<String>(
                  options: kPassportRoles,
                  selected: _roles,
                  label: (r) => passportRoleLabel(l10n, r),
                  max: 6,
                  onChanged: (v) => setState(() => _roles = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.teal,
                  title: Text(l10n.restrictToRoles, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.restrictToRolesHint, style: const TextStyle(fontSize: 12)),
                  value: _restrict,
                  onChanged: (v) => setState(() => _restrict = v),
                ),
                gap,
                TagInput(label: l10n.requiredSkills, hint: l10n.typeAndEnter, values: _skills, onChanged: (v) => setState(() => _skills = v)),
                gap,
                TagInput(label: l10n.genres, hint: l10n.typeAndEnter, values: _genres, onChanged: (v) => setState(() => _genres = v)),
                const SizedBox(height: 24),
                FormSectionTitle(l10n.collaborationType, Icons.handshake_outlined),
                gap,
                SingleChoiceChips<String>(
                  options: kArrangements,
                  value: _type,
                  label: (a) => arrangementLabel(l10n, a),
                  onChanged: (v) => setState(() => _type = v),
                ),
                gap,
                TextFormField(controller: _comp, decoration: InputDecoration(labelText: l10n.compensationArrangement, hintText: l10n.compensationHint)),
                gap,
                TextFormField(controller: _deliv, maxLines: 3, decoration: InputDecoration(labelText: l10n.expectedDeliverables)),
                const SizedBox(height: 24),
                FormSectionTitle(l10n.projectLocation, Icons.place_outlined),
                gap,
                TextFormField(controller: _location, decoration: InputDecoration(labelText: l10n.projectLocation, hintText: l10n.operatingLocationHint)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.teal,
                  title: Text(l10n.remoteCollaboration, style: const TextStyle(fontSize: 14)),
                  value: _remote,
                  onChanged: (v) => setState(() => _remote = v),
                ),
                gap,
                Row(children: [
                  Expanded(child: DatePickerField(label: l10n.projectDeadline, value: _projectDeadline, onPicked: (d) => setState(() => _projectDeadline = d))),
                  const SizedBox(width: 12),
                  Expanded(child: DatePickerField(label: l10n.applicationDeadline, value: _appDeadline, onPicked: (d) => setState(() => _appDeadline = d))),
                ]),
                gap,
                TextFormField(
                  controller: _positions,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                  decoration: InputDecoration(labelText: l10n.positionsNeeded),
                ),
                gap,
                TagInput(label: l10n.referenceLinks, hint: 'https://…', values: _links, max: 10, onChanged: (v) => setState(() => _links = v)),
                gap,
                TextFormField(controller: _req, maxLines: 3, decoration: InputDecoration(labelText: l10n.additionalRequirements)),
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(widget.existing == null ? l10n.publishOpportunity : l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
