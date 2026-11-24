import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/plan_limits.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../projects/models/project.dart';
import '../../projects/screens/project_form_screen.dart';
import '../models/agreement.dart';
import '../providers/agreements_provider.dart';
import 'agreement_detail_screen.dart';
import '../../dealflow/models/workspace.dart' show linkWorkspaceAgreement;

/// Terms agreed in a DealFlow workspace, used to pre-fill a new agreement.
class AgreementPrefill {
  final String workspaceId;
  final String title;
  final String? description;
  final String? paymentTerms;
  final List<({String userId, String name, String role, String? responsibilities, double percentage})> members;
  const AgreementPrefill({
    required this.workspaceId,
    required this.title,
    this.description,
    this.paymentTerms,
    required this.members,
  });
}

/// Create a new agreement (optionally inside a [project]) or edit an existing [agreement].
class CreateAgreementScreen extends ConsumerStatefulWidget {
  final Project? project;
  final Agreement? agreement;
  final AgreementPrefill? prefill;
  const CreateAgreementScreen({super.key, this.project, this.agreement, this.prefill});

  @override
  ConsumerState<CreateAgreementScreen> createState() => _CreateAgreementScreenState();
}

class _SplitControllers {
  final String? id;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final customRole = TextEditingController();
  final desc = TextEditingController();
  final pct = TextEditingController();
  String? roleChoice; // one of kMusicRoles; 'Other' uses [customRole]
  final String? userId; // set when the collaborator is already a SplitSure member (DealFlow)

  _SplitControllers({this.id, this.userId});

  String get role => roleChoice == 'Other' ? customRole.text.trim() : (roleChoice ?? '');

  void setRole(String value) {
    if (kMusicRoles.contains(value) && value != 'Other') {
      roleChoice = value;
    } else {
      roleChoice = 'Other';
      customRole.text = value;
    }
  }

  void dispose() {
    for (final c in [name, email, phone, customRole, desc, pct]) {
      c.dispose();
    }
  }
}

class _CreateAgreementScreenState extends ConsumerState<CreateAgreementScreen> {
  static const _steps = 4;
  final _formKeys = List.generate(_steps, (_) => GlobalKey<FormState>());
  final _pageController = PageController();
  int _step = 0;
  bool _saving = false;

  // Step 1 – song / project
  String? _projectId;
  final _title = TextEditingController();
  final _genre = TextEditingController();
  final _desc = TextEditingController();
  DateTime? _recordingDate, _releaseDate, _effectiveDate;
  String? _cover;
  bool _uploadingCover = false;

  // Step 2 – collaborators
  final List<_SplitControllers> _splits = [];

  // Step 3 – scope & terms
  final Set<String> _scope = {};
  final _scopeDetails = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _terms = TextEditingController();

  // Step 4 – witness / lawyer
  bool _addWitness = false, _addLawyer = false;
  final _wName = TextEditingController(), _wEmail = TextEditingController();
  final _wPhone = TextEditingController(), _wRole = TextEditingController();
  final _lName = TextEditingController(), _lFirm = TextEditingController();
  final _lEmail = TextEditingController(), _lPhone = TextEditingController(), _lReg = TextEditingController();

  bool get _isEdit => widget.agreement != null;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  double get _total => _splits.fold(0.0, (s, c) => s + (double.tryParse(c.pct.text.replaceAll(',', '.')) ?? 0));

