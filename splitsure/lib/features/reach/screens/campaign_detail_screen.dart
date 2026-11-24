import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../models/campaign.dart';
import '../providers/campaigns_provider.dart';
import '../services/promo_video_service.dart';
import '../widgets/video_preview.dart';
import '../widgets/social_share_panel.dart';
import 'create_campaign_screen.dart';
import '../../../core/services/plan_limits.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/media_cache.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../projects/screens/projects_screen.dart' show confirmDialog;

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;
  const CampaignDetailScreen({super.key, required this.campaign});
  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  late Campaign _campaign;
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  bool _generating = false;

  // Audio snippet state
  web.HTMLAudioElement? _audio;
  bool _audioReady = false;
  bool _playing = false;
  double _duration = 0;
  double _position = 0;
  double _snippetStart = 0;
  double _snippetEnd = 30;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _snippetStart = _campaign.snippetStart ?? 0;
    _snippetEnd = _campaign.snippetEnd ?? 30;
    if (_campaign.musicFileUrl != null) _initAudio(_campaign.musicFileUrl!);
    // Warm up song + artwork in the background so "Generate" starts instantly.
    prefetchMedia([_campaign.musicFileUrl, _campaign.coverArtUrl]);
  }

  void _initAudio(String url) {
    _audio = web.HTMLAudioElement();
    _audio!.src = url;
    _audio!.preload = 'metadata';
    _audio!.addEventListener(
      'loadedmetadata',
      (web.Event _) {
        if (mounted) {
          setState(() {
            _duration = _audio!.duration.toDouble();
            _audioReady = true;
            if (_snippetEnd > _duration) _snippetEnd = _duration;
          });
        }
      }.toJS,
    );
    _audio!.addEventListener(
      'ended',
      (web.Event _) {
        _ticker?.cancel();
        if (mounted) setState(() => _playing = false);
      }.toJS,
    );
  }

  void _togglePlay() {
    if (_audio == null) return;
    if (_playing) {
      _audio!.pause();
      _ticker?.cancel();
      setState(() => _playing = false);
    } else {
      _audio!.currentTime = _snippetStart;
      _audio!.play();
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        final pos = _audio!.currentTime;
        if (pos >= _snippetEnd) {
          _audio!.pause();
          _ticker?.cancel();
          setState(() {
            _playing = false;
            _position = _snippetStart;
          });
        } else {
          setState(() => _position = pos);
        }
      });
      setState(() => _playing = true);
    }
  }

  Future<void> _saveSnippet() async {
    await updateCampaignSnippet(_campaign.id, _snippetStart, _snippetEnd);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snippetSaved), backgroundColor: AppColors.teal),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _audio?.pause();
    if (_localVideoUrl != null) web.URL.revokeObjectURL(_localVideoUrl!);
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      await generateCampaignContent(_campaign, l10n);
      final updated = await _reload();
      if (mounted) setState(() => _campaign = updated ?? _campaign);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contentGeneratedSnack), backgroundColor: AppColors.teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetails('$e')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<Campaign?> _reload() async {
    try {
      final data = await Supabase.instance.client.from('campaigns').select().eq('id', _campaign.id).single();
      return Campaign.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _markReady() async {
    await updateCampaignStatus(_campaign.id, 'ready_to_share');
    final updated = await _reload();
    if (mounted) setState(() => _campaign = updated ?? _campaign);
  }

  /// Artist name for captions and the video: the campaign's, else the account holder's.
  String _artistName() {
    if (_campaign.artistName?.trim().isNotEmpty ?? false) return _campaign.artistName!.trim();
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    return [meta['first_name'], meta['last_name']].whereType<String>().join(' ').trim();
  }

  // ── Promo video ────────────────────────────────────────────────────────────

  PromoTemplate _template = PromoTemplate.pulse;
  bool _rendering = false; // preparing or recording
  bool _uploadingVideo = false;
  bool _preparing = false;
  double _renderProgress = 0;
  double _uploadProgress = 0;
  bool? _lastWasMp4;
  String? _localVideoUrl; // just-recorded video, playable before the upload finishes

  bool get _busy => _rendering || _uploadingVideo;

  Future<void> _generateVideo() async {
    final music = _campaign.musicFileUrl;
    if (music == null) {
      showError(context, l10n.videoNeedsMusic);
      return;
    }
    if (!await planAllows('promo_video')) {
      if (mounted) showError(context, l10n.featureNotInPlan);
      return;
    }
    if (_playing) _togglePlay();
    setState(() {
      _rendering = true;
      _preparing = true;
      _renderProgress = 0;
    });
    try {
      final artist = _artistName();
      final end = _audioReady ? _snippetEnd : (_campaign.snippetEnd ?? 30);
      final start = _audioReady ? _snippetStart : (_campaign.snippetStart ?? 0);
      final result = await generatePromoVideo(
        PromoVideoRequest(
          audioUrl: music,
          coverUrl: _campaign.coverArtUrl,
          title: _campaign.songTitle,
          artist: artist.isEmpty ? l10n.defaultArtistName : artist,
          message: _campaign.promotionalMessage,
          badge: l10n.outNowBadge,
          start: start,
          end: end,
          template: _template,
        ),
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _preparing = false;
              _renderProgress = p;
            });
          }
        },
      );
      // Show the finished video right away; save it while the user watches.
      if (_localVideoUrl != null) web.URL.revokeObjectURL(_localVideoUrl!);
      final local = web.URL.createObjectURL(result.blob);
      if (mounted) {
        setState(() {
          _localVideoUrl = local;
          _lastWasMp4 = result.isMp4;
          _rendering = false;
          _uploadingVideo = true;
          _uploadProgress = 0;
        });
      }
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final url = await uploadBlob(
        bucket: 'campaign-assets',
        path: '$uid/video_${_campaign.id}_${DateTime.now().millisecondsSinceEpoch}.${result.extension}',
        blob: result.blob,
        contentType: result.mimeType,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      rememberMediaBlob(url, result.blob); // sharing/downloading reuse it, no re-download
      await saveCampaignVideo(_campaign.id, url: url, template: _template.id);
      if (_campaign.status == 'draft') await updateCampaignStatus(_campaign.id, 'content_generated');
      final updated = await _reload();
      if (!mounted) return;
      setState(() => _campaign = updated ?? _campaign);
      showSuccess(context, l10n.videoReady);
    } catch (e) {
      // Not saved: drop the local preview so it is not mistaken for a stored video.
      if (_localVideoUrl != null) web.URL.revokeObjectURL(_localVideoUrl!);
      _localVideoUrl = null;
      if (mounted) showError(context, l10n.videoFailed(friendlyError(e)));
    } finally {
      if (mounted) {
        setState(() {
          _rendering = false;
          _preparing = false;
          _uploadingVideo = false;
        });
      }
    }
  }

  Widget _buildVideoSection() {
    final hasVideo = _campaign.videoUrl != null;
    final previewUrl = _localVideoUrl ?? _campaign.videoUrl;
    final supported = promoVideoSupported;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.videoIntro, style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText, height: 1.5)),
      const SizedBox(height: 12),
      Row(children: [
        for (final t in PromoTemplate.values) ...[
          Expanded(
            child: _TemplateTile(
              selected: _template == t,
              icon: t == PromoTemplate.pulse ? Icons.album_rounded : Icons.graphic_eq_rounded,
              title: t == PromoTemplate.pulse ? l10n.templatePulse : l10n.templateWaveform,
              subtitle: t == PromoTemplate.pulse ? l10n.templatePulseHint : l10n.templateWaveformHint,
              onTap: _busy ? null : () => setState(() => _template = t),
            ),
          ),
          if (t != PromoTemplate.values.last) const SizedBox(width: 10),
        ],
      ]),
      const SizedBox(height: 14),
      if (_busy) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _preparing ? null : (_uploadingVideo ? _uploadProgress : _renderProgress),
            minHeight: 8,
            backgroundColor: AppColors.cardBorder,
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
        ),
        const SizedBox(height: 8),
        Text(
            _preparing
                ? l10n.videoPreparing
                : _uploadingVideo
                    ? l10n.videoUploading((_uploadProgress * 100).round())
                    : l10n.videoRendering((_renderProgress * 100).round()),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
        if (_uploadingVideo)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.videoSavedLocallyHint,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
          ),
      ] else
        ElevatedButton.icon(
          onPressed: supported && _campaign.musicFileUrl != null ? _generateVideo : null,
          icon: const Icon(Icons.movie_creation_outlined, size: 18),
          label: Text(hasVideo ? l10n.regenerateVideo : l10n.generateVideo),
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size(double.infinity, 48)),
        ),
      if (!supported)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.videoUnsupported, style: const TextStyle(fontSize: 12, color: Colors.orange)),
        ),
      if (_campaign.musicFileUrl == null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.videoNeedsMusic, style: const TextStyle(fontSize: 12, color: Colors.orange)),
        ),
      if (previewUrl != null && !_rendering) ...[
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: VideoPreview(url: previewUrl),
          ),
        ),
      ],
      if (hasVideo && !_busy) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final ext = _campaign.videoUrl!.split('.').last.split('?').first;
            downloadUrl(_campaign.videoUrl!, '${_campaign.songTitle.replaceAll(RegExp(r'[^\w\- ]'), '')}-promo.$ext');
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(l10n.downloadVideo),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
        ),
        if (_lastWasMp4 == false || _campaign.videoUrl!.endsWith('.webm'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.videoWebmNote, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
          ),
      ],
    ]);
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedLabel(label)), backgroundColor: AppColors.teal),
    );
  }

  String _fmt(double secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _statusColor => switch (_campaign.status) {
        'completed' => const Color(0xFF38A169),
        'ready_to_share' || 'active' => AppColors.teal,
        'content_generated' => Colors.blue,
        _ => AppColors.mutedText,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: _campaign.campaignName ?? _campaign.songTitle,
          subtitle: _campaign.songTitle,
          gradient: kTealGradient,
          showBack: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.white),
              onSelected: (v) async {
                if (v == 'edit') {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => CreateCampaignScreen(campaign: _campaign)));
                  final updated = await _reload();
                  if (mounted) setState(() => _campaign = updated ?? _campaign);
                } else if (v == 'delete') {
                  final ok = await confirmDialog(context, l10n.deleteCampaignConfirm);
                  if (!ok) return;
                  await deleteCampaign(_campaign.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.editCampaign)),
                PopupMenuItem(
                    value: 'delete', child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent))),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(right: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(campaignStatusLabel(l10n, _campaign.status),
                  style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Campaign details
              _Card(
                  title: l10n.campaignDetails,
                  child: Column(children: [
                    if (_campaign.description != null) _Row(l10n.description, _campaign.description!),
                    if (_campaign.targetAudience != null) _Row(l10n.audience, _campaign.targetAudience!),
                    if (_campaign.releaseDate != null) _Row(l10n.releaseDate, _campaign.releaseDate!),
                    if (_campaign.streamingLink != null) _Row(l10n.streamingLink, _campaign.streamingLink!),
                  ])),
              const SizedBox(height: 16),

              // Audio snippet selector
              if (_campaign.musicFileUrl != null) ...[
                _Card(
                  title: l10n.songSnippet,
                  child: _audioReady
                      ? _buildSnippetSelector()
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)),
                            const SizedBox(width: 12),
                            Text(l10n.loadingAudio, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
                          ]),
                        ),
                ),
                const SizedBox(height: 16),
              ],

              // Generate content
              if (_campaign.generatedCaptions == null) ...[
                _Card(
                  title: l10n.generatePromoContent,
                  child: Column(children: [
                    Text(
                      l10n.generatePromoContentHint,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_generating ? l10n.generating : l10n.generateContent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Generated caption
              if (_campaign.generatedCaptions != null) ...[
                _Card(
                  title: l10n.generatedCaption,
                  action: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: l10n.reachRegenerate,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
                          : const Icon(Icons.refresh_rounded, size: 19, color: AppColors.teal),
                      onPressed: _generating ? null : _generate,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.teal),
                      onPressed: () => _copy(_campaign.generatedCaptions!, l10n.caption),
                    ),
                  ]),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.lightBg, borderRadius: BorderRadius.circular(10)),
                    child: Text(withoutEmoji(_campaign.generatedCaptions!),
                        style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, height: 1.6)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_campaign.generatedHashtags != null) ...[
                _Card(
                  title: l10n.hashtags,
                  action: IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.teal),
                    onPressed: () => _copy(_campaign.generatedHashtags!, l10n.hashtags),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _campaign.generatedHashtags!
                        .split(' ')
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(tag,
                                  style: const TextStyle(
                                      color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Promotional video (real 9:16 file rendered in the browser)
              _Card(
                title: l10n.promotionalVideo,
                child: _buildVideoSection(),
              ),
              const SizedBox(height: 16),

              // Post to social media (per-platform captions, share sheet, content pack)
              _Card(
                title: l10n.reachPostTitle,
                child: SocialSharePanel(campaign: _campaign, artist: _artistName()),
              ),
              const SizedBox(height: 16),

              // Status action
              if (_campaign.status == 'content_generated')
                ElevatedButton.icon(
                  onPressed: _markReady,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(l10n.markReadyToShare),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepNavy,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              if (_campaign.status == 'ready_to_share')
                ElevatedButton.icon(
                  onPressed: () async {
                    await updateCampaignStatus(_campaign.id, 'completed');
                    final updated = await _reload();
                    if (mounted) setState(() => _campaign = updated ?? _campaign);
                  },
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: Text(l10n.markCompleted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A169),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSnippetSelector() {
    final snippetDuration = _snippetEnd - _snippetStart;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Playback bar
      Row(children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(22)),
            child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.teal,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.teal,
            ),
            child: Slider(
              value: _position.clamp(0, _duration),
              min: 0,
              max: _duration > 0 ? _duration : 1,
              onChanged: (v) {
                _audio?.currentTime = v;
                setState(() => _position = v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_fmt(_position), style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              Text(_fmt(_duration), style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
            ]),
          ),
        ])),
      ]),
      const SizedBox(height: 20),

      // Snippet range
      Row(children: [
        const Icon(Icons.content_cut_rounded, size: 16, color: AppColors.deepNavy),
        const SizedBox(width: 8),
        Text(l10n.selectSnippet,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(l10n.secondsShort(snippetDuration.toStringAsFixed(0)),
              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Text(l10n.snippetStart(_fmt(_snippetStart)), style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        const Spacer(),
        Text(l10n.snippetEnd(_fmt(_snippetEnd)), style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
      ]),
      RangeSlider(
        values: RangeValues(_snippetStart, _snippetEnd),
        min: 0,
        max: _duration > 0 ? _duration : 1,
        activeColor: AppColors.teal,
        inactiveColor: AppColors.cardBorder,
        onChanged: (v) {
          setState(() {
            _snippetStart = v.start;
            _snippetEnd = v.end;
          });
        },
      ),
      const SizedBox(height: 4),
      Text(
        l10n.snippetRecommendation,
        style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
      ),
      const SizedBox(height: 14),
      ElevatedButton.icon(
        onPressed: _saveSnippet,
        icon: const Icon(Icons.save_outlined, size: 16),
        label: Text(l10n.saveSnippetTimes, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepNavy,
          minimumSize: const Size(double.infinity, 44),
        ),
      ),
    ]);
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Card({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy))),
          if (action != null) action!,
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _TemplateTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(colors: [Color(0xFF142B4A), Color(0xFF0D9488)]) : null,
            color: selected ? null : AppColors.lightBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: selected ? AppColors.white : AppColors.deepNavy, size: 22),
            const SizedBox(height: 6),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: selected ? AppColors.white : AppColors.deepNavy)),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : AppColors.mutedText)),
          ]),
        ),
      ),
    );
  }
}
