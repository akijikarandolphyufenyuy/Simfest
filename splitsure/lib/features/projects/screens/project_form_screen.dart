import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/plan_limits.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/project.dart';

/// Create or edit a music project. Pops with the saved [Project].
class ProjectFormScreen extends StatefulWidget {
  final Project? project;
  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.project?.title);
  late final _genre = TextEditingController(text: widget.project?.genre);
  late final _desc = TextEditingController(text: widget.project?.description);
  late String _status = widget.project?.status ?? 'in_progress';
  late DateTime? _recording = DateTime.tryParse(widget.project?.recordingDate ?? '');
  late DateTime? _release = DateTime.tryParse(widget.project?.releaseDate ?? '');
  late String? _cover = widget.project?.coverArtUrl;
  bool _uploading = false;
  bool _saving = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _title.dispose();
    _genre.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    setState(() => _uploading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final url = await uploadCoverArt(bucket: 'agreement-assets', folder: uid);
      if (url != null) setState(() => _cover = url);
    } catch (e) {
      if (mounted) showError(context, l10n.uploadError('$e'));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.project == null && !await checkPlanLimit(context, PlanLimit.projects)) return;
    setState(() => _saving = true);
    try {
      final p = await saveProject(
        id: widget.project?.id,
        title: _title.text,
        genre: _genre.text,
        description: _desc.text,
        coverArtUrl: _cover,
        recordingDate: _recording?.toIso8601String().split('T').first,
        releaseDate: _release?.toIso8601String().split('T').first,
        status: _status,
      );
      if (mounted) Navigator.pop(context, p);
    } catch (e) {
      if (mounted) showError(context, l10n.errorWithDetails('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: GradientAppBar(title: widget.project == null ? l10n.createProject : l10n.editProject),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CoverPicker(url: _cover, uploading: _uploading, onTap: _pickCover, label: l10n.uploadCoverArtOptional),
            const SizedBox(height: 18),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.songTitleRequired, prefixIcon: const Icon(Icons.music_note_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _genre,
              decoration: InputDecoration(labelText: l10n.musicGenre, hintText: l10n.musicGenreHint),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.songDescription),
            ),
            const SizedBox(height: 14),
            DatePickerField(label: l10n.recordingDate, value: _recording, onPicked: (d) => setState(() => _recording = d)),
            const SizedBox(height: 14),
            DatePickerField(
              label: l10n.expectedReleaseDate,
              value: _release,
              onPicked: (d) => setState(() => _release = d),
            ),
            const SizedBox(height: 18),
            Text(l10n.projectStatus,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in kProjectStatuses)
                  ChoiceChip(
                    label: Text(projectStatusLabel(l10n, s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                    selectedColor: AppColors.deepNavy,
                    labelStyle: TextStyle(
                      color: _status == s ? AppColors.white : AppColors.deepNavy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    backgroundColor: AppColors.white,
                    side: BorderSide(color: _status == s ? AppColors.deepNavy : AppColors.cardBorder),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : Text(l10n.saveProject),
            ),
          ],
        ),
      ),
    );
  }
}
