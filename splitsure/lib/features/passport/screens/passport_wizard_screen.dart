import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/chip_inputs.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../models/passport.dart';
import '../widgets/passport_view.dart';
import 'portfolio_item_sheet.dart';

const _kGenreSuggestions = [
  'Afrobeats',
  'Makossa',
  'Bikutsi',
  'Hip-Hop',
  'R&B',
  'Gospel',
  'Afro-pop',
  'Dancehall',
  'Amapiano',
  'Jazz'
];
const _kLanguageSuggestions = ['English', 'Français', 'Pidgin', 'Camfranglais', 'Duala', 'Ewondo'];
const _kInstrumentSuggestions = ['Guitar', 'Piano', 'Drums', 'Bass', 'Saxophone', 'Keyboard', 'Violin'];

/// Guided creation (and editing) of the user's Music Passport.
class PassportWizardScreen extends ConsumerStatefulWidget {
  final MusicPassport? existing;
  final int initialStep;
  const PassportWizardScreen({super.key, this.existing, this.initialStep = 0});

  @override
  ConsumerState<PassportWizardScreen> createState() => _PassportWizardScreenState();
}

class _PassportWizardScreenState extends ConsumerState<PassportWizardScreen> {
  late int _step = widget.initialStep;
  bool _saving = false;
  bool _uploading = false;

  // Step 1
  final _stage = TextEditingController();
  final _full = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _photo;
  String? _primaryRole;
  List<String> _secondary = [];
  String? _country;
  String? _preferred;

  // Step 2
  List<String> _skills = [], _genres = [], _instruments = [], _languages = [], _arrangements = [];
  final _years = TextEditingController();
  String _availability = 'available';
  final _operating = TextEditingController();

  // Step 3
  final Map<String, TextEditingController> _links = {for (final k in kPassportLinks.keys) k: TextEditingController()};

