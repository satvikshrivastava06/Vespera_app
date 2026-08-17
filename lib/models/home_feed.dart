class PlaylistItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String audioId;
  final String searchQuery;

  PlaylistItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.audioId,
    this.searchQuery = '',
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      audioId: json['audio_id'] ?? '',
      searchQuery: json['search_query'] ?? '',
    );
  }
}

class UserRanking {
  final String name;
  final int rank;
  final String imageUrl;

  UserRanking({
    required this.name,
    required this.rank,
    required this.imageUrl,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      name: json['name'] ?? '',
      rank: json['rank'] ?? 0,
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class NewsItem {
  final String category;
  final String title;
  final String subtitle;
  final String imageUrl;

  NewsItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class ExploreFeedResponse {
  final List<PlaylistItem> trendingEvents;
  final List<PlaylistItem> personalizedMixes;
  final List<String> categories;

  ExploreFeedResponse({
    required this.trendingEvents,
    required this.personalizedMixes,
    required this.categories,
  });

  factory ExploreFeedResponse.fromJson(Map<String, dynamic> json) {
    return ExploreFeedResponse(
      trendingEvents: (json['trending_events'] as List)
          .map((i) => PlaylistItem.fromJson(i))
          .toList(),
      personalizedMixes: (json['personalized_mixes'] as List)
          .map((i) => PlaylistItem.fromJson(i))
          .toList(),
      categories: List<String>.from(json['categories']),
    );
  }
}

class HomeFeedResponse {
// ... (rest of class remains)
  final String greeting;
  final String aiMessage;
  final List<UserRanking> rankings;
  final List<PlaylistItem> popularPlaylists;
  final List<PlaylistItem> jumpBackIn;
  final List<PlaylistItem> quickPicks;
  final List<PlaylistItem> trendingNow;
  final List<PlaylistItem> newReleases;
  final List<NewsItem> news;

  HomeFeedResponse({
    required this.greeting,
    required this.aiMessage,
    required this.rankings,
    required this.popularPlaylists,
    required this.jumpBackIn,
    required this.quickPicks,
    required this.trendingNow,
    required this.newReleases,
    required this.news,
  });

  factory HomeFeedResponse.fromJson(Map<String, dynamic> json) {
    return HomeFeedResponse(
      greeting: json['greeting'] ?? '',
      aiMessage: json['ai_message'] ?? '',
      rankings: (json['rankings'] as List?)
              ?.map((e) => UserRanking.fromJson(e))
              .toList() ??
          [],
      popularPlaylists: (json['popular_playlists'] as List?)
              ?.map((e) => PlaylistItem.fromJson(e))
              .toList() ??
          [],
      jumpBackIn: (json['jump_back_in'] as List?)
              ?.map((e) => PlaylistItem.fromJson(e))
              .toList() ??
          [],
      quickPicks: (json['quick_picks'] as List?)
              ?.map((e) => PlaylistItem.fromJson(e))
              .toList() ??
          [],
      trendingNow: (json['trending_now'] as List?)
              ?.map((e) => PlaylistItem.fromJson(e))
              .toList() ??
          [],
      newReleases: (json['new_releases'] as List?)
              ?.map((e) => PlaylistItem.fromJson(e))
              .toList() ??
          [],
      news: (json['news'] as List?)
              ?.map((e) => NewsItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
