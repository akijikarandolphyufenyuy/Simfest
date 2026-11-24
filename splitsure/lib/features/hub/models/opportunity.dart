import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../passport/models/passport.dart';

SupabaseClient get _client => Supabase.instance.client;
String? get _uid => _client.auth.currentUser?.id;

const kOpportunityCategories = [
  'recording', 'songwriting', 'production', 'performance', 'video', 'live', 'marketing', 'business', 'other',
];

String opportunityCategoryLabel(AppLocalizations l10n, String c) => switch (c) {
      'recording' => l10n.categoryRecording,
      'songwriting' => l10n.categorySongwriting,
      'production' => l10n.categoryProduction,
      'performance' => l10n.categoryPerformance,
      'video' => l10n.categoryVideo,
      'live' => l10n.categoryLive,
      'marketing' => l10n.categoryMarketing,
      'business' => l10n.categoryBusiness,
      _ => l10n.categoryOther,
    };

const kApplicationStatuses = ['pending', 'under_review', 'shortlisted', 'accepted', 'rejected', 'withdrawn'];

String applicationStatusLabel(AppLocalizations l10n, String s) => switch (s) {
      'under_review' => l10n.appStatusUnderReview,
      'shortlisted' => l10n.appStatusShortlisted,
      'accepted' => l10n.appStatusAccepted,
      'rejected' => l10n.appStatusRejected,
      'withdrawn' => l10n.appStatusWithdrawn,
      _ => l10n.appStatusPending,
    };

class Opportunity {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String category;
  final List<String> requiredRoles;
  final List<String> skills;
  final List<String> genres;
  final String? location;
  final bool isRemote;
  final String collaborationType;
  final String? compensation;
  final String? deliverables;
  final DateTime? projectDeadline;
  final DateTime? applicationDeadline;
  final int positions;
  final List<String> referenceLinks;
  final String? requirements;
  final bool restrictToRoles;
  final String status;
  final DateTime createdAt;

  const Opportunity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    this.requiredRoles = const [],
    this.skills = const [],
    this.genres = const [],
    this.location,
    this.isRemote = true,
    required this.collaborationType,
    this.compensation,
    this.deliverables,
    this.projectDeadline,
    this.applicationDeadline,
    this.positions = 1,
    this.referenceLinks = const [],
    this.requirements,
    this.restrictToRoles = false,
    this.status = 'open',
    required this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isMine => ownerId == _uid;
  bool get applicationsClosed =>
      !isOpen ||
      (applicationDeadline != null &&
          applicationDeadline!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)));

  static List<String> _l(dynamic v) => v == null ? const [] : (v as List).map((e) => e.toString()).toList();
  static DateTime? _d(dynamic v) => v == null ? null : DateTime.parse(v);

  factory Opportunity.fromJson(Map<String, dynamic> j) => Opportunity(
        id: j['id'],
        ownerId: j['owner_id'],
        title: j['title'],
        description: j['description'],
        category: j['category'],
        requiredRoles: _l(j['required_roles']),
        skills: _l(j['skills']),
        genres: _l(j['genres']),
        location: j['location'],
        isRemote: j['is_remote'] ?? true,
        collaborationType: j['collaboration_type'],
        compensation: j['compensation'],
        deliverables: j['deliverables'],
        projectDeadline: _d(j['project_deadline']),
        applicationDeadline: _d(j['application_deadline']),
        positions: j['positions'] ?? 1,
        referenceLinks: _l(j['reference_links']),
        requirements: j['requirements'],
        restrictToRoles: j['restrict_to_roles'] ?? false,
        status: j['status'] ?? 'open',
        createdAt: DateTime.parse(j['created_at']),
      );

  /// How well this matches the viewer's roles (used for "Recommended for you").
  int matchScore(List<String> myRoles) => requiredRoles.where(myRoles.contains).length;
}

String _date(DateTime? d) => d == null ? '' : d.toIso8601String().substring(0, 10);

Map<String, dynamic> opportunityRow({
  required String title,
  required String description,
  required String category,
  required List<String> requiredRoles,
  required List<String> skills,
  required List<String> genres,
  String? location,
  required bool isRemote,
  required String collaborationType,
  String? compensation,
  String? deliverables,
  DateTime? projectDeadline,
  DateTime? applicationDeadline,
  required int positions,
  required List<String> referenceLinks,
  String? requirements,
  required bool restrictToRoles,
}) =>
    {
      'title': title,
      'description': description,
      'category': category,
      'required_roles': requiredRoles,
      'skills': skills,
      'genres': genres,
      'location': location,
      'is_remote': isRemote,
      'collaboration_type': collaborationType,
      'compensation': compensation,
      'deliverables': deliverables,
      'project_deadline': projectDeadline == null ? null : _date(projectDeadline),
      'application_deadline': applicationDeadline == null ? null : _date(applicationDeadline),
      'positions': positions,
      'reference_links': referenceLinks,
      'requirements': requirements,
      'restrict_to_roles': restrictToRoles,
      'updated_at': DateTime.now().toIso8601String(),
    };