  // Step 4
  final _slug = TextEditingController();
  String? _slugError;
  Map<String, bool> _visibility = {
    'contact': false,
    'location': true,
    'portfolio': true,
    'links': true,
    'experience': true
  };

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _stage.text = p.stageName;
      _full.text = p.fullName ?? '';
      _city.text = p.city ?? '';
      _bio.text = p.bio ?? '';
      _email.text = p.contactEmail ?? '';
      _phone.text = p.contactPhone ?? '';
      _photo = p.photoUrl;
      _primaryRole = p.primaryRole;
      _secondary = [...p.secondaryRoles];
      _country = p.country;
      _preferred = p.preferredContact;
      _skills = [...p.skills];
      _genres = [...p.genres];
      _instruments = [...p.instruments];
      _languages = [...p.languages];
      _arrangements = [...p.arrangements];
      _years.text = p.yearsExperience?.toString() ?? '';
      _availability = p.availability;
      _operating.text = p.operatingLocation ?? '';
      p.links.forEach((k, v) => _links[k]?.text = v);
      _slug.text = p.slug;
      _visibility = {..._visibility, ...p.visibility};
    } else {
      // Pre-fill from the account profile so nobody types the same thing twice.
      final pr = ref.read(profileProvider).whenOrNull(data: (p) => p);
      final user = Supabase.instance.client.auth.currentUser;
      _full.text = [pr?.firstName, pr?.lastName].where((s) => s != null && s.isNotEmpty).join(' ');
      _stage.text = pr?.username ?? '';
      _city.text = pr?.city ?? '';
      _bio.text = pr?.bio ?? '';
      _email.text = user?.email ?? '';
      _phone.text = pr?.phone ?? '';
      _photo = pr?.avatarUrl;
      _country = kCountries.contains(pr?.country) ? pr?.country : null;
      _preferred = 'in_app';
    }
  }

  @override
  void dispose() {
    for (final c in [_stage, _full, _city, _bio, _email, _phone, _years, _operating, _slug, ..._links.values]) {
      c.dispose();
    }
    super.dispose();
  }

  MusicPassport _build({required bool publish}) => MusicPassport(
        userId: Supabase.instance.client.auth.currentUser!.id,
        slug: _slug.text.trim().toLowerCase(),
        stageName: _stage.text.trim(),
        fullName: _full.text.trim().isEmpty ? null : _full.text.trim(),
        photoUrl: _photo,
        primaryRole: _primaryRole ?? 'Other',
        secondaryRoles: _secondary.where((r) => r != _primaryRole).toList(),
        skills: _skills,
        country: _country,
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        contactEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
        contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        preferredContact: _preferred,
        yearsExperience: int.tryParse(_years.text.trim()),
        genres: _genres,
        instruments: _instruments,
        languages: _languages,
        availability: _availability,
        arrangements: _arrangements,
        operatingLocation: _operating.text.trim().isEmpty ? null : _operating.text.trim(),
        links: {
          for (final e in _links.entries)
            if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim()
        },
        visibility: _visibility,
        isPublished: publish,
      );

  bool _validateStep(AppLocalizations l10n) {
    if (_step == 0 && (_stage.text.trim().isEmpty || _primaryRole == null)) {
      showError(context, '${l10n.stageName} · ${l10n.primaryRole}: ${l10n.requiredField}');
      return false;
    }
    return true;
  }

  void _next(AppLocalizations l10n) {
    if (!_validateStep(l10n)) return;
    if (_step == 0 && _slug.text.isEmpty) _slug.text = slugify(_stage.text);
    setState(() => _step++);
  }

  Future<void> _pickPhoto() async {
    final picked =
        await afterTap(() => ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85));
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await uploadPassportImage(await picked.readAsBytes(), picked.name.split('.').last.toLowerCase());
      if (mounted) setState(() => _photo = url);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save({required bool publish}) async {
    final l10n = AppLocalizations.of(context)!;
    final slug = _slug.text.trim().toLowerCase();
    if (!kSlugPattern.hasMatch(slug)) {
      setState(() => _slugError = l10n.slugInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _slugError = null;
    });
    try {
      if (!await slugAvailable(slug)) {
        setState(() => _slugError = l10n.slugTaken);
        return;
      }
      await savePassport(_build(publish: publish));
      ref.invalidate(myPassportProvider);
      ref.invalidate(myPortfolioProvider);
      if (!mounted) return;
      showSuccess(context, publish ? l10n.passportPublished : l10n.passportSaved);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.passportStepIdentity,
      l10n.passportStepProfessional,
      l10n.passportStepPortfolio,
      l10n.passportStepReview
    ];
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: GradientAppBar(
        title: widget.existing == null ? l10n.createPassport : l10n.editPassport,
        subtitle: l10n.stepOf(_step + 1, 4),
      ),
      body: Column(children: [
        _StepBar(
            titles: titles,
            step: _step,
            onTap: (i) => i < _step || widget.existing != null ? setState(() => _step = i) : null),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                  position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(a), child: child),
            ),
            child: SingleChildScrollView(
              key: ValueKey(_step),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: switch (_step) {
                    0 => _identity(l10n),
                    1 => _professional(l10n),
                    2 => _portfolio(l10n),
                    _ => _review(l10n),
                  },
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration:
                const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.cardBorder))),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _step < 3
                    ? Row(children: [
                        if (_step > 0)
                          Expanded(
                            child: OutlinedButton(onPressed: () => setState(() => _step--), child: Text(l10n.back)),
                          ),
                        if (_step > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: () => _next(l10n),
                            child: Text(l10n.next),
                          ),
                        ),
                      ])
                    : Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => _save(publish: false),
                            child: Text(widget.existing?.isPublished == true ? l10n.unpublishPassport : l10n.saveDraft),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _saving ? null : () => _save(publish: true),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.public_rounded),
                            label: Text(l10n.publishPassport),
                          ),
                        ),
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Step 1: identity ──
  Widget _identity(AppLocalizations l10n) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: GestureDetector(
            onTap: _uploading ? null : _pickPhoto,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                backgroundImage: _photo != null ? NetworkImage(_photo!) : null,
                child: _uploading
                    ? const CircularProgressIndicator(color: AppColors.teal)
                    : (_photo == null ? const Icon(Icons.person_rounded, size: 44, color: AppColors.teal) : null),
              ),
              const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.teal,
                  child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white)),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
              onPressed: _uploading ? null : _pickPhoto, child: Text(_photo == null ? l10n.photo : l10n.changePhoto)),
        ),
        _gap,
        TextField(controller: _stage, decoration: InputDecoration(labelText: '${l10n.stageName} *')),
        _gap,
        TextField(controller: _full, decoration: InputDecoration(labelText: l10n.fullName)),
        _gap,
        DropdownButtonFormField<String>(
          initialValue: _primaryRole,
          isExpanded: true,
          decoration: InputDecoration(labelText: '${l10n.primaryRole} *'),
          items: [for (final r in kPassportRoles) DropdownMenuItem(value: r, child: Text(passportRoleLabel(l10n, r)))],
          onChanged: (v) => setState(() {
            _primaryRole = v;
            _secondary.remove(v);
          }),
        ),
        _gap,
        _label(l10n.secondaryRoles),
        MultiChoiceChips<String>(
          options: kPassportRoles.where((r) => r != _primaryRole).toList(),
          selected: _secondary,
          label: (r) => passportRoleLabel(l10n, r),
          max: 5,
          onChanged: (v) => setState(() => _secondary = v),
        ),
        _gap,
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _country,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.country),
              items: [for (final c in kCountries) DropdownMenuItem(value: c, child: Text(countryLabel(l10n, c)))],
              onChanged: (v) => setState(() => _country = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _city, decoration: InputDecoration(labelText: l10n.city))),
        ]),
        _gap,
        TextField(
            controller: _bio,
            maxLines: 4,
            maxLength: 600,
            decoration: InputDecoration(labelText: l10n.professionalBio)),
        _gap,
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.contactEmail)),
        _gap,
        TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.contactPhone)),
        _gap,
        _label(l10n.preferredContact),
        SingleChoiceChips<String>(
          options: kContactMethods,
          value: _preferred,
          label: (m) => contactMethodLabel(l10n, m),
          onChanged: (v) => setState(() => _preferred = v),
        ),
      ]);

  // ── Step 2: professional ──
  Widget _professional(AppLocalizations l10n) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TagInput(
            label: l10n.skillsSpecialisations,
            hint: l10n.typeAndEnter,
            values: _skills,
            onChanged: (v) => setState(() => _skills = v)),
        _gap,
        TextField(
          controller: _years,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          decoration: InputDecoration(labelText: l10n.yearsExperience),
        ),
        _gap,
        TagInput(
            label: l10n.genres,
            hint: l10n.typeAndEnter,
            values: _genres,
            suggestions: _kGenreSuggestions,
            onChanged: (v) => setState(() => _genres = v)),
        _gap,
        TagInput(
            label: l10n.instruments,
            hint: l10n.typeAndEnter,
            values: _instruments,
            suggestions: _kInstrumentSuggestions,
            onChanged: (v) => setState(() => _instruments = v)),
        _gap,
        TagInput(
            label: l10n.languages,
            hint: l10n.typeAndEnter,
            values: _languages,
            suggestions: _kLanguageSuggestions,
            onChanged: (v) => setState(() => _languages = v)),
        _gap,
        _label(l10n.availability),
        SingleChoiceChips<String>(
          options: kAvailability,
          value: _availability,
          label: (a) => availabilityLabel(l10n, a),
          onChanged: (v) => setState(() => _availability = v),
        ),
        _gap,
        _label(l10n.preferredArrangements),
        MultiChoiceChips<String>(
          options: kArrangements,
          selected: _arrangements,
          label: (a) => arrangementLabel(l10n, a),
          onChanged: (v) => setState(() => _arrangements = v),
        ),
        _gap,
        TextField(
            controller: _operating,
            decoration: InputDecoration(labelText: l10n.operatingLocation, hintText: l10n.operatingLocationHint)),
      ]);

  // ── Step 3: portfolio ──
  Widget _portfolio(AppLocalizations l10n) {
    final items = ref.watch(myPortfolioProvider).whenOrNull(data: (l) => l) ?? const <PortfolioItem>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: Text(l10n.portfolioItems,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.deepNavy))),
        FilledButton.tonalIcon(
          onPressed: () => showPortfolioItemSheet(context, ref, sortOrder: items.length),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addPortfolioItem),
        ),
      ]),
      const SizedBox(height: 8),
      if (items.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder)),
          child: Text(l10n.noPortfolioItems,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder)),
          child: Column(children: [
            for (final it in items)
              PortfolioTile(
                item: it,
                onTap: () => showPortfolioItemSheet(context, ref, existing: it),
                trailing: Icon(it.isPublic ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18, color: AppColors.mutedText),
              ),
          ]),
        ),
      const SizedBox(height: 22),
      Text(l10n.externalLinks,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.deepNavy)),
      const SizedBox(height: 8),
      for (final e in kPassportLinks.entries) ...[
        TextField(
          controller: _links[e.key],
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: e.key == 'website' ? l10n.personalWebsite : e.value,
            prefixIcon: const Icon(Icons.link_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }

  // ── Step 4: review ──
  Widget _review(AppLocalizations l10n) {
    final items = ref.watch(myPortfolioProvider).whenOrNull(data: (l) => l) ?? const <PortfolioItem>[];
    final preview = _build(publish: false);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.passportUrl, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          TextField(
            controller: _slug,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
              LengthLimitingTextInputFormatter(40)
            ],
            onChanged: (_) => setState(() => _slugError = null),
            decoration: InputDecoration(
              prefixText: '/passport/',
              helperText: l10n.passportSlugHint,
              errorText: _slugError,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.visibilitySettings, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          Text(l10n.visibilityHint, style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
          for (final k in kVisibilityKeys)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeThumbColor: AppColors.teal,
              title: Text(switch (k) {
                'contact' => l10n.visibilityContact,
                'location' => l10n.visibilityLocation,
                'portfolio' => l10n.visibilityPortfolio,
                'links' => l10n.visibilityLinks,
                _ => l10n.visibilityExperience,
              }),
              value: _visibility[k] ?? false,
              onChanged: (v) => setState(() => _visibility = {..._visibility, k: v}),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      PassportView(passport: preview, portfolio: items),
    ]);
  }

  static const _gap = SizedBox(height: 14);

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy, fontSize: 13.5)),
      );
}

class _StepBar extends StatelessWidget {
  final List<String> titles;
  final int step;
  final ValueChanged<int> onTap;
  const _StepBar({required this.titles, required this.step, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(children: [
            for (var i = 0; i < titles.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= step ? AppColors.teal : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(titles[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                          color: i == step ? AppColors.deepNavy : AppColors.mutedText,
                        )),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
