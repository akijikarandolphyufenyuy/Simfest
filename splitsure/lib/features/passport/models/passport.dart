import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/localization/l10n/app_localizations.dart';

SupabaseClient get _client => Supabase.instance.client;

/// Professional roles (stored in English; displayed via [passportRoleLabel]).
const kPassportRoles = [
  'Singer',
  'Rapper',
  'Producer',
  'Songwriter',
  'Composer',
  'Sound Engineer',
  'Mixing & Mastering Engineer',
  'Instrumentalist',
  'DJ',
  'Music Manager',
  'Artist Manager',
  'Record Label',
  'Music Publisher',
  'Video Director',
  'Music Promoter',
  'Graphic Designer',
  'Photographer',
  'Music Business Professional',
  'Other',
];

String passportRoleLabel(AppLocalizations l10n, String r) => switch (r) {
      'Singer' => l10n.rolePassportSinger,
      'Rapper' => l10n.rolePassportRapper,
      'Producer' => l10n.rolePassportProducer,
      'Songwriter' => l10n.rolePassportSongwriter,
      'Composer' => l10n.rolePassportComposer,
      'Sound Engineer' => l10n.rolePassportSoundEngineer,
      'Mixing & Mastering Engineer' => l10n.rolePassportMixMaster,
      'Instrumentalist' => l10n.rolePassportInstrumentalist,
      'DJ' => l10n.rolePassportDj,
      'Music Manager' => l10n.rolePassportMusicManager,
      'Artist Manager' => l10n.rolePassportArtistManager,
      'Record Label' => l10n.rolePassportLabel,
      'Music Publisher' => l10n.rolePassportPublisher,
      'Video Director' => l10n.rolePassportVideoDirector,
      'Music Promoter' => l10n.rolePassportPromoter,
      'Graphic Designer' => l10n.rolePassportDesigner,
      'Photographer' => l10n.rolePassportPhotographer,
      'Music Business Professional' => l10n.rolePassportBusiness,
      'Other' => l10n.rolePassportOther,
      _ => r,
    };

/// Collaboration arrangements (shared with the Opportunity Hub's collaboration types).
const kArrangements = ['paid', 'revenue_share', 'royalty_share', 'percentage_partnership', 'voluntary', 'negotiable'];

String arrangementLabel(AppLocalizations l10n, String a) => switch (a) {
      'paid' => l10n.arrangementPaid,
      'revenue_share' => l10n.arrangementRevenueShare,
      'royalty_share' => l10n.arrangementRoyaltyShare,
      'percentage_partnership' => l10n.arrangementPercentage,
      'voluntary' => l10n.arrangementVoluntary,
      'negotiable' => l10n.arrangementNegotiable,
      _ => a,
    };

const kAvailability = ['available', 'limited', 'unavailable'];

String availabilityLabel(AppLocalizations l10n, String a) => switch (a) {
      'limited' => l10n.availabilityLimited,
      'unavailable' => l10n.availabilityUnavailable,
      _ => l10n.availabilityAvailable,
    };

const kContactMethods = ['email', 'phone', 'whatsapp', 'in_app'];

String contactMethodLabel(AppLocalizations l10n, String m) => switch (m) {
      'email' => l10n.contactEmailMethod,
      'phone' => l10n.contactPhoneMethod,
      'whatsapp' => l10n.contactWhatsapp,
      _ => l10n.contactInApp,
    };

const kPortfolioKinds = [
  'project',
  'release',
  'album',
  'production_credit',
  'writing_credit',
  'collaboration',
  'video',
  'award',
  'experience',
];

String portfolioKindLabel(AppLocalizations l10n, String k) => switch (k) {
      'project' => l10n.kindProject,
      'release' => l10n.kindRelease,
      'album' => l10n.kindAlbum,
      'production_credit' => l10n.kindProductionCredit,
      'writing_credit' => l10n.kindWritingCredit,
      'collaboration' => l10n.kindCollaboration,
      'video' => l10n.kindVideo,
      'award' => l10n.kindAward,
      _ => l10n.kindExperience,
    };

