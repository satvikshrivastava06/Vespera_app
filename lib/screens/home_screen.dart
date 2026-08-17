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

import 'package:vespera/models/home_feed.dart';
import 'package:vespera/services/api_service.dart';
import 'package:vespera/services/music_service.dart';
import 'package:vespera/services/ai_voice_service.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final MusicService _musicService = MusicService();
  final AiVoiceService _aiVoiceService = AiVoiceService();

  HomeFeedResponse? _homeData;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    // Note: We don't block the screen with _isLoading anymore to ensure fallbacks are always visible.
    try {
      String locationString = "Bhopal, India";
      try {
        // Location check with 3s timeout
        Position position = await _determinePosition().timeout(const Duration(seconds: 3));
        locationString = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      } catch (e) {
        print("Location error or timeout (using fallback): $e");
      }

      final data = await _apiService.fetchHomeFeed(
        location: locationString,
        activityBpm: 70,
      );

      if (mounted) {
        setState(() {
          _homeData = data;
        });
        
        // AI Voice Activation
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _homeData != null && _homeData!.aiMessage.isNotEmpty) {
            _aiVoiceService.speak(_homeData!.aiMessage);
          }
        });
      }
    } catch (e) {
      print("Error loading home data: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _musicService.dispose();
    _aiVoiceService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: We no longer block the whole screen with _isLoading.
    // This ensures fallbacks are visible immediately.

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
