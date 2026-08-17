import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vespera/models/home_feed.dart';

class MusicNewsService {
  static const String rssUrl = 'https://billboard.com/feed';
  static const String jsonApiUrl = 'https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fbillboard.com%2Ffeed';

  Future<List<NewsItem>> fetchLatestMusicNews() async {
    try {
      final response = await http.get(Uri.parse(jsonApiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          final List items = data['items'];
          
          // Create news items processing them in parallel for any missing images
          final List<Future<NewsItem>> itemFutures = items.map((item) async {
            String link = item['link'] ?? '';
            // Using a high-quality, extremely reliable music placeholder
            String imageUrl = 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&q=80';
            
            print('Processing news item: ${item['title']} - link: $link');
            // 1. Try standard RSS fields
            if (item['thumbnail'] != null && item['thumbnail'].toString().isNotEmpty) {
              imageUrl = item['thumbnail'];
            } else if (item['enclosure'] != null && item['enclosure']['link'] != null) {
              imageUrl = item['enclosure']['link'];
            } else if (item['description'] != null && item['description'].contains('<img')) {
              final match = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(item['description']);
              if (match != null) imageUrl = match.group(1)!;
            }

            // 2. "Direct System": If image is still default or we want the high-res one from the source
            // We'll attempt to fetch the actual website meta tags for a more "Related" and high-quality image
            if (imageUrl.contains('unsplash.com') && link.isNotEmpty) {
              try {
                final webImage = await _fetchOGImage(link);
                if (webImage != null) imageUrl = webImage;
              } catch (e) {
                // Silently fail and use what we have
              }
            }

            print('Final imageUrl for ${item['title']}: $imageUrl');

            return NewsItem(
              title: item['title'] ?? 'Music News',
              subtitle: _stripHtml(item['description'] ?? 'Read more about this story...'),
              category: _getCategory(item['categories'] ?? []),
              imageUrl: imageUrl,
            );
          }).toList();

          return await Future.wait(itemFutures);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching music news: $e');
      return [];
    }
  }

  /// Automatically fetches the og:image or related image from the direct news website
  Future<String?> _fetchOGImage(String url) async {
    try {
      // Use a short timeout to not block the UI for too long
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = response.body;
        
        // Look for OpenGraph image tag
        // <meta property="og:image" content="..." />
        final ogMatch = RegExp(r'<meta[^>]+property="og:image"[^>]+content="([^">]+)"').firstMatch(body);
        if (ogMatch != null) return ogMatch.group(1);

        // Fallback to twitter image
        final twitterMatch = RegExp(r'<meta[^>]+name="twitter:image"[^>]+content="([^">]+)"').firstMatch(body);
        if (twitterMatch != null) return twitterMatch.group(1);

        // Fallback to primary article image tag
        final altMatch = RegExp(r'<link[^>]+rel="image_src"[^>]+href="([^">]+)"').firstMatch(body);
        if (altMatch != null) return altMatch.group(1);
      }
    } catch (e) {
      // Error in direct fetching
    }
    return null;
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  String _getCategory(List categories) {
    if (categories.isEmpty) return 'MUSIC';
    return categories.first.toString().toUpperCase();
  }
}
