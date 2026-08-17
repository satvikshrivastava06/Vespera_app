import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/widgets/category_section.dart';
import 'package:vespera/widgets/bulged_card.dart';
import 'package:vespera/widgets/news_item_widget.dart';
import 'package:vespera/services/music_news_service.dart';
import 'package:vespera/models/home_feed.dart' as models;

class ViewAllScreen extends StatefulWidget {
  final String title;
  final List<CategoryItem> items;

  const ViewAllScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  final MusicNewsService _newsService = MusicNewsService();
  List<models.NewsItem> _liveNews = [];
  bool _isLoadingNews = false;

  bool get _isNewsSection => widget.title.toLowerCase().contains('news');

  @override
  void initState() {
    super.initState();
    if (_isNewsSection) {
      _fetchNews();
    }
  }

  Future<void> _fetchNews() async {
    setState(() => _isLoadingNews = true);
    try {
      final news = await _newsService.fetchLatestMusicNews();
      if (mounted) {
        setState(() {
          _liveNews = news;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesperaStyle.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isNewsSection ? _buildNewsContent() : _buildGridContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsContent() {
    if (_isLoadingNews) {
      return const Center(child: CircularProgressIndicator(color: VesperaStyle.neonPurple));
    }

    final itemsToDisplay = _liveNews.isNotEmpty ? _liveNews : widget.items.map((e) => models.NewsItem(
      title: e.title,
      subtitle: e.subtitle ?? '',
      category: 'MUSIC',
      imageUrl: e.image,
    )).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: itemsToDisplay.length,
      itemBuilder: (context, index) {
        final item = itemsToDisplay[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: NewsItemWidget(
            title: item.title,
            subtitle: item.subtitle,
            category: item.category,
            badgeColor: _getBadgeColor(item.category),
            imageUrl: item.imageUrl,
          ),
        );
      },
    );
  }

  Color _getBadgeColor(String category) {
    switch (category.toUpperCase()) {
      case 'TECH': return VesperaStyle.neonGreen;
      case 'EVENT': return VesperaStyle.greenTag;
      case 'ALBUM': return VesperaStyle.neonPurple;
      case 'CHART': return const Color(0xFFFFD700);
      default: return VesperaStyle.neonBlue;
    }
  }

  Widget _buildGridContent() {
    final List<CategoryItem> displayItems = widget.items.length >= 5 
        ? widget.items 
        : List.generate(10, (i) => i < widget.items.length ? widget.items[i] : CategoryItem(
            title: 'Playlist ${i+1}', 
            subtitle: '80 Songs', 
            image: 'https://picsum.photos/seed/viewall$i/400/400'
          ));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 20)),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 30,
              crossAxisSpacing: 25,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= 2) return null;
                return BulgedCard(item: displayItems[index]);
              },
              childCount: 2,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),

        if (displayItems.length > 2)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BulgedCard(
                item: displayItems[2],
                isHorizontal: true,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 50)),

        if (displayItems.length > 3)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 40,
                crossAxisSpacing: 25,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actualIndex = index + 3;
                  if (actualIndex >= displayItems.length) return null;
                  return BulgedCard(item: displayItems[actualIndex]);
                },
                childCount: displayItems.length - 3,
              ),
            ),
          ),
        
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            context,
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: VesperaStyle.textPrimary,
            ),
          ),
          _buildCircleButton(
            context,
            icon: Icons.more_horiz_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        width: 45,
        height: 45,
        borderRadius: 100,
        child: Icon(icon, size: 18, color: VesperaStyle.textPrimary),
      ),
    );
  }
}
