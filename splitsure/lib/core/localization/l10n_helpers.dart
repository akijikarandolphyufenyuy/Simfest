import 'l10n/app_localizations.dart';

/// Values stored in the database stay in English (stable keys);
/// these helpers turn them into display labels in the active language.

const List<String> kCountries = [
  'Cameroon',
  'Nigeria',
  'Ghana',
  'South Africa',
  'Kenya',
  'France',
  'United States',
  'United Kingdom',
  'Other',
];

String countryLabel(AppLocalizations l10n, String value) => switch (value) {
      'Cameroon' => l10n.countryCameroon,
      'Nigeria' => l10n.countryNigeria,
      'Ghana' => l10n.countryGhana,
      'South Africa' => l10n.countrySouthAfrica,
      'Kenya' => l10n.countryKenya,
      'France' => l10n.countryFrance,
      'United States' => l10n.countryUnitedStates,
      'United Kingdom' => l10n.countryUnitedKingdom,
      'Other' => l10n.countryOther,
      _ => value,
    };

String planLabel(AppLocalizations l10n, String plan) => switch (plan) {
      'monthly' => l10n.monthlyPlan,
      'quarterly' => l10n.quarterlyPlan,
      'annual' => l10n.annualPlan,
      'pro' => l10n.proPlan,
      _ => l10n.freePlan,
    };

String agreementStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'draft' => l10n.statusDraft,
      'pending' => l10n.statusPending,
      'accepted' || 'signed' => l10n.statusAccepted,
      'changes_requested' => l10n.statusChangesRequested,
      'declined' => l10n.statusDeclined,
      _ => status,
    };

String campaignStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'draft' => l10n.statusDraft,
      'content_generated' => l10n.statusContentGenerated,
      'ready_to_share' => l10n.statusReadyToShare,
      'completed' => l10n.statusCompleted,
      _ => status,
    };

/// Music roles are stored in English; unknown (free-text) roles are shown as typed.
const List<String> kMusicRoles = [
  'Artist',
  'Producer',
  'Songwriter',
  'Beatmaker',
  'Featured Artist',
  'Composer',
  'Sound Engineer',
  'Music Manager',
  'Other',
];

String musicRoleLabel(AppLocalizations l10n, String role) => switch (role) {
      'Artist' => l10n.roleArtist,
      'Producer' => l10n.roleProducer,
      'Songwriter' => l10n.roleSongwriter,
      'Beatmaker' => l10n.roleBeatmaker,
      'Featured Artist' => l10n.roleFeaturedArtist,
      'Composer' => l10n.roleComposer,
      'Sound Engineer' => l10n.roleSoundEngineer,
      'Music Manager' => l10n.roleMusicManager,
      'Other' => l10n.roleOther,
      _ => role,
    };

String timeAgo(AppLocalizations l10n, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return l10n.daysAgo(diff.inDays);
  if (diff.inHours > 0) return l10n.hoursAgo(diff.inHours);
  if (diff.inMinutes > 0) return l10n.minutesAgo(diff.inMinutes);
  return l10n.justNow;
}

String scopeCategoryLabel(AppLocalizations l10n, String key) => switch (key) {
      'master' => l10n.scopeMaster,
      'composition' => l10n.scopeComposition,
      'lyrics' => l10n.scopeLyrics,
      'production' => l10n.scopeProduction,
      'other' => l10n.scopeOther,
      _ => key,
    };

String projectStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'idea' => l10n.projectStatusIdea,
      'in_progress' => l10n.projectStatusInProgress,
      'recorded' => l10n.projectStatusRecorded,
      'released' => l10n.projectStatusReleased,
      _ => status,
    };

/// dd/mm/yyyy for a DateTime or an ISO date string.
String formatDate(Object? value) {
  final d = value is DateTime ? value : (value is String ? DateTime.tryParse(value) : null);
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String paymentStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'demo' => l10n.paymentDemo,
      'pending' => l10n.paymentPending,
      'paid' => l10n.paymentPaid,
      'success' => l10n.paymentSuccess,
      'cancelled' => l10n.paymentCancelled,
      'failed' => l10n.paymentFailed,
      'refunded' => l10n.paymentRefunded,
      _ => status,
    };

/// "randolp" → "Randolp" (keeps the rest as typed, e.g. "McKay").
String capitalizeName(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// [s] without emoji, for showing inside the app.
///
/// Flutter Web has no emoji in the app font, so displaying one makes it
/// download the ~10 MB "Noto Color Emoji" font (slow, and it times out on weak
/// connections). Captions keep their emoji when copied or shared.
String withoutEmoji(String s) => s
    .replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]', unicode: true), '')
    .replaceAll(RegExp(r'^[ \t]+', multiLine: true), '')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ');