/// External profile links shown on the passport (key → display name).
const kPassportLinks = {
  'spotify': 'Spotify',
  'apple_music': 'Apple Music',
  'youtube': 'YouTube',
  'soundcloud': 'SoundCloud',
  'audiomack': 'Audiomack',
  'instagram': 'Instagram',
  'tiktok': 'TikTok',
  'website': 'Website',
};

const kVisibilityKeys = ['contact', 'location', 'portfolio', 'links', 'experience'];

class MusicPassport {
  final String userId;
  final String slug;
  final String stageName;
  final String? fullName;
  final String? photoUrl;
  final String primaryRole;
  final List<String> secondaryRoles;
  final List<String> skills;
  final String? country;
  final String? city;
  final String? bio;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredContact;
  final int? yearsExperience;
  final List<String> genres;
  final List<String> instruments;
  final List<String> languages;
  final String availability;
  final List<String> arrangements;
  final String? operatingLocation;
  final Map<String, String> links;
  final Map<String, bool> visibility;
  final bool isPublished;
  final bool portfolioPublic;

  const MusicPassport({
    required this.userId,
    required this.slug,
    required this.stageName,
    this.fullName,
    this.photoUrl,
    required this.primaryRole,
    this.secondaryRoles = const [],
    this.skills = const [],
    this.country,
    this.city,
    this.bio,
    this.contactEmail,
    this.contactPhone,
    this.preferredContact,
    this.yearsExperience,
    this.genres = const [],
    this.instruments = const [],
    this.languages = const [],
    this.availability = 'available',
    this.arrangements = const [],
    this.operatingLocation,
    this.links = const {},
    this.visibility = const {},
    this.isPublished = false,
    this.portfolioPublic = true,
  });

  List<String> get allRoles => [primaryRole, ...secondaryRoles];
  String get location => [city, country].where((s) => s != null && s.isNotEmpty).join(', ');
  bool visible(String key) => visibility[key] ?? (key != 'contact');

  static List<String> _list(dynamic v) => v == null ? const [] : (v as List).map((e) => e.toString()).toList();