  @override
  void initState() {
    super.initState();
    final a = widget.agreement;
    if (a != null) {
      _projectId = a.projectId;
      _title.text = a.songTitle;
      _genre.text = a.genre ?? '';
      _desc.text = a.description ?? '';
      _recordingDate = DateTime.tryParse(a.recordingDate ?? '');
      _releaseDate = DateTime.tryParse(a.releaseDate ?? '');
      _effectiveDate = DateTime.tryParse(a.effectiveDate ?? '');
      _cover = a.coverArtUrl;
      _scope.addAll(a.scopeCategories);
      _scopeDetails.text = a.scopeOfRights ?? '';
      _paymentTerms.text = a.paymentTerms ?? '';
      _terms.text = a.additionalTerms ?? '';
      _addWitness = a.witnessName != null;
      _wName.text = a.witnessName ?? '';
      _wEmail.text = a.witnessEmail ?? '';
      _wPhone.text = a.witnessPhone ?? '';
      _wRole.text = a.witnessRole ?? '';
      _addLawyer = a.lawyerName != null;
      _lName.text = a.lawyerName ?? '';
      _lFirm.text = a.lawyerFirm ?? '';
      _lEmail.text = a.lawyerEmail ?? '';
      _lPhone.text = a.lawyerPhone ?? '';
      _lReg.text = a.lawyerRegistration ?? '';
      for (final s in a.splits) {
        final c = _SplitControllers(id: s.id)
          ..name.text = s.collaboratorName
          ..email.text = s.collaboratorEmail ?? ''
          ..phone.text = s.phone ?? ''
          ..desc.text = s.contributionDescription ?? ''
          ..pct.text = s.splitPercentage.toStringAsFixed(s.splitPercentage % 1 == 0 ? 0 : 2);
        c.setRole(s.role);
        _splits.add(c);
      }
    } else if (widget.prefill != null) {
      final pf = widget.prefill!;
      _title.text = pf.title;
      _desc.text = pf.description ?? '';
      _paymentTerms.text = pf.paymentTerms ?? '';
      final me = Supabase.instance.client.auth.currentUser;
      for (final m in pf.members) {
        final c = _SplitControllers(userId: m.userId)
          ..name.text = m.name
          ..email.text = m.userId == me?.id ? (me?.email ?? '') : ''
          ..desc.text = m.responsibilities ?? ''
          ..pct.text = m.percentage.toStringAsFixed(m.percentage % 1 == 0 ? 0 : 2);
        c.setRole(m.role);
        _splits.add(c);
      }
    } else {
      if (widget.project != null) _applyProject(widget.project!);
      // Start with the creator as the first collaborator line.
      final user = Supabase.instance.client.auth.currentUser;
      final meta = user?.userMetadata ?? {};
      _splits.add(_SplitControllers()
        ..name.text = [meta['first_name'], meta['last_name']].whereType<String>().join(' ').trim()
        ..email.text = user?.email ?? '');
    }
  }

  void _applyProject(Project p) {
    _projectId = p.id;
    _title.text = p.title;
    _genre.text = p.genre ?? _genre.text;
    _desc.text = p.description ?? _desc.text;
    _cover = p.coverArtUrl ?? _cover;
    _recordingDate = DateTime.tryParse(p.recordingDate ?? '') ?? _recordingDate;
    _releaseDate = DateTime.tryParse(p.releaseDate ?? '') ?? _releaseDate;
  }