class Application {
  final String id;
  final String opportunityId;
  final String applicantId;
  final String message;
  final List<String> links;
  final String status;
  final DateTime createdAt;

  const Application({
    required this.id,
    required this.opportunityId,
    required this.applicantId,
    required this.message,
    this.links = const [],
    required this.status,
    required this.createdAt,
  });

  bool get canWithdraw => status != 'accepted' && status != 'withdrawn';

  factory Application.fromJson(Map<String, dynamic> j) => Application(
        id: j['id'],
        opportunityId: j['opportunity_id'],
        applicantId: j['applicant_id'],
        message: j['message'],
        links: Opportunity._l(j['links']),
        status: j['status'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

/// Every opportunity the viewer is allowed to see (RLS applies role targeting).
final openOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  ref.watch(currentUserIdProvider);
  final rows = await _client
      .from('collaboration_opportunities')
      .select()
      .eq('status', 'open')
      .order('created_at', ascending: false)
      .limit(200);
  return (rows as List).map((e) => Opportunity.fromJson(e)).toList();
});

final myOpportunitiesProvider = FutureProvider<List<Opportunity>>((ref) async {
  ref.watch(currentUserIdProvider);
  final uid = _uid;
  if (uid == null) return [];
  final rows =
      await _client.from('collaboration_opportunities').select().eq('owner_id', uid).order('created_at', ascending: false);
  return (rows as List).map((e) => Opportunity.fromJson(e)).toList();
});

final opportunityProvider = FutureProvider.family<Opportunity?, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final row = await _client.from('collaboration_opportunities').select().eq('id', id).maybeSingle();
  return row == null ? null : Opportunity.fromJson(row);
});

final ownerOpenOpportunitiesProvider = FutureProvider.family<List<Opportunity>, String>((ref, ownerId) async {
  ref.watch(currentUserIdProvider);
  final rows = await _client
      .from('collaboration_opportunities')
      .select()
      .eq('owner_id', ownerId)
      .eq('status', 'open')
      .order('created_at', ascending: false);
  return (rows as List).map((e) => Opportunity.fromJson(e)).toList();
});

final applicationCountProvider = FutureProvider.family<int, String>((ref, oppId) async =>
    (await _client.rpc('opportunity_application_count', params: {'p_opp': oppId}) as num?)?.toInt() ?? 0);

/// Applications the viewer sent.
final myApplicationsProvider = FutureProvider<List<Application>>((ref) async {
  ref.watch(currentUserIdProvider);
  final uid = _uid;
  if (uid == null) return [];
  final rows =
      await _client.from('opportunity_applications').select().eq('applicant_id', uid).order('created_at', ascending: false);
  return (rows as List).map((e) => Application.fromJson(e)).toList();
});

/// Applications received for one of the viewer's opportunities.
final receivedApplicationsProvider = FutureProvider.family<List<Application>, String>((ref, oppId) async {
  ref.watch(currentUserIdProvider);
  final rows = await _client
      .from('opportunity_applications')
      .select()
      .eq('opportunity_id', oppId)
      .order('created_at', ascending: false);
  return (rows as List).map((e) => Application.fromJson(e)).toList();
});

/// The viewer's own roles from their Music Passport.
final myRolesProvider = Provider<List<String>>((ref) =>
    ref.watch(myPassportProvider).whenOrNull(data: (p) => p?.allRoles) ?? const []);

Future<bool> canPostOpportunity() async => await _client.rpc('can_post_opportunity') == true;

Future<void> setApplicationStatus(String applicationId, String status) =>
    _client.rpc('set_application_status', params: {'p_application': applicationId, 'p_status': status});

Future<void> withdrawApplication(String applicationId) =>
    _client.rpc('withdraw_application', params: {'p_application': applicationId});

String opportunityLink(String id) {
  final b = Uri.base;
  return '${b.scheme}://${b.host}${b.hasPort ? ':${b.port}' : ''}/opportunity/$id';
}