  /// Works for both the owner's row (`music_passports`) and the public view (`public_passports`).
  factory MusicPassport.fromJson(Map<String, dynamic> j) => MusicPassport(
        userId: j['user_id'],
        slug: j['slug'],
        stageName: j['stage_name'],
        fullName: j['full_name'],
        photoUrl: j['photo_url'],
        primaryRole: j['primary_role'],
        secondaryRoles: _list(j['secondary_roles']),
        skills: _list(j['skills']),
        country: j['country'],
        city: j['city'],
        bio: j['bio'],
        contactEmail: j['contact_email'],
        contactPhone: j['contact_phone'],
        preferredContact: j['preferred_contact'],
        yearsExperience: j['years_experience'],
        genres: _list(j['genres']),
        instruments: _list(j['instruments']),
        languages: _list(j['languages']),
        availability: j['availability'] ?? 'available',
        arrangements: _list(j['arrangements']),
        operatingLocation: j['operating_location'],
        links: ((j['links'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        visibility: ((j['visibility'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), v == true)),
        isPublished: j['is_published'] ?? true,
        portfolioPublic: j['portfolio_public'] ?? true,
      );

  Map<String, dynamic> toRow() => {
        'slug': slug,
        'stage_name': stageName,
        'full_name': fullName,
        'photo_url': photoUrl,
        'primary_role': primaryRole,
        'secondary_roles': secondaryRoles,
        'skills': skills,
        'country': country,
        'city': city,
        'bio': bio,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'preferred_contact': preferredContact,
        'years_experience': yearsExperience,
        'genres': genres,
        'instruments': instruments,
        'languages': languages,
        'availability': availability,
        'arrangements': arrangements,
        'operating_location': operatingLocation,
        'links': links,
        'visibility': visibility,
        'is_published': isPublished,
        'updated_at': DateTime.now().toIso8601String(),
      };
}

class PortfolioItem {
  final String? id;
  final String kind;
  final String title;
  final String? role;
  final int? year;
  final String? url;
  final String? imageUrl;
  final String? description;
  final bool isPublic;
  final int sortOrder;

  const PortfolioItem({
    this.id,
    required this.kind,
    required this.title,
    this.role,
    this.year,
    this.url,
    this.imageUrl,
    this.description,
    this.isPublic = true,
    this.sortOrder = 0,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> j) => PortfolioItem(
        id: j['id'],
        kind: j['kind'],
        title: j['title'],
        role: j['role'],
        year: j['year'],
        url: j['url'],
        imageUrl: j['image_url'],
        description: j['description'],
        isPublic: j['is_public'] ?? true,
        sortOrder: j['sort_order'] ?? 0,
      );

  Map<String, dynamic> toRow() => {
        'kind': kind,
        'title': title,
        'role': role,
        'year': year,
        'url': url,
        'image_url': imageUrl,
        'description': description,
        'is_public': isPublic,
        'sort_order': sortOrder,
      };
}

/// The signed-in user's own passport (null until created).
final myPassportProvider = FutureProvider<MusicPassport?>((ref) async {
  ref.watch(currentUserIdProvider);
  final uid = _client.auth.currentUser?.id;
  if (uid == null) return null;
  final row = await _client.from('music_passports').select().eq('user_id', uid).maybeSingle();
  return row == null ? null : MusicPassport.fromJson(row);
});

final myPortfolioProvider = FutureProvider<List<PortfolioItem>>((ref) async {
  ref.watch(currentUserIdProvider);
  final uid = _client.auth.currentUser?.id;
  if (uid == null) return [];
  final rows = await _client.from('passport_portfolio_items').select().eq('user_id', uid).order('sort_order');
  return (rows as List).map((e) => PortfolioItem.fromJson(e)).toList();
});

/// A published passport by public link (works signed out).
final publicPassportBySlugProvider = FutureProvider.family<MusicPassport?, String>((ref, slug) async {
  final row = await _client.from('public_passports').select().eq('slug', slug.toLowerCase()).maybeSingle();
  return row == null ? null : MusicPassport.fromJson(row);
});

/// A published passport by user (opportunity owners and applicants).
final publicPassportByUserProvider = FutureProvider.family<MusicPassport?, String>((ref, userId) async {
  final row = await _client.from('public_passports').select().eq('user_id', userId).maybeSingle();
  return row == null ? null : MusicPassport.fromJson(row);
});

final publicPortfolioProvider = FutureProvider.family<List<PortfolioItem>, String>((ref, userId) async {
  final rows = await _client.from('public_portfolio_items').select().eq('user_id', userId).order('sort_order');
  return (rows as List).map((e) => PortfolioItem.fromJson(e)).toList();
});

Future<void> savePassport(MusicPassport p) async {
  final uid = _client.auth.currentUser!.id;
  await _client.from('music_passports').upsert({'user_id': uid, ...p.toRow()});
}

Future<bool> slugAvailable(String slug) async => await _client.rpc('slug_available', params: {'p_slug': slug}) == true;

/// "Ayo Bami!" → "ayo-bami"
String slugify(String s) {
  final base = s
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâä]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return base.length > 40 ? base.substring(0, 40) : base;
}

final kSlugPattern = RegExp(r'^[a-z0-9][a-z0-9-]{2,39}$');

/// Public URL of a passport, e.g. https://splitsure.vercel.app/passport/ayo-bami
/// Override at build time with --dart-define=APP_URL=https://your-domain.
const _kAppBaseUrl = String.fromEnvironment('APP_URL', defaultValue: 'https://splitsure.vercel.app');

String passportLink(String slug) => '$_kAppBaseUrl/passport/$slug';

Future<String> uploadPassportImage(Uint8List bytes, String ext) async {
  final uid = _client.auth.currentUser!.id;
  final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
  await _client.storage
      .from('passport-media')
      .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: imageMime(ext), upsert: true));
  return _client.storage.from('passport-media').getPublicUrl(path);
}