  @override
  void dispose() {
    for (final c in [
      _title, _genre, _desc, _scopeDetails, _paymentTerms, _terms,
      _wName, _wEmail, _wPhone, _wRole, _lName, _lFirm, _lEmail, _lPhone, _lReg,
    ]) {
      c.dispose();
    }
    for (final s in _splits) {
      s.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  bool _validateStep(int i) {
    if (!(_formKeys[i].currentState?.validate() ?? true)) return false;
    if (i == 1) {
      if (_splits.isEmpty) {
        showError(context, l10n.addAtLeastOneCollaborator);
        return false;
      }
      if (_total > 100.0001) {
        showError(context, l10n.splitsExceed100);
        return false;
      }
    }
    return true;
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;
    if (_step < _steps - 1) {
      _goTo(_step + 1);
    } else {
      await _save();
    }
  }

  AgreementDraft _draft() {
    String? opt(bool on, TextEditingController c) => on ? c.text : null;
    String? date(DateTime? d) => d?.toIso8601String().split('T').first;
    String? n(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return AgreementDraft(
      songTitle: _title.text,
      projectId: _projectId,
      description: _desc.text,
      genre: _genre.text,
      coverArtUrl: _cover,
      recordingDate: date(_recordingDate),
      releaseDate: date(_releaseDate),
      effectiveDate: date(_effectiveDate),
      scopeOfRights: _scopeDetails.text,
      scopeCategories: _scope.toList(),
      paymentTerms: _paymentTerms.text,
      additionalTerms: _terms.text,
      witnessName: opt(_addWitness, _wName),
      witnessEmail: opt(_addWitness, _wEmail),
      witnessPhone: opt(_addWitness, _wPhone),
      witnessRole: opt(_addWitness, _wRole),
      lawyerName: opt(_addLawyer, _lName),
      lawyerFirm: opt(_addLawyer, _lFirm),
      lawyerEmail: opt(_addLawyer, _lEmail),
      lawyerPhone: opt(_addLawyer, _lPhone),
      lawyerRegistration: opt(_addLawyer, _lReg),
      splits: _splits
          .map((s) => <String, dynamic>{
                if (s.id != null) 'id': s.id,
                if (s.userId != null) 'user_id': s.userId,
                'collaborator_name': s.name.text.trim(),
                'collaborator_email': n(s.email)?.toLowerCase(),
                'phone': n(s.phone),
                'role': s.role,
                'contribution_description': n(s.desc),
                'split_percentage': double.parse(s.pct.text.replaceAll(',', '.')),
              })
          .toList(),
    );
  }

  Future<void> _save() async {
    for (var i = 0; i < _steps; i++) {
      if (!_validateStep(i)) {
        _goTo(i);
        return;
      }
    }
    if (!_isEdit && !await checkPlanLimit(context, PlanLimit.agreements)) return;
    setState(() => _saving = true);
    try {
      final a = widget.agreement;
      if (a == null) {
        final created = await createAgreement(_draft());
        if (widget.prefill != null) await linkWorkspaceAgreement(widget.prefill!.workspaceId, created.id);
        ref.invalidate(agreementsProvider);
        if (!mounted) return;
        showSuccess(context, l10n.agreementSavedDraft);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreement: created)));
      } else {
        var newVersion = false;
        var emailed = 0;
        String? note;
        if (a.status != 'draft') {
          // Already sent: the edits become a new version and everyone is asked again.
          note = await _askChangeNote();
          if (note == '__cancel__') return;
        }
        await updateAgreement(a.id, _draft(), existingSplitIds: a.splits.map((s) => s.id).toList());
        if (a.status != 'draft') {
          emailed = (await sendForReview(a.id, note: note)).emailed;
          newVersion = true;
        }
        ref.invalidate(agreementsProvider);
        ref.invalidate(agreementProvider(a.id));
        if (!mounted) return;
        showSuccess(
            context,
            !newVersion
                ? l10n.changesSaved
                : (emailed > 0 ? l10n.newVersionSentEmailed(emailed) : l10n.newVersionSent));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      // The server enforces the plan limit too (row-level security on insert).
      if (widget.agreement == null && '$e'.contains('row-level security')) {
        await showUpgradeDialog(context, body: l10n.planAgreementLimitBody);
      } else {
        showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Returns the note, null for no note, or '__cancel__' if the dialog was dismissed.
  Future<String?> _askChangeNote() async {
    final c = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.newVersionTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.newVersionExplain, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: c, maxLines: 3, decoration: InputDecoration(labelText: l10n.changeNoteOptional)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, '__cancel__'), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(l10n.sendNewVersion),
          ),
        ],
      ),
    );
    if (note == null) return '__cancel__';
    return note.isEmpty ? null : note;
  }

  @override
  Widget build(BuildContext context) {
    final titles = [l10n.songInformation, l10n.collaboratorsAndSplits, l10n.scopeAndTerms, l10n.witnessLegalRep];
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: GradientAppBar(
        title: _isEdit ? l10n.editAgreement : l10n.newAgreement,
        bottomHeight: 46,
        bottom: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(titles[_step],
                        key: ValueKey(_step),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                Text(l10n.stepOfN('${_step + 1}', '$_steps'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (_step + 1) / _steps),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                  ),
                ),
              ),
            ]),
          ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _stepWrap(0, _buildSongStep()),
          _stepWrap(1, _buildSplitsStep()),
          _stepWrap(2, _buildScopeStep()),
          _stepWrap(3, _buildWitnessStep()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _goTo(_step - 1),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(l10n.back),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saving ? null : _next,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepNavy, minimumSize: const Size(0, 52)),
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(_step < _steps - 1 ? l10n.next : (_isEdit ? l10n.saveChanges : l10n.saveAsDraft)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stepWrap(int i, Widget child) => Form(
        key: _formKeys[i],
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [child]),
          ),
        ),
      );

  // ── Step 1 ────────────────────────────────────────────────────────────────

  Widget _buildSongStep() {
    final projects = ref.watch(projectsProvider).whenOrNull(data: (l) => l) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<String?>(
        initialValue: projects.any((p) => p.id == _projectId) ? _projectId : null,
        isExpanded: true,
        decoration:
            InputDecoration(labelText: l10n.musicProjectOptional, prefixIcon: const Icon(Icons.library_music_outlined)),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.noProject)),
          for (final p in projects) DropdownMenuItem(value: p.id, child: Text(p.title, overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: '__new__', child: Text('+ ${l10n.createProject}')),
        ],
        onChanged: (v) async {
          if (v == '__new__') {
            final p = await Navigator.push<Project>(context, MaterialPageRoute(builder: (_) => const ProjectFormScreen()));
            ref.invalidate(projectsProvider);
            if (p != null) setState(() => _applyProject(p));
            return;
          }
          setState(() {
            _projectId = v;
            final p = projects.where((e) => e.id == v).firstOrNull;
            if (p != null) _applyProject(p);
          });
        },
      ),
      const SizedBox(height: 14),
      CoverPicker(
        url: _cover,
        uploading: _uploadingCover,
        height: 130,
        label: l10n.uploadCoverArtOptional,
        onTap: () async {
          setState(() => _uploadingCover = true);
          try {
            final uid = Supabase.instance.client.auth.currentUser!.id;
            final url = await uploadCoverArt(bucket: 'agreement-assets', folder: uid);
            if (url != null) setState(() => _cover = url);
          } catch (e) {
            if (mounted) showError(context, l10n.uploadError('$e'));
          } finally {
            if (mounted) setState(() => _uploadingCover = false);
          }
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _title,
        decoration: InputDecoration(labelText: l10n.songTitleRequired, prefixIcon: const Icon(Icons.music_note_outlined)),
        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
      ),
      const SizedBox(height: 14),
      TextFormField(controller: _genre, decoration: InputDecoration(labelText: l10n.musicGenre, hintText: l10n.musicGenreHint)),
      const SizedBox(height: 14),
      TextFormField(controller: _desc, maxLines: 3, decoration: InputDecoration(labelText: l10n.songDescription)),
      const SizedBox(height: 14),
      DatePickerField(label: l10n.recordingDate, value: _recordingDate, onPicked: (d) => setState(() => _recordingDate = d)),
      const SizedBox(height: 14),
      DatePickerField(
          label: l10n.expectedReleaseDate, value: _releaseDate, onPicked: (d) => setState(() => _releaseDate = d)),
      const SizedBox(height: 14),
      DatePickerField(label: l10n.effectiveDate, value: _effectiveDate, onPicked: (d) => setState(() => _effectiveDate = d)),
      const SizedBox(height: 18),
      _Notice(text: l10n.legalInfoNotice, color: AppColors.teal, icon: Icons.info_outline),
    ]);
  }

  // ── Step 2 ────────────────────────────────────────────────────────────────

  Widget _buildSplitsStep() {
    final total = _total;
    final remaining = 100 - total;
    final ok = (total - 100).abs() < 0.001;
    final over = total > 100.0001;
    final color = ok ? AppColors.teal : (over ? Colors.red : Colors.orange);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                  l10n.splitTotalRemaining(total.toStringAsFixed(0), remaining.clamp(0, 100).toStringAsFixed(0)),
                  style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            ),
            Icon(ok ? Icons.check_circle_rounded : Icons.pie_chart_outline_rounded, color: color),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (total / 100).clamp(0, 1)),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ok ? l10n.splitsReady : (over ? l10n.splitsExceed100 : l10n.splitsMustReach100),
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < _splits.length; i++)
        _SplitCard(
          key: ObjectKey(_splits[i]),
          index: i,
          c: _splits[i],
          onRemove: _splits.length > 1 ? () => setState(() => _splits.removeAt(i).dispose()) : null,
          onChanged: () => setState(() {}),
        ),
      OutlinedButton.icon(
        onPressed: () => setState(() => _splits.add(_SplitControllers())),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
        label: Text(l10n.addCollaborator),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      ),
      const SizedBox(height: 12),
      _Notice(text: l10n.inviteExplain, color: AppColors.deepNavy, icon: Icons.mail_outline_rounded),
    ]);
  }

  // ── Step 3 ────────────────────────────────────────────────────────────────

  Widget _buildScopeStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.scopeQuestion, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy, fontSize: 14)),
      const SizedBox(height: 4),
      Text(l10n.scopeHelp, style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final k in kScopeCategories)
          FilterChip(
            label: Text(scopeCategoryLabel(l10n, k)),
            selected: _scope.contains(k),
            onSelected: (v) => setState(() => v ? _scope.add(k) : _scope.remove(k)),
            selectedColor: AppColors.teal.withValues(alpha: 0.15),
            checkmarkColor: AppColors.teal,
            labelStyle: TextStyle(
              color: _scope.contains(k) ? AppColors.teal : AppColors.deepNavy,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            backgroundColor: AppColors.white,
            side: BorderSide(color: _scope.contains(k) ? AppColors.teal : AppColors.cardBorder),
          ),
      ]),
      const SizedBox(height: 16),
      TextFormField(
        controller: _scopeDetails,
        maxLines: 3,
        decoration: InputDecoration(labelText: l10n.scopeDetails, hintText: l10n.scopeOfRightsHint),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _paymentTerms,
        maxLines: 3,
        decoration: InputDecoration(labelText: l10n.paymentTerms, hintText: l10n.paymentTermsHint),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _terms,
        maxLines: 4,
        decoration: InputDecoration(labelText: l10n.additionalTermsOptional, hintText: l10n.additionalTermsHint),
      ),
    ]);
  }

  // ── Step 4 ────────────────────────────────────────────────────────────────

  Widget _buildWitnessStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.witnessOptionalIntro, style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
      const SizedBox(height: 12),
      _ToggleSection(
        title: l10n.addWitness,
        subtitle: l10n.addWitnessSubtitle,
        icon: Icons.person_outline,
        value: _addWitness,
        onChanged: (v) => setState(() => _addWitness = v),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: !_addWitness
            ? const SizedBox(width: double.infinity)
            : _FieldGroup(children: [
                TextFormField(
                  controller: _wName,
                  decoration: InputDecoration(labelText: l10n.witnessFullNameRequired, isDense: true),
                  validator: (v) => _addWitness && (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                TextFormField(
                    controller: _wEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: l10n.emailOptional,
                        helperText: l10n.witnessEmailHint,
                        helperMaxLines: 3,
                        isDense: true),
                    validator: _optionalEmail),
                TextFormField(
                    controller: _wPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l10n.phoneOptional, isDense: true)),
                TextFormField(
                    controller: _wRole, decoration: InputDecoration(labelText: l10n.roleRelationshipOptional, isDense: true)),
              ]),
      ),
      const SizedBox(height: 14),
      _ToggleSection(
        title: l10n.addLegalRep,
        subtitle: l10n.addLegalRepSubtitle,
        icon: Icons.gavel_rounded,
        value: _addLawyer,
        onChanged: (v) => setState(() => _addLawyer = v),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: !_addLawyer
            ? const SizedBox(width: double.infinity)
            : _FieldGroup(children: [
                TextFormField(
                  controller: _lName,
                  decoration: InputDecoration(labelText: l10n.lawyerFullNameRequired, isDense: true),
                  validator: (v) => _addLawyer && (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                TextFormField(controller: _lFirm, decoration: InputDecoration(labelText: l10n.lawFirmOptional, isDense: true)),
                TextFormField(
                    controller: _lEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.emailOptional, isDense: true),
                    validator: _optionalEmail),
                TextFormField(
                    controller: _lPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l10n.phoneOptional, isDense: true)),
                TextFormField(
                    controller: _lReg,
                    decoration: InputDecoration(labelText: l10n.professionalRegistrationOptional, isDense: true)),
              ]),
      ),
      const SizedBox(height: 18),
      _Notice(text: l10n.witnessLawyerDisclaimer, color: Colors.deepOrange, icon: Icons.gavel_outlined),
    ]);
  }

  String? _optionalEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : l10n.emailInvalid;
  }
}

