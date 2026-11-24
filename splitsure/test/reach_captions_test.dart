import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/core/localization/l10n/app_localizations.dart';
import 'package:splitsure/features/reach/models/campaign.dart';
import 'package:splitsure/features/reach/services/social_captions.dart';

void main() {
  Campaign campaign({String? link, String? message}) => Campaign.fromJson({
        'id': 'c1',
        'song_title': 'Mboa Love',
        'artist_name': 'Randolph',
        'promotional_message': message,
        'streaming_link': link,
        'status': 'content_generated',
        'created_at': '2026-11-24T08:00:00Z',
      });

  for (final code in ['en', 'fr']) {
    test('every platform gets its own caption ($code)', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      final c = campaign(link: 'https://open.spotify.com/track/x', message: 'Summer vibes from Douala');
      final captions = {for (final p in SocialPlatform.values) p: captionFor(p, c, l10n)};

      for (final entry in captions.entries) {
        expect(entry.value, contains('Mboa Love'), reason: entry.key.label);
        expect(entry.value.trim(), isNotEmpty);
      }
      expect(captions.values.toSet().length, SocialPlatform.values.length,
          reason: 'captions should differ per platform');
      expect(SocialPlatform.values,
          [SocialPlatform.facebook, SocialPlatform.tiktok, SocialPlatform.whatsapp, SocialPlatform.youtube]);
      expect(captions[SocialPlatform.youtube], contains('#Shorts'));
      expect(captions[SocialPlatform.facebook], contains('https://open.spotify.com/track/x'));
      expect(captions[SocialPlatform.whatsapp], contains('Summer vibes from Douala'));
      expect(captions[SocialPlatform.tiktok], contains('#MboaLove'));
    });
  }

  test('works without a streaming link or message', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final p in SocialPlatform.values) {
      final text = captionFor(p, campaign(), l10n);
      expect(text, contains('Mboa Love'));
      expect(text, isNot(contains('null')));
    }
    // Facebook without a link opens the plain site, with a link the share dialog.
    expect(SocialPlatform.facebook.uploadPage('x', null), 'https://www.facebook.com/');
    expect(SocialPlatform.facebook.uploadPage('x', 'https://a.b/c'), contains('sharer.php?u=https%3A%2F%2Fa.b%2Fc'));
    expect(SocialPlatform.whatsapp.uploadPage('hi there', null), 'https://wa.me/?text=hi%20there');
  });
}
