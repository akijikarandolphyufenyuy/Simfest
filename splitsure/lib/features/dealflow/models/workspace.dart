import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';
import '../../../core/localization/l10n/app_localizations.dart';

SupabaseClient get _client => Supabase.instance.client;

String workspaceStatusLabel(AppLocalizations l10n, String s) => switch (s) {
      'agreed' => l10n.wsStatusAgreed,
      'in_protect' => l10n.wsStatusInProtect,
      'active' => l10n.wsStatusActive,
      'completed' => l10n.wsStatusCompleted,
      'cancelled' => l10n.wsStatusCancelled,
      _ => l10n.wsStatusNegotiating,
    };

class Workspace {
  final String id;
  final String ownerId;
  final String? opportunityId;
  final String title;
  final String? description;
  final String? deliverables;
  final String? paymentArrangement;
  final String? importantDates;
  final String status;
  final String? agreementId;
  final DateTime createdAt;

  const Workspace({
    required this.id,
    required this.ownerId,
    this.opportunityId,
    required this.title,
    this.description,
    this.deliverables,
    this.paymentArrangement,
    this.importantDates,
    required this.status,
    this.agreementId,
    required this.createdAt,
  });

  bool get isOwner => ownerId == _client.auth.currentUser?.id;
  bool get termsEditable => status == 'negotiating' || status == 'agreed';

  factory Workspace.fromJson(Map<String, dynamic> j) => Workspace(
        id: j['id'],
        ownerId: j['owner_id'],
        opportunityId: j['opportunity_id'],
        title: j['title'],
        description: j['description'],
        deliverables: j['deliverables'],
        paymentArrangement: j['payment_arrangement'],
        importantDates: j['important_dates'],
        status: j['status'],
        agreementId: j['agreement_id'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

class WorkspaceMember {
  final String userId;
  final String displayName;
  final String? role;
  final String? responsibilities;
  final double? percentage;
  final bool agreed;
  final bool isOwner;

  const WorkspaceMember({
    required this.userId,
    required this.displayName,
    this.role,
    this.responsibilities,
    this.percentage,
    this.agreed = false,
    this.isOwner = false,
  });

  bool get isMe => userId == _client.auth.currentUser?.id;

  factory WorkspaceMember.fromJson(Map<String, dynamic> j) => WorkspaceMember(
        userId: j['user_id'],
        displayName: j['display_name'],
        role: j['role'],
        responsibilities: j['responsibilities'],
        percentage: (j['percentage'] as num?)?.toDouble(),
        agreed: j['agreed'] ?? false,
        isOwner: j['is_owner'] ?? false,
      );
}

class WorkspaceMessage {
  final String id;
  final String userId;
  final String body;
  final DateTime createdAt;
  const WorkspaceMessage({required this.id, required this.userId, required this.body, required this.createdAt});

  factory WorkspaceMessage.fromJson(Map<String, dynamic> j) =>
      WorkspaceMessage(id: j['id'], userId: j['user_id'], body: j['body'], createdAt: DateTime.parse(j['created_at']));
}

final myWorkspacesProvider = FutureProvider<List<Workspace>>((ref) async {
  ref.watch(currentUserIdProvider);
  if (_client.auth.currentUser == null) return [];
  final rows = await _client.from('collaboration_workspaces').select().order('updated_at', ascending: false);
  return (rows as List).map((e) => Workspace.fromJson(e)).toList();
});

final workspaceProvider = FutureProvider.family<Workspace?, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final row = await _client.from('collaboration_workspaces').select().eq('id', id).maybeSingle();
  return row == null ? null : Workspace.fromJson(row);
});

final workspaceForOpportunityProvider = FutureProvider.family<Workspace?, String>((ref, oppId) async {
  ref.watch(currentUserIdProvider);
  final row = await _client.from('collaboration_workspaces').select().eq('opportunity_id', oppId).maybeSingle();
  return row == null ? null : Workspace.fromJson(row);
});

final workspaceMembersProvider = FutureProvider.family<List<WorkspaceMember>, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final rows = await _client.from('workspace_members').select().eq('workspace_id', id).order('joined_at');
  return (rows as List).map((e) => WorkspaceMember.fromJson(e)).toList();
});

/// Live negotiation thread.
final workspaceMessagesProvider = StreamProvider.family<List<WorkspaceMessage>, String>((ref, id) => _client
    .from('workspace_messages')
    .stream(primaryKey: ['id'])
    .eq('workspace_id', id)
    .order('created_at')
    .map((rows) => rows.map(WorkspaceMessage.fromJson).toList()));

Future<String> startWorkspaceFromApplication(String applicationId) async =>
    await _client.rpc('start_workspace_from_application', params: {'p_application': applicationId}) as String;

Future<void> updateMemberTerms(String ws, String userId, {String? role, String? responsibilities, double? percentage}) =>
    _client.rpc('update_member_terms', params: {
      'p_ws': ws,
      'p_user': userId,
      'p_role': role,
      'p_responsibilities': responsibilities,
      'p_percentage': percentage,
    });

Future<String> setTermsAgreed(String ws, bool agreed) async =>
    await _client.rpc('set_terms_agreed', params: {'p_ws': ws, 'p_agreed': agreed}) as String;

Future<void> linkWorkspaceAgreement(String ws, String agreementId) =>
    _client.rpc('link_workspace_agreement', params: {'p_ws': ws, 'p_agreement': agreementId});

Future<void> setWorkspaceStatus(String ws, String status) =>
    _client.rpc('set_workspace_status', params: {'p_ws': ws, 'p_status': status});

Future<void> sendWorkspaceMessage(String ws, String body) =>
    _client.from('workspace_messages').insert({'workspace_id': ws, 'body': body});
