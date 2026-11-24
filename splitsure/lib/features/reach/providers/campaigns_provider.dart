import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';
import '../models/campaign.dart';
import '../../../core/localization/l10n/app_localizations.dart';

SupabaseClient get _client => Supabase.instance.client;

final campaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  ref.watch(currentUserIdProvider);
  final data = await _client.from('campaigns').select().order('created_at', ascending: false);
  return (data as List).map((e) => Campaign.fromJson(e)).toList();
});

Future<Campaign> createCampaign({
  required String songTitle,
  String? campaignName,
  String? description,
  String? targetAudience,
  int budgetXaf = 0,
  String? coverArtUrl,
  String? musicFileUrl,
  String? releaseDate,
  String? promotionalMessage,
  String? streamingLink,
  String? projectId,
  String? artistName,
}) async {
  final row = await _client
      .from('campaigns')
      .insert({
        if (projectId != null) 'project_id': projectId,
        if (artistName != null && artistName.trim().isNotEmpty) 'artist_name': artistName.trim(),
        'song_title': songTitle,
        'campaign_name': campaignName,
        'description': description,
        'target_audience': targetAudience,
        'budget_xaf': budgetXaf,
        'cover_art_url': coverArtUrl,
        'music_file_url': musicFileUrl,
        'release_date': releaseDate,
        'promotional_message': promotionalMessage,
        'streaming_link': streamingLink,
        'status': 'draft',
      })
      .select()
      .single();
  return Campaign.fromJson(row);
}

/// Captions are written in the user's current app language.
Future<void> generateCampaignContent(Campaign campaign, AppLocalizations l10n) async {
  final title = campaign.songTitle;
  final msg = campaign.promotionalMessage ?? l10n.defaultPromoMessage;

  final stream = campaign.streamingLink != null ? l10n.streamItNowAt(campaign.streamingLink!) : l10n.streamItNow;
  final captions = '''${l10n.captionOutNow(title)}

$msg

$stream

#NewMusic #SplitSure #MusicRelease''';

  final hashtags =
      '#NewMusic #${title.replaceAll(' ', '')} #MusicRelease #AfricanMusic #Cameroon #SplitSure #IndieArtist #NewSong';

  await _client.from('campaigns').update({
    'generated_captions': captions,
    'generated_hashtags': hashtags,
    'status': 'content_generated',
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', campaign.id);
}

Future<void> updateCampaignStatus(String id, String status) async {
  await _client.from('campaigns').update({
    'status': status,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', id);
}

Future<void> updateCampaign({
  required String id,
  required String songTitle,
  String? campaignName,
  String? description,
  String? targetAudience,
  int budgetXaf = 0,
  String? coverArtUrl,
  String? musicFileUrl,
  String? releaseDate,
  String? promotionalMessage,
  String? streamingLink,
  String? projectId,
  String? artistName,
}) async {
  await _client.from('campaigns').update({
    if (projectId != null) 'project_id': projectId,
    if (artistName != null && artistName.trim().isNotEmpty) 'artist_name': artistName.trim(),
    'song_title': songTitle,
    'campaign_name': campaignName,
    'description': description,
    'target_audience': targetAudience,
    'budget_xaf': budgetXaf,
    'cover_art_url': coverArtUrl,
    'music_file_url': musicFileUrl,
    'release_date': releaseDate,
    'promotional_message': promotionalMessage,
    'streaming_link': streamingLink,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', id);
}

Future<void> updateCampaignSnippet(String id, double start, double end) async {
  await _client.from('campaigns').update({
    'snippet_start': start,
    'snippet_end': end,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', id);
}

Future<void> deleteCampaign(String id) async {
  await _client.from('campaigns').delete().eq('id', id);
}

/// Stores a generated promotional video and moves the campaign forward.
Future<void> saveCampaignVideo(String id, {required String url, required String template}) async {
  await _client.from('campaigns').update({
    'video_url': url,
    'video_template': template,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', id);
}

Future<Campaign?> fetchCampaign(String id) async {
  final row = await _client.from('campaigns').select().eq('id', id).maybeSingle();
  return row == null ? null : Campaign.fromJson(row);
}
