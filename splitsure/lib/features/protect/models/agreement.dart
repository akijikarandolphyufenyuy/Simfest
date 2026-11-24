import 'package:supabase_flutter/supabase_flutter.dart';

/// Rights / revenue categories an agreement can cover (stored as stable keys).
const kScopeCategories = ['master', 'composition', 'lyrics', 'production', 'other'];

class Agreement {
  final String id;
  final String? userId;
  final String? projectId;
  final String songTitle;
  final String? description;
  final String? genre;
  final String? coverArtUrl;
  final String? recordingDate;
  final String? releaseDate;
  final String? scopeOfRights;
  final List<String> scopeCategories;
  final String? paymentTerms;
  final String? additionalTerms;
  final String? effectiveDate;
  final String status;
  final int version;
  final String? reference;
  final DateTime? finalizedAt;
  final String? witnessName;
  final String? witnessEmail;
  final String? witnessPhone;
  final String? witnessRole;
  final String? witnessUserId;
  final int? witnessInvitedVersion;
  final String? witnessResponse; // confirmed | declined
  final String? witnessNote;
  final DateTime? witnessRespondedAt;
  final String? witnessSignatureCode;
  final String? lawyerName;
  final String? lawyerFirm;
  final String? lawyerEmail;
  final String? lawyerPhone;
  final String? lawyerRegistration;
  final String? pdfUrl;
  final String? pdfPath;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<AgreementSplit> splits;

  Agreement({
    required this.id,
    this.userId,
    this.projectId,
    required this.songTitle,
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
    required this.status,
    this.version = 1,
    this.reference,
    this.finalizedAt,
    this.witnessName,
    this.witnessEmail,
    this.witnessPhone,
    this.witnessRole,
    this.witnessUserId,
    this.witnessInvitedVersion,
    this.witnessResponse,
    this.witnessNote,
    this.witnessRespondedAt,
    this.witnessSignatureCode,
    this.lawyerName,
    this.lawyerFirm,
    this.lawyerEmail,
    this.lawyerPhone,
    this.lawyerRegistration,
    this.pdfUrl,
    this.pdfPath,
    required this.createdAt,
    this.updatedAt,
    this.splits = const [],
  });

  /// True when the signed-in user created this agreement.
  bool get isOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return userId == null || userId == uid;
  }

  /// The collaborator line belonging to the signed-in user, if any.
  AgreementSplit? get mySplit {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    for (final s in splits) {
      if (s.userId == user.id) return s;
    }
    for (final s in splits) {
      if (s.userId == null &&
          s.collaboratorEmail != null &&
          s.collaboratorEmail!.toLowerCase() == (user.email ?? '').toLowerCase()) {
        return s;
      }
    }
    return null;
  }

  /// True when the signed-in user is this agreement's witness.
  bool get isMyWitness {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    if (witnessUserId != null) return witnessUserId == user.id;
    final e = witnessEmail?.trim().toLowerCase();
    return e != null && e.isNotEmpty && e == (user.email ?? '').toLowerCase();
  }

  /// The witness was asked to confirm the current version.
  bool get witnessInvited => witnessInvitedVersion != null && witnessInvitedVersion == version;

  double get totalPercentage => splits.fold(0.0, (sum, s) => sum + s.splitPercentage);
  bool get isOpenForResponses => status == 'pending' || status == 'changes_requested';
  bool get isEditable => isOwner && status != 'accepted';
  String get displayReference => reference ?? 'SS-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}';

  factory Agreement.fromJson(Map<String, dynamic> json) => Agreement(
        id: json['id'],
        userId: json['user_id'],
        projectId: json['project_id'],
        songTitle: json['song_title'],
        description: json['description'],
        genre: json['genre'],
        coverArtUrl: json['cover_art_url'],
        recordingDate: json['recording_date'],
        releaseDate: json['release_date'],
        scopeOfRights: json['scope_of_rights'],
        scopeCategories: (json['scope_categories'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
        paymentTerms: json['payment_terms'],
        additionalTerms: json['additional_terms'],
        effectiveDate: json['effective_date'],
        status: json['status'],
        version: (json['version'] as num?)?.toInt() ?? 1,
        reference: json['reference'],
        finalizedAt: json['finalized_at'] != null ? DateTime.parse(json['finalized_at']) : null,
        witnessName: json['witness_name'],
        witnessEmail: json['witness_email'],
        witnessPhone: json['witness_phone'],
        witnessRole: json['witness_role'],
        witnessUserId: json['witness_user_id'],
        witnessInvitedVersion: (json['witness_invited_version'] as num?)?.toInt(),
        witnessResponse: json['witness_response'],
        witnessNote: json['witness_note'],
        witnessRespondedAt: json['witness_responded_at'] != null ? DateTime.parse(json['witness_responded_at']) : null,
        witnessSignatureCode: json['witness_signature_code'],
        lawyerName: json['lawyer_name'],
        lawyerFirm: json['lawyer_firm'],
        lawyerEmail: json['lawyer_email'],
        lawyerPhone: json['lawyer_phone'],
        lawyerRegistration: json['lawyer_registration'],
        pdfUrl: json['pdf_url'],
        pdfPath: json['pdf_path'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        splits: (json['agreement_splits'] as List<dynamic>? ?? [])
            .map((s) => AgreementSplit.fromJson(s))
            .toList()
          ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0))),
      );
}

