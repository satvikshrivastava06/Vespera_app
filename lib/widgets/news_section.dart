import 'package:flutter/material.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/widgets/category_section.dart';
import 'package:vespera/widgets/news_item_widget.dart';
import 'package:vespera/services/music_news_service.dart';
import 'package:vespera/models/home_feed.dart' as models;

class NewsSection extends StatefulWidget {
  final List<models.NewsItem>? news;
  
  const NewsSection({super.key, this.news});

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  final MusicNewsService _newsService = MusicNewsService();
  List<models.NewsItem> _liveNews = [];
  bool _isLoadingLive = false;

  @override
  void initState() {
    super.initState();
    _loadLiveNews();
  }

  Future<void> _loadLiveNews() async {
    if (mounted) setState(() => _isLoadingLive = true);
    try {
      final news = await _newsService.fetchLatestMusicNews();
      if (mounted) {
        setState(() {
          _liveNews = news;
          _isLoadingLive = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLive = false);
    }
  }

  Color _getBadgeColor(String category) {
    switch (category) {
      case 'TECH': return VesperaStyle.neonGreen;
      case 'ALBUM': return VesperaStyle.neonPurple;
      case 'CHART': return VesperaStyle.neonBlue;
      default: return VesperaStyle.greenTag;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Determine which list to use. Prefer live news if available.
    List<models.NewsItem> displayNews;
    
    if (_liveNews.isNotEmpty) {
      // Limit to 3 items for the home screen as requested
      displayNews = _liveNews.take(3).toList();
    } else if (widget.news != null && widget.news!.isNotEmpty) {
      displayNews = widget.news!;
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Latest Music News',
          items: displayNews.map((n) => CategoryItem(
            title: n.title,
            subtitle: n.category,
            image: n.imageUrl,
          )).toList(),
        ),
        const SizedBox(height: 20),
        
        if (_isLoadingLive && _liveNews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: VesperaStyle.accent),
            ),
          )
        else
          ...displayNews.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: NewsItemWidget(
              title: item.title,
              subtitle: item.subtitle,
              category: item.category,
              badgeColor: _getBadgeColor(item.category),
              imageUrl: item.imageUrl,
            ),
          )),
      ],
    );
  }
}
