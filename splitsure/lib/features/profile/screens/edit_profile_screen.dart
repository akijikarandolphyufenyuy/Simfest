import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _ttCtrl = TextEditingController();
  final _ytCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  List<String> _roles = [];
  bool _loading = false;
  bool _initialized = false;
  String? _avatarUrl;

  static const _allRoles = kMusicRoles;

  static Widget _socialLogo(String asset) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(asset, width: 22, height: 22, fit: BoxFit.cover),
      );
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  void _init(UserProfile p) {
    if (_initialized) return;
    _initialized = true;
    _firstCtrl.text = p.firstName ?? '';
    _lastCtrl.text = p.lastName ?? '';
    _usernameCtrl.text = p.username ?? '';
    _bioCtrl.text = p.bio ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _countryCtrl.text = p.country ?? 'Cameroon';
    _cityCtrl.text = p.city ?? '';
    _waCtrl.text = p.whatsappUrl ?? '';
    _ttCtrl.text = p.tiktokUrl ?? '';
    _ytCtrl.text = p.youtubeUrl ?? '';
    _fbCtrl.text = p.facebookUrl ?? '';
    _roles = List<String>.from(p.musicRoles);
    _avatarUrl = p.avatarUrl;
  }

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _usernameCtrl, _bioCtrl,
        _phoneCtrl, _countryCtrl, _cityCtrl, _waCtrl, _ttCtrl, _ytCtrl, _fbCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').upsert({
        'id': uid,
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
        'first_name': _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim(),
        'username': _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'country': _countryCtrl.text.trim().isEmpty ? 'Cameroon' : _countryCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'music_roles': _roles,
        'whatsapp_url': _waCtrl.text.trim().isEmpty ? null : _waCtrl.text.trim(),
        'tiktok_url': _ttCtrl.text.trim().isEmpty ? null : _ttCtrl.text.trim(),
        'youtube_url': _ytCtrl.text.trim().isEmpty ? null : _ytCtrl.text.trim(),
        'facebook_url': _fbCtrl.text.trim().isEmpty ? null : _fbCtrl.text.trim(),
      });
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdated), backgroundColor: AppColors.teal),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetails('$e')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(profileProvider).whenOrNull(data: (p) { if (p != null) { _init(p); } });

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: GradientAppBar(
        title: l10n.editProfile,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(l10n.save,
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: GestureDetector(
                onTap: () async {
                  final url = await uploadAvatar();
                  if (url != null) setState(() => _avatarUrl = url);
                },
                child: Stack(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.teal,
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? Text(
                            _firstCtrl.text.isNotEmpty ? _firstCtrl.text[0].toUpperCase() : 'A',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.white),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.white),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            _label(l10n.personalInfo),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _firstCtrl,
                decoration: InputDecoration(labelText: l10n.firstNameRequiredLabel),
                validator: (v) => (v == null || v.isEmpty) ? l10n.fieldRequired : null,
                onChanged: (_) => setState(() {}),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(
                controller: _lastCtrl,
                decoration: InputDecoration(labelText: l10n.lastNameRequiredLabel),
                validator: (v) => (v == null || v.isEmpty) ? l10n.fieldRequired : null,
              )),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _usernameCtrl,
              decoration: InputDecoration(labelText: l10n.username, prefixText: '@'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bioCtrl,
              decoration: InputDecoration(labelText: l10n.bio),
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(labelText: l10n.phoneNumber),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _countryCtrl,
                decoration: InputDecoration(labelText: l10n.country),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(
                controller: _cityCtrl,
                decoration: InputDecoration(labelText: l10n.city),
              )),
            ]),
            const SizedBox(height: 24),
            _label(l10n.musicRoles),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _allRoles.map((role) {
                final sel = _roles.contains(role);
                return FilterChip(
                  label: Text(musicRoleLabel(l10n, role)),
                  selected: sel,
                  onSelected: (v) => setState(() {
                    if (v) { _roles.add(role); } else { _roles.remove(role); }
                  }),
                  selectedColor: AppColors.deepNavy,
                  labelStyle: TextStyle(
                    color: sel ? AppColors.white : AppColors.deepNavy,
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.white,
                  side: BorderSide(color: sel ? AppColors.deepNavy : AppColors.cardBorder),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _label(l10n.socialMediaLinks),
            const SizedBox(height: 12),
            TextFormField(
              controller: _waCtrl,
              decoration: InputDecoration(
                labelText: l10n.whatsappUrl,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _socialLogo('assets/images/SocialMedia/whatsapp.jpg'),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ttCtrl,
              decoration: InputDecoration(
                labelText: l10n.tiktokUrl,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _socialLogo('assets/images/SocialMedia/tiktok.jpg'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ytCtrl,
              decoration: InputDecoration(
                labelText: l10n.youtubeUrl,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _socialLogo('assets/images/SocialMedia/youtube.jpg'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fbCtrl,
              decoration: InputDecoration(
                labelText: l10n.facebookUrl,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _socialLogo('assets/images/SocialMedia/facebook.jpg'),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy, minimumSize: const Size(double.infinity, 52)),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : Text(l10n.saveProfile,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 28),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy));
}
