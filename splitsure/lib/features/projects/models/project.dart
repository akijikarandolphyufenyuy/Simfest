import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';

const kProjectStatuses = ['idea', 'in_progress', 'recorded', 'released'];

class Project {
  final String id;
  final String? userId;
  final String title;
  final String? genre;
  final String? description;
  final String? coverArtUrl;
  final String? recordingDate;
  final String? releaseDate;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    this.userId,
    required this.title,
    this.genre,
    this.description,
    this.coverArtUrl,
    this.recordingDate,
    this.releaseDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOwner => userId == null || userId == Supabase.instance.client.auth.currentUser?.id;

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'],
        userId: j['user_id'],
        title: j['title'],
        genre: j['genre'],
        description: j['description'],
        coverArtUrl: j['cover_art_url'],
        recordingDate: j['recording_date'],
        releaseDate: j['release_date'],
        status: j['status'] ?? 'in_progress',
        createdAt: DateTime.parse(j['created_at']),
        updatedAt: j['updated_at'] != null ? DateTime.parse(j['updated_at']) : null,
      );
}

SupabaseClient get _client => Supabase.instance.client;

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  ref.watch(currentUserIdProvider);
  try {
    final data = await _client.from('projects').select().order('updated_at', ascending: false);
    return (data as List).map((e) => Project.fromJson(e)).toList();
  } on PostgrestException catch (e) {
    // Table missing until migration 002 is applied: show an empty list instead of crashing.
    if (e.code == '42P01' || e.code == 'PGRST205') return [];
    rethrow;
  }
});

Future<Project> saveProject({
  String? id,
  required String title,
  String? genre,
  String? description,
  String? coverArtUrl,
  String? recordingDate,
  String? releaseDate,
  required String status,
}) async {
  String? n(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
  final row = {
    'title': title.trim(),
    'genre': n(genre),
    'description': n(description),
    'cover_art_url': coverArtUrl,
    'recording_date': recordingDate,
    'release_date': releaseDate,
    'status': status,
    'updated_at': DateTime.now().toIso8601String(),
  };
  final data = id == null
      ? await _client.from('projects').insert(row).select().single()
      : await _client.from('projects').update(row).eq('id', id).select().single();
  return Project.fromJson(data);
}

Future<void> deleteProject(String id) => _client.from('projects').delete().eq('id', id);
