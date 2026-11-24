import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';

class UserProfile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String? country;
  final String? city;
  final String? phone;
  final List<String> musicRoles;
  final String? whatsappUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String? facebookUrl;

  const UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarUrl,
    this.bio,
    this.country,
    this.city,
    this.phone,
    this.musicRoles = const [],
    this.whatsappUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    this.facebookUrl,
  });

  String get displayName {
    // Names are shown capitalised ("randolp" → "Randolp") whatever was typed.
    final name = [firstName, lastName]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim()[0].toUpperCase() + s.trim().substring(1))
        .join(' ');
    return name.isNotEmpty ? name : (username ?? 'Artist');
  }

  String get initials {
    final f = firstName?.isNotEmpty == true ? firstName![0].toUpperCase() : '';
    final l = lastName?.isNotEmpty == true ? lastName![0].toUpperCase() : '';
    return (f + l).isNotEmpty ? (f + l) : 'A';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        username: json['username'],
        avatarUrl: json['avatar_url'],
        bio: json['bio'],
        country: json['country'],
        city: json['city'],
        phone: json['phone'],
        musicRoles: (json['music_roles'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        whatsappUrl: json['whatsapp_url'],
        tiktokUrl: json['tiktok_url'],
        youtubeUrl: json['youtube_url'],
        facebookUrl: json['facebook_url'],
      );
}

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(currentUserIdProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final data = await Supabase.instance.client.from('profiles').select().eq('id', user.id).maybeSingle();
  if (data == null) return null;
  return UserProfile.fromJson(data);
});
