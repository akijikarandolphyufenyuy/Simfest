import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/services/storage_service.dart';
import '../models/campaign.dart';
import '../../projects/models/project.dart';
import '../../../core/services/plan_limits.dart';
import '../providers/campaigns_provider.dart';

class CreateCampaignScreen extends StatefulWidget {
  final Campaign? campaign; // non-null = edit mode
  final Project? project; // create inside a music project
  const CreateCampaignScreen({super.key, this.campaign, this.project});
  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  String? _projectId;
  late bool _rightsConfirmed = widget.campaign != null;
  DateTime? _releaseDate;
  bool _loading = false;
  String? _coverArtUrl;
  String? _musicFileUrl;
  bool _uploadingCover = false;
  bool _uploadingMusic = false;
  double? _musicProgress;

  bool get _isEdit => widget.campaign != null;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    if (c != null) {
      _nameCtrl.text = c.campaignName ?? '';
      _titleCtrl.text = c.songTitle;
      _descCtrl.text = c.description ?? '';
      _audienceCtrl.text = c.targetAudience ?? '';
      _msgCtrl.text = c.promotionalMessage ?? '';
      _linkCtrl.text = c.streamingLink ?? '';
      _releaseDate = c.releaseDate != null ? DateTime.tryParse(c.releaseDate!) : null;
      _coverArtUrl = c.coverArtUrl;
      _musicFileUrl = c.musicFileUrl;
      _artistCtrl.text = c.artistName ?? '';
      _projectId = c.projectId;
    } else {
      final p = widget.project;
      if (p != null) {
        _projectId = p.id;
        _titleCtrl.text = p.title;
        _coverArtUrl = p.coverArtUrl;
        _releaseDate = DateTime.tryParse(p.releaseDate ?? '');
        _descCtrl.text = p.description ?? '';
      }
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
      _artistCtrl.text = [meta['first_name'], meta['last_name']].whereType<String>().join(' ').trim();
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _titleCtrl, _descCtrl, _audienceCtrl, _msgCtrl, _linkCtrl, _artistCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCoverArt() async {
    setState(() => _uploadingCover = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final url = await uploadCoverArt(bucket: 'campaign-assets', folder: uid);
      if (url != null) setState(() => _coverArtUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.uploadError('$e')), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _uploadingCover = false);
    }
  }

