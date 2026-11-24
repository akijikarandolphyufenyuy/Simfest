class Campaign {
  final String id;
  final String? userId;
  final String? projectId;
  final String? artistName;
  final String? videoUrl;
  final String? videoTemplate;
  final String songTitle;
  final String? campaignName;
  final String? description;
  final String? targetAudience;
  final int budgetXaf;
  final String? coverArtUrl;
  final String? musicFileUrl;
  final String? releaseDate;
  final String? promotionalMessage;
  final String? streamingLink;
  final double? snippetStart;
  final double? snippetEnd;
  final String? generatedCaptions;
  final String? generatedHashtags;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Campaign({
    required this.id,
    this.userId,
    this.projectId,
    this.artistName,
    this.videoUrl,
    this.videoTemplate,
    required this.songTitle,
    this.campaignName,
    this.description,
    this.targetAudience,
    required this.budgetXaf,
    this.coverArtUrl,
    this.musicFileUrl,
    this.releaseDate,
    this.promotionalMessage,
    this.streamingLink,
    this.snippetStart,
    this.snippetEnd,
    this.generatedCaptions,
    this.generatedHashtags,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'],
        userId: json['user_id'],
        projectId: json['project_id'],
        artistName: json['artist_name'],
        videoUrl: json['video_url'],
        videoTemplate: json['video_template'],
        songTitle: json['song_title'],
        campaignName: json['campaign_name'],
        description: json['description'],
        targetAudience: json['target_audience'],
        budgetXaf: json['budget_xaf'] ?? 0,
        coverArtUrl: json['cover_art_url'],
        musicFileUrl: json['music_file_url'],
        releaseDate: json['release_date'],
        promotionalMessage: json['promotional_message'],
        streamingLink: json['streaming_link'],
        snippetStart: json['snippet_start'] != null ? (json['snippet_start'] as num).toDouble() : null,
        snippetEnd: json['snippet_end'] != null ? (json['snippet_end'] as num).toDouble() : null,
        generatedCaptions: json['generated_captions'],
        generatedHashtags: json['generated_hashtags'],
        status: json['status'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      );
}
