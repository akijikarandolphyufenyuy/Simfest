import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web/web.dart' as web;
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../../passport/widgets/passport_view.dart' show openExternal;
import '../models/campaign.dart';
import '../services/social_share_service.dart';

/// "Post to your socials": a caption per platform, one-tap Share (video + caption),
/// Copy caption, the user's linked accounts, and a downloadable content pack.
class SocialSharePanel extends ConsumerStatefulWidget {
  final Campaign campaign;
  final String? artist;
  const SocialSharePanel({super.key, required this.campaign, this.artist});

  @override
  ConsumerState<SocialSharePanel> createState() => _SocialSharePanelState();
}

class _SocialSharePanelState extends ConsumerState<SocialSharePanel> {
  web.File? _video;
  SocialPlatform? _open;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prefetch();
  }

  @override
  void didUpdateWidget(covariant SocialSharePanel old) {
    super.didUpdateWidget(old);
    if (old.campaign.videoUrl != widget.campaign.videoUrl) {
      _video = null;
      _prefetch();
    }
  }

  /// Fetch the video in advance: browsers only allow sharing right after a tap.
  Future<void> _prefetch() async {
    final f = await prefetchVideo(widget.campaign.videoUrl, '${widget.campaign.songTitle}-promo');
    if (mounted) setState(() => _video = f);
  }

  String _caption(SocialPlatform p, AppLocalizations l10n) =>
      captionFor(p, widget.campaign, l10n, artist: widget.artist);

  Future<void> _share(SocialPlatform p) async {
    final l10n = AppLocalizations.of(context)!;
    if (p.needsVideo && widget.campaign.videoUrl == null) {
      showError(context, l10n.reachNeedsVideo(p.label));
      return;
    }
    setState(() => _busy = true);
    try {
      final outcome = await shareToPlatform(
        p,
        caption: _caption(p, l10n),
        songTitle: widget.campaign.songTitle,
        videoUrl: widget.campaign.videoUrl,
        link: widget.campaign.streamingLink,
        video: _video,
      );
      if (!mounted) return;
      switch (outcome) {
        case ShareOutcome.sharedToApp:
          showSuccess(context, l10n.reachSharedToApp);
        case ShareOutcome.openedWebPage:
          showSuccess(context, l10n.reachOpenedWeb);
        case ShareOutcome.cancelled:
          break;
      }
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(SocialPlatform p) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: _caption(p, l10n)));
    if (mounted) showSuccess(context, l10n.copiedLabel(p.label));
  }

  Future<void> _pack() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await downloadContentPack(widget.campaign, l10n, artist: widget.artist, video: _video);
      if (mounted) showSuccess(context, l10n.reachContentPackDone);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    String? linked(SocialPlatform p) {
      final url = switch (p) {
        SocialPlatform.tiktok => profile?.tiktokUrl,
        SocialPlatform.facebook => profile?.facebookUrl,
        SocialPlatform.youtube => profile?.youtubeUrl,
        SocialPlatform.whatsapp => profile?.whatsappUrl,
      };
      return (url?.trim().isNotEmpty ?? false) ? url!.trim() : null;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.reachPostHint, style: const TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.45)),
      const SizedBox(height: 12),
      for (final p in SocialPlatform.values) ...[
        _PlatformRow(
          platform: p,
          linkedUrl: linked(p),
          caption: _caption(p, l10n),
          expanded: _open == p,
          busy: _busy,
          missingVideo: p.needsVideo && widget.campaign.videoUrl == null,
          onToggle: () => setState(() => _open = _open == p ? null : p),
          onShare: () => _share(p),
          onCopy: () => _copy(p),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 6),
      OutlinedButton.icon(
        onPressed: _busy ? null : _pack,
        icon: const Icon(Icons.folder_zip_outlined, size: 18),
        label: Text(l10n.reachContentPack),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
      ),
      const SizedBox(height: 4),
      Text(l10n.reachContentPackHint,
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
    ]);
  }
}

class _PlatformRow extends StatelessWidget {
  final SocialPlatform platform;
  final String? linkedUrl;
  final String caption;
  final bool expanded;
  final bool busy;
  final bool missingVideo;
  final VoidCallback onToggle;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const _PlatformRow({
    required this.platform,
    required this.linkedUrl,
    required this.caption,
    required this.expanded,
    required this.busy,
    required this.missingVideo,
    required this.onToggle,
    required this.onShare,
    required this.onCopy,
  });

  (FaIconData, Color) get _brand => switch (platform) {
        SocialPlatform.tiktok => (FontAwesomeIcons.tiktok, const Color(0xFF010101)),
        SocialPlatform.facebook => (FontAwesomeIcons.facebook, const Color(0xFF1877F2)),
        SocialPlatform.youtube => (FontAwesomeIcons.youtube, const Color(0xFFFF0000)),
        SocialPlatform.whatsapp => (FontAwesomeIcons.whatsapp, const Color(0xFF25D366)),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color) = _brand;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: expanded ? color.withValues(alpha: 0.5) : AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Center(child: FaIcon(icon, color: color, size: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(platform.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy, fontSize: 14)),
                  const SizedBox(height: 2),
                  if (linkedUrl != null)
                    InkWell(
                      onTap: () => openExternal(linkedUrl!),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.link_rounded, size: 13, color: AppColors.teal),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text('${l10n.reachLinked} · ${l10n.reachOpenMyPage}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontSize: 11.5, color: AppColors.teal, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    )
                  else
                    Text(l10n.reachPreviewCaption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
                ]),
              ),
              IconButton(
                tooltip: l10n.reachCopyCaption,
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.mutedText),
              ),
              FilledButton.icon(
                onPressed: busy ? null : onShare,
                style: FilledButton.styleFrom(
                  backgroundColor: missingVideo ? AppColors.mutedText : color,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 16),
                label: Text(l10n.reachShare),
              ),
            ]),
          ),
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.lightBg, borderRadius: BorderRadius.circular(10)),
            child: SelectableText(withoutEmoji(caption),
                style: const TextStyle(fontSize: 12.5, color: AppColors.deepNavy, height: 1.5)),
          ),
      ]),
    );
  }
}