class AgreementSplit {
  final String id;
  final String? userId;
  final String collaboratorName;
  final String? collaboratorEmail;
  final String? phone;
  final String role;
  final String? contributionDescription;
  final double splitPercentage;
  final String? response;
  final String? responseNote;
  final DateTime? acceptedAt;
  final DateTime? respondedAt;

  /// Electronic signature stamped when this party accepted (e.g. SS-1A2B-3C4D-5E6F).
  final String? signatureCode;

  /// How the party signed: 'app' or 'email'.
  final String? signedVia;
  final String? inviteToken;
  final bool isRequired;
  final DateTime? createdAt;

  AgreementSplit({
    required this.id,
    this.userId,
    required this.collaboratorName,
    this.collaboratorEmail,
    this.phone,
    required this.role,
    this.contributionDescription,
    required this.splitPercentage,
    this.response,
    this.responseNote,
    this.acceptedAt,
    this.respondedAt,
    this.signatureCode,
    this.signedVia,
    this.inviteToken,
    this.isRequired = true,
    this.createdAt,
  });

  bool get isLinked => userId != null;

  factory AgreementSplit.fromJson(Map<String, dynamic> json) => AgreementSplit(
        id: json['id'],
        userId: json['user_id'],
        collaboratorName: json['collaborator_name'],
        collaboratorEmail: json['collaborator_email'],
        phone: json['phone'],
        role: json['role'],
        contributionDescription: json['contribution_description'],
        splitPercentage: (json['split_percentage'] as num).toDouble(),
        response: json['response'],
        responseNote: json['response_note'],
        acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
        respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at']) : null,
        signatureCode: json['signature_code'],
        signedVia: json['signed_via'],
        inviteToken: json['invite_token'],
        isRequired: json['is_required'] ?? true,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      );
}

class AgreementVersion {
  final int version;
  final String? changeNote;
  final DateTime createdAt;
  final Map<String, dynamic> snapshot;

  AgreementVersion({required this.version, this.changeNote, required this.createdAt, required this.snapshot});

  factory AgreementVersion.fromJson(Map<String, dynamic> j) => AgreementVersion(
        version: (j['version'] as num).toInt(),
        changeNote: j['change_note'],
        createdAt: DateTime.parse(j['created_at']),
        snapshot: Map<String, dynamic>.from(j['snapshot'] ?? {}),
      );
}

class AgreementResponseRecord {
  final String splitId;
  final int version;
  final String response;
  final String? note;
  final DateTime createdAt;

  AgreementResponseRecord({
    required this.splitId,
    required this.version,
    required this.response,
    this.note,
    required this.createdAt,
  });

  factory AgreementResponseRecord.fromJson(Map<String, dynamic> j) => AgreementResponseRecord(
        splitId: j['split_id'],
        version: (j['version'] as num).toInt(),
        response: j['response'],
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']),
      );
}