// ── Pieces ─────────────────────────────────────────────────────────────────

class _SplitCard extends StatelessWidget {
  final int index;
  final _SplitControllers c;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _SplitCard({super.key, required this.index, required this.c, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.deepNavy.withValues(alpha: 0.1),
            child: Text('${index + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.collaboratorNumber('${index + 1}'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.deepNavy)),
          ),
          if (onRemove != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.delete,
              icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
              onPressed: onRemove,
            ),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: c.name,
              decoration: InputDecoration(labelText: l10n.nameRequired, isDense: true),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: c.pct,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.percentRequired, isDense: true, suffixText: '%'),
              onChanged: (_) => onChanged(),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (v == null || v.isEmpty) return l10n.requiredShort;
                if (n == null || n <= 0 || n > 100) return l10n.invalid;
                return null;
              },
            ),
          ),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: c.roleChoice,
          isExpanded: true,
          isDense: true,
          decoration: InputDecoration(labelText: l10n.role, isDense: true),
          items: [for (final r in kMusicRoles) DropdownMenuItem(value: r, child: Text(musicRoleLabel(l10n, r)))],
          onChanged: (v) {
            c.roleChoice = v;
            onChanged();
          },
          validator: (v) => v == null ? l10n.fieldRequired : null,
        ),
        if (c.roleChoice == 'Other') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: c.customRole,
            decoration: InputDecoration(labelText: l10n.collaboratorRoleRequired, isDense: true),
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
        ],
        const SizedBox(height: 10),
        TextFormField(
          controller: c.desc,
          decoration: InputDecoration(labelText: l10n.contributionDescriptionOptional, isDense: true),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextFormField(
              controller: c.email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailForInvite, isDense: true),
              validator: (v) =>
                  (v == null || v.trim().isEmpty || emailRe.hasMatch(v.trim())) ? null : l10n.emailInvalid,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: c.phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneOptional, isDense: true),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final List<Widget> children;
  const _FieldGroup({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ]),
      );
}

class _ToggleSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: value ? AppColors.deepNavy : AppColors.cardBorder),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.deepNavy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.deepNavy)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ]),
            ),
            Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.teal),
          ]),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _Notice({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: color, height: 1.45))),
        ]),
      );
}
