import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agreement.dart';

SupabaseClient get _client => Supabase.instance.client;

const _select = '*, agreement_splits(*)';

/// Agreements the user created AND agreements they were invited to (RLS returns both).
final agreementsProvider = FutureProvider<List<Agreement>>((ref) async {
  ref.watch(currentUserIdProvider);
  final data = await _client.from('agreements').select(_select).order('updated_at', ascending: false);
  return (data as List).map((e) => Agreement.fromJson(e)).toList();
});

final agreementProvider = FutureProvider.family<Agreement, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final data = await _client.from('agreements').select(_select).eq('id', id).single();
  return Agreement.fromJson(data);
});

final agreementVersionsProvider = FutureProvider.family<List<AgreementVersion>, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final data = await _client
      .from('agreement_versions')
      .select()
      .eq('agreement_id', id)
      .order('version', ascending: false);
  return (data as List).map((e) => AgreementVersion.fromJson(e)).toList();
});

final agreementResponsesProvider = FutureProvider.family<List<AgreementResponseRecord>, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final data = await _client
      .from('agreement_responses')
      .select()
      .eq('agreement_id', id)
      .order('created_at', ascending: false);
  return (data as List).map((e) => AgreementResponseRecord.fromJson(e)).toList();
});

/// Fields shared by create and update.
class AgreementDraft {
  String songTitle;
  String? projectId;
  String? description;
  String? genre;
  String? coverArtUrl;
  String? recordingDate;
  String? releaseDate;
  String? scopeOfRights;
  List<String> scopeCategories;
  String? paymentTerms;
  String? additionalTerms;
  String? effectiveDate;
  String? witnessName, witnessEmail, witnessPhone, witnessRole;
  String? lawyerName, lawyerFirm, lawyerEmail, lawyerPhone, lawyerRegistration;
  List<Map<String, dynamic>> splits;

  AgreementDraft({
    required this.songTitle,
    this.projectId,
    this.description,
    this.genre,
    this.coverArtUrl,
    this.recordingDate,
    this.releaseDate,
    this.scopeOfRights,
    this.scopeCategories = const [],
    this.paymentTerms,
    this.additionalTerms,
    this.effectiveDate,
    this.witnessName,
    this.witnessEmail,
    this.witnessPhone,
    this.witnessRole,
    this.lawyerName,
    this.lawyerFirm,
    this.lawyerEmail,
    this.lawyerPhone,
    this.lawyerRegistration,
    this.splits = const [],
  });