  Future<void> _pickMusicFile() async {
    setState(() {
      _uploadingMusic = true;
      _musicProgress = null;
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final url = await uploadMusicFile(
        folder: uid,
        onProgress: (p) {
          if (mounted) setState(() => _musicProgress = p);
        },
      );
      if (url != null) setState(() => _musicFileUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.uploadError('$e')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingMusic = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_musicFileUrl != null || _coverArtUrl != null) && !_rightsConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.confirmRightsRequired), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_isEdit && !await checkPlanLimit(context, PlanLimit.campaigns)) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await updateCampaign(
          id: widget.campaign!.id,
          songTitle: _titleCtrl.text.trim(),
          campaignName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          targetAudience: _audienceCtrl.text.trim().isEmpty ? null : _audienceCtrl.text.trim(),
          promotionalMessage: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
          streamingLink: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
          releaseDate: _releaseDate?.toIso8601String().split('T').first,
          coverArtUrl: _coverArtUrl,
          musicFileUrl: _musicFileUrl,
          projectId: _projectId,
          artistName: _artistCtrl.text,
        );
      } else {
        await createCampaign(
          songTitle: _titleCtrl.text.trim(),
          campaignName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          targetAudience: _audienceCtrl.text.trim().isEmpty ? null : _audienceCtrl.text.trim(),
          promotionalMessage: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
          streamingLink: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
          releaseDate: _releaseDate?.toIso8601String().split('T').first,
          coverArtUrl: _coverArtUrl,
          musicFileUrl: _musicFileUrl,
          projectId: _projectId,
          artistName: _artistCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: GradientAppBar(title: _isEdit ? l10n.editCampaign : l10n.newCampaign, gradient: kTealGradient),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _section(l10n.campaignInfo, Icons.campaign_rounded),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  InputDecoration(labelText: l10n.campaignNameOptional, prefixIcon: const Icon(Icons.label_outline)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleCtrl,
              decoration:
                  InputDecoration(labelText: l10n.songTitleRequired, prefixIcon: const Icon(Icons.music_note_outlined)),
              validator: (v) => (v == null || v.isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _artistCtrl,
              decoration:
                  InputDecoration(labelText: l10n.artistNameLabel, prefixIcon: const Icon(Icons.mic_none_rounded)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: l10n.musicDescription),
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                labelText: l10n.promotionalMessage,
                hintText: l10n.promotionalMessageHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _linkCtrl,
              decoration: InputDecoration(
                labelText: l10n.streamingLinkOptional,
                prefixIcon: const Icon(Icons.link_outlined),
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            _section(l10n.mediaAssets, Icons.perm_media_outlined),
            const SizedBox(height: 16),
            _UploadTile(
              label: l10n.coverArt,
              icon: Icons.image_outlined,
              uploaded: _coverArtUrl != null,
              uploading: _uploadingCover,
              previewUrl: _coverArtUrl,
              onTap: _pickCoverArt,
              onRemove: () => setState(() => _coverArtUrl = null),
            ),
            const SizedBox(height: 12),
            _UploadTile(
              label: l10n.musicFileFormats,
              icon: Icons.audio_file_outlined,
              uploaded: _musicFileUrl != null,
              uploading: _uploadingMusic,
              progress: _musicProgress,
              onTap: _pickMusicFile,
              onRemove: () => setState(() => _musicFileUrl = null),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _rightsConfirmed,
              onChanged: (v) => setState(() => _rightsConfirmed = v ?? false),
              activeColor: AppColors.teal,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.confirmRights, style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
            ),
            const SizedBox(height: 16),
            _section(l10n.audienceAndRelease, Icons.people_outline),
            const SizedBox(height: 16),
            TextFormField(
              controller: _audienceCtrl,
              decoration: InputDecoration(
                labelText: l10n.targetAudienceOptional,
                hintText: l10n.targetAudienceHint,
                prefixIcon: const Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _releaseDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _releaseDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.mutedText),
                  const SizedBox(width: 12),
                  Text(
                    _releaseDate != null
                        ? l10n.releaseOn('${_releaseDate!.day}/${_releaseDate!.month}/${_releaseDate!.year}')
                        : l10n.releaseDateOptional,
                    style: TextStyle(
                      color: _releaseDate != null ? AppColors.deepNavy : AppColors.mutedText,
                      fontSize: 14,
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            _section(l10n.platforms, Icons.share_outlined),
            const SizedBox(height: 12),
            _platformRow(),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal, minimumSize: const Size(double.infinity, 52)),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : Text(
                      _isEdit ? l10n.saveChanges : l10n.createCampaign,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 28),
          ]),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration:
            BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.teal, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
    ]);
  }

  Widget _platformRow() {
    const platforms = [
      (Icons.tiktok, 'TikTok', Color(0xFF010101)),
      (Icons.camera_alt_outlined, 'Instagram', Color(0xFFE1306C)),
      (Icons.facebook, 'Facebook', Color(0xFF1877F2)),
      (Icons.play_circle_outline, 'YouTube', Color(0xFFFF0000)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: platforms
          .map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: p.$3.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.$3.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(p.$1, size: 16, color: p.$3),
                  const SizedBox(width: 6),
                  Text(p.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.$3)),
                ]),
              ))
          .toList(),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool uploaded;
  final bool uploading;
  final String? previewUrl;
  final double? progress; // 0..1 while uploading, when known
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _UploadTile({
    required this.label,
    required this.icon,
    required this.uploaded,
    required this.uploading,
    required this.onTap,
    required this.onRemove,
    this.previewUrl,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: uploaded ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: uploaded ? AppColors.teal : AppColors.cardBorder),
        ),
        child: Row(children: [
          if (previewUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(previewUrl!, width: 48, height: 48, fit: BoxFit.cover),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (uploaded ? AppColors.teal : AppColors.mutedText).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: uploaded ? AppColors.teal : AppColors.mutedText, size: 22),
            ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.deepNavy)),
            const SizedBox(height: 2),
            Text(
              uploading
                  ? (progress != null ? l10n.uploadingPercent((progress! * 100).round()) : l10n.uploading)
                  : (uploaded ? l10n.uploaded : l10n.tapToUpload),
              style: TextStyle(
                fontSize: 12,
                color: uploading ? AppColors.teal : (uploaded ? AppColors.teal : AppColors.mutedText),
              ),
            ),
          ])),
          if (uploading)
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal, value: progress))
          else if (uploaded)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration:
                    BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.close, size: 14, color: Colors.red),
              ),
            )
          else
            const Icon(Icons.upload_outlined, color: AppColors.mutedText, size: 18),
        ]),
      ),
    );
  }
}
