import '../../../core/localization/l10n/app_localizations.dart';
import '../models/campaign.dart';

/// Where Reach content can be posted, and a caption written for each platform.
/// (Pure Dart, no browser APIs, so it can be unit-tested.)
enum SocialPlatform { facebook, tiktok, whatsapp, youtube }

extension SocialPlatformInfo on SocialPlatform {
  String get label => switch (this) {
        SocialPlatform.tiktok => 'TikTok',
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.youtube => 'YouTube Shorts',
        SocialPlatform.whatsapp => 'WhatsApp',
      };

  /// Page to open on a computer when the share sheet isn't available.
  String uploadPage(String caption, String? link) => switch (this) {
        SocialPlatform.tiktok => 'https://www.tiktok.com/upload',
        SocialPlatform.youtube => 'https://studio.youtube.com/',
        SocialPlatform.facebook => link != null && link.isNotEmpty
            ? 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}'
            : 'https://www.facebook.com/',
        SocialPlatform.whatsapp => 'https://wa.me/?text=${Uri.encodeComponent(caption)}',
      };

  /// Platforms that need the video file (the others can post text + link).
  bool get needsVideo => this == SocialPlatform.tiktok || this == SocialPlatform.youtube;
}

String _tag(String s) => '#${s.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')}';

/// A caption written for each platform from the campaign's own details.
String captionFor(SocialPlatform p, Campaign c, AppLocalizations l10n, {String? artist}) {
  final title = c.songTitle.trim();
  final by = (artist ?? c.artistName ?? '').trim();
  final msg =
      (c.promotionalMessage?.trim().isNotEmpty ?? false) ? c.promotionalMessage!.trim() : l10n.defaultPromoMessage;
  final link = (c.streamingLink?.trim().isNotEmpty ?? false) ? c.streamingLink!.trim() : null;
  final headline = by.isEmpty ? l10n.captionOutNow(title) : l10n.reachHeadlineBy(title, by);
  final songTag = _tag(title);
  final artistTag = by.isEmpty ? '' : ' ${_tag(by)}';

  switch (p) {
    case SocialPlatform.tiktok:
      return '$headline\n$msg\n\n${link != null ? l10n.reachLinkInBio : l10n.streamItNow}\n\n'
          '$songTag$artistTag #NewMusic #fyp #Cameroon #AfroMusic';
    case SocialPlatform.facebook:
      return '$headline\n\n$msg\n\n${link != null ? l10n.streamItNowAt(link) : l10n.streamItNow}\n\n'
          '$songTag #NewMusic #MusicRelease';
    case SocialPlatform.youtube:
      return '$headline #Shorts\n\n$msg\n\n${link != null ? l10n.streamItNowAt(link) : l10n.streamItNow}\n\n'
          '$songTag$artistTag #NewMusic #Shorts';
    case SocialPlatform.whatsapp:
      return '$headline\n$msg${link != null ? '\n${l10n.streamItNowAt(link)}' : ''}';
  }
}