  Map<String, dynamic> toRow() {
    String? n(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    return {
      'song_title': songTitle.trim(),
      if (projectId != null) 'project_id': projectId,
      'description': n(description),
      'genre': n(genre),
      'cover_art_url': coverArtUrl,
      'recording_date': recordingDate,
      'release_date': releaseDate,
      'scope_of_rights': n(scopeOfRights),
      if (scopeCategories.isNotEmpty) 'scope_categories': scopeCategories,
      if (n(paymentTerms) != null) 'payment_terms': n(paymentTerms),
      'additional_terms': n(additionalTerms),
      'effective_date': effectiveDate,
      'witness_name': n(witnessName),
      'witness_email': n(witnessEmail),
      'witness_phone': n(witnessPhone),
      'witness_role': n(witnessRole),
      'lawyer_name': n(lawyerName),
      'lawyer_firm': n(lawyerFirm),
      'lawyer_email': n(lawyerEmail),
      'lawyer_phone': n(lawyerPhone),
      'lawyer_registration': n(lawyerRegistration),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

Future<Agreement> createAgreement(AgreementDraft d) async {
  final row = await _client.from('agreements').insert({...d.toRow(), 'status': 'draft'}).select('id').single();
  final id = row['id'] as String;
  if (d.splits.isNotEmpty) {
    await _client.from('agreement_splits').insert(d.splits.map((s) => {...s, 'agreement_id': id}).toList());
  }
  final fresh = await _client.from('agreements').select(_select).eq('id', id).single();
  return Agreement.fromJson(fresh);
}

/// Saves edits. Existing collaborator lines are updated in place (keeping their
/// invitation links), new ones inserted, removed ones deleted.
/// If the agreement was already sent, call [sendForReview] afterwards to publish a new version.
Future<void> updateAgreement(String id, AgreementDraft d, {required List<String> existingSplitIds}) async {
  await _client.from('agreements').update(d.toRow()).eq('id', id);
  final keep = <String>{};
  for (final s in d.splits) {
    final splitId = s['id'] as String?;
    final data = Map<String, dynamic>.from(s)..remove('id');
    if (splitId != null) {
      keep.add(splitId);
      await _client.from('agreement_splits').update(data).eq('id', splitId);
    } else {
      await _client.from('agreement_splits').insert({...data, 'agreement_id': id});
    }
  }
  final removed = existingSplitIds.where((e) => !keep.contains(e)).toList();
  if (removed.isNotEmpty) {
    await _client.from('agreement_splits').delete().inFilter('id', removed);
  }
}

/// Outcome of sending an agreement for review.
class SendResult {
  final int version;

  /// Collaborators e-mailed for this version (0 when e-mail isn't configured or nobody has an address).
  final int emailed;
  final bool emailConfigured;
  const SendResult(this.version, {this.emailed = 0, this.emailConfigured = true});
}

/// Sends the agreement to collaborators (first time = version 1; afterwards a new version).
/// Collaborators who already have an account get an in-app/push notification (server side);
/// everyone with an e-mail address also gets a branded "Review & approve" e-mail.
Future<SendResult> sendForReview(String id, {String? note}) async {
  final v = await _client.rpc('send_agreement_for_review', params: {'p_agreement': id, 'p_note': note});
  final version = (v as num).toInt();
  try {
    final res = await _client.functions.invoke('agreement-emails', body: {'agreement_id': id, if (note != null) 'note': note});
    final d = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    return SendResult(version,
        emailed: (d['sent'] as num?)?.toInt() ?? 0, emailConfigured: d['configured'] != false);
  } catch (_) {
    // The agreement is already sent and in-app notifications are out; e-mail is best effort.
    return SendResult(version, emailConfigured: false);
  }
}

/// The signed-in collaborator accepts, requests changes or declines their line.
Future<String> respondToAgreement(String splitId, String response, {String? note}) async {
  final s = await _client.rpc('respond_to_agreement', params: {
    'p_split': splitId,
    'p_response': response,
    'p_note': note,
  });
  return s as String;
}

/// Asks the witness of an already-sent agreement to confirm the current version.
/// Returns whether the witness e-mail went out (false when e-mail isn't configured).
Future<bool> inviteWitness(String id) async {
  await _client.rpc('invite_witness', params: {'p_agreement': id});
  try {
    final res = await _client.functions.invoke('agreement-emails', body: {'agreement_id': id, 'witness_only': true});
    return (res.data as Map?)?['witness'] == 'sent';
  } catch (_) {
    return false; // in-app notification is already out; e-mail is best effort
  }
}

/// The signed-in witness confirms or declines the agreement.
Future<String> respondAsWitness(String agreementId, String response, {String? note}) async {
  final r = await _client.rpc('respond_as_witness', params: {
    'p_agreement': agreementId,
    'p_response': response,
    'p_note': note,
  });
  return ((r as Map?)?['status'] ?? '') as String;
}

/// Links the signed-in user to an invitation and returns the agreement id.
Future<String> claimInvite(String token) async {
  final id = await _client.rpc('claim_agreement_invite', params: {'p_token': token});
  return id as String;
}

Future<void> deleteAgreement(String id) async {
  await _client.from('agreements').delete().eq('id', id);
}

// ── Private PDF storage ────────────────────────────────────────────────────

const _pdfBucket = 'agreement-pdfs';

/// Stores the final PDF once (allowed only after unlock) and records it for every party.
Future<String> storeFinalAgreementPdf(Agreement a, Uint8List bytes) async {
  final path = '${a.id}/final-v${a.version}.pdf';
  await _client.storage.from(_pdfBucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
      );
  await _client.rpc('record_final_pdf', params: {'p_agreement': a.id, 'p_path': path});
  return path;
}

Future<void> openStoredAgreementPdf(String path) async {
  final url = await signedPdfUrl(path);
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Unlock record of an agreement's final document (null = not unlocked yet).
class AgreementDocument {
  final String unlockedVia; // pro | payment
  final String? pdfPath;
  const AgreementDocument(this.unlockedVia, this.pdfPath);
}

final agreementDocumentProvider = FutureProvider.family<AgreementDocument?, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final row = await _client.from('agreement_documents').select('unlocked_via, pdf_path').eq('agreement_id', id).maybeSingle();
  return row == null ? null : AgreementDocument(row['unlocked_via'], row['pdf_path']);
});

/// Who may open this agreement's PDF: 'unlocked' (paid or already unlocked),
/// 'free' (Pro, or the creator's first agreement) or 'pay' (50 FCFA needed).
final agreementDocAccessProvider = FutureProvider.family<String, String>((ref, id) async {
  ref.watch(currentUserIdProvider);
  final r = await _client.rpc('agreement_document_access', params: {'p_agreement': id});
  return r as String;
});

/// Unlocks the final document for free cases (Pro, or the first agreement).
Future<void> unlockAgreementFree(String id) => _client.rpc('unlock_agreement_free', params: {'p_agreement': id});

/// Pro users unlock final generation server-side (no charge).
Future<void> unlockAgreementWithPro(String id) => _client.rpc('unlock_agreement_with_pro', params: {'p_agreement': id});

/// Short-lived link for an authorised party to download the stored PDF.
Future<String> signedPdfUrl(String path) =>
    _client.storage.from(_pdfBucket).createSignedUrl(path, 60 * 10);

/// Invitation link a creator can share with an external collaborator.
String inviteLink(AgreementSplit s) {
  final base = Uri.base;
  final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
  return '$origin/invite/${s.inviteToken}';
}
