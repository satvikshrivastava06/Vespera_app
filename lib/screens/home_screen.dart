import 'package:flutter/material.dart';
import 'package:vespera/widgets/custom_header.dart';
import 'package:vespera/widgets/ranking_section.dart';
import 'package:vespera/widgets/category_section.dart';
import 'package:vespera/widgets/bulged_category_section.dart';
import 'package:vespera/widgets/twilight_banner.dart';
import 'package:vespera/widgets/news_section.dart';
import 'package:vespera/widgets/custom_bottom_nav.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/widgets/custom_drawer.dart';

import 'package:vespera/models/catalog_track.dart';
import 'package:vespera/models/home_feed.dart';
import 'package:vespera/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  HomeFeedResponse? _homeData;
  List<CatalogTrack> _catalog = const [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    HomeFeedResponse? feed;
    List<CatalogTrack> catalog = const [];
    Object? feedError;
    try {
      feed = await _apiService.fetchHomeFeed(activityBpm: 70);
    } catch (e) {
      feedError = e;
    }
    try {
      catalog = await _apiService.fetchCatalog();
    } catch (_) {
      catalog = const [];
    }
    if (!mounted) return;
    setState(() {
      _homeData = feed;
      _catalog = catalog;
    });
    if (feedError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedError.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesperaStyle.background,
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CustomHeader(greeting: _homeData?.greeting),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI DJ Message Banner (New subtle addition to show the AI is working)
                    if (_homeData != null && _homeData!.aiMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: NeumorphicContainer(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          borderRadius: 20,
                          backgroundColor: Colors.white.withAlpha(150),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: VesperaStyle.accent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _homeData!.aiMessage,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: VesperaStyle.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_catalog.isNotEmpty) ...[
                      CategorySection(
                        title: 'Rights-cleared catalog',
                        style: CategoryStyle.standard,
                        cardWidth: 140,
                        cardHeight: 220,
                        items: _catalog
                            .map(
                              (track) => CategoryItem(
                                title: track.title,
                                subtitle: track.artist,
                                image: track.imageUrl ?? '',
                                audioId: track.id,
                                streamUrl: track.audioUrl ?? '',
                                jamendoShareUrl: track.jamendoShareUrl,
                                playableMs: track.playableMs,
                                sessionEligible: track.sessionEligible,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 35),
                    ],

                    // 1. Monthly Ranking
                    RankingSection(rankings: _homeData?.rankings),
                    const SizedBox(height: 35),
                    
                    // 2. Popular Playlist (Inset type)
                    CategorySection(
                      title: 'Popular Playlist',
                      style: CategoryStyle.insetImage,
                      cardWidth: 160,
                      cardHeight: 220,
                      items: _homeData?.popularPlaylists.map((item) => CategoryItem(
                        title: item.title,
                        subtitle: item.subtitle,
                        image: item.imageUrl,
                        audioId: item.audioId,
                        searchQuery: item.searchQuery,
                      )).toList(),
                    ),
                    const SizedBox(height: 35),
                    
                    // 3. Jump back in
                    BulgedCategorySection(
                      title: 'Jump back in',
                      items: _homeData?.jumpBackIn.map((item) => BulgedCategoryItem(
                        title: item.title,
                        subtitle: item.subtitle,
                        image: item.imageUrl,
                        audioId: item.audioId,
                        searchQuery: item.searchQuery,
                      )).toList(),
                    ),
                    const SizedBox(height: 35),
                    
                    // 4. Quick picks for you!
                    CategorySection(
                      title: 'Quick picks for you!',
                      style: CategoryStyle.standard,
                      cardWidth: 140,
                      cardHeight: 220,
                      items: _homeData?.quickPicks.map((item) => CategoryItem(
                        title: item.title,
                        subtitle: item.subtitle,
                        image: item.imageUrl,
                        audioId: item.audioId,
                        searchQuery: item.searchQuery,
                      )).toList(),
                    ),
                    const SizedBox(height: 35),
                    
                    // 5. Trending Now
                    BulgedCategorySection(
                      title: 'Trending Now',
                      items: _homeData?.trendingNow.map((item) => BulgedCategoryItem(
                        title: item.title,
                        subtitle: item.subtitle,
                        image: item.imageUrl,
                        audioId: item.audioId,
                        searchQuery: item.searchQuery,
                      )).toList(),
                    ),
                    const SizedBox(height: 35),
                    
                    // 6. Twilight
                    const TwilightBanner(),
                    const SizedBox(height: 35),

                    // 7. New releases
                    CategorySection(
                      title: 'New releases',
                      style: CategoryStyle.standard, // Changed to standard to actually show the content
                      cardWidth: 160,
                      cardHeight: 220,
                      items: _homeData?.newReleases.map((item) => CategoryItem(
                        title: item.title,
                        subtitle: item.subtitle,
                        image: item.imageUrl,
                        audioId: item.audioId,
                        searchQuery: item.searchQuery,
                      )).toList(),
                    ),
                    const SizedBox(height: 35),
                    
                    // 8. Latest Music News
                    NewsSection(news: _homeData?.news),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
