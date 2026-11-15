import 'package:vespera/models/playable_track.dart';
import 'package:vespera/services/audio_service.dart';
import 'package:vespera/widgets/category_section.dart';

Future<bool> playCategoryItem(CategoryItem item) {
  final audio = AudioPlayerService();
  if (item.sessionEligible && item.streamUrl.isNotEmpty) {
    return audio.playTrack(
      PlayableTrack(
        id: item.audioId.isNotEmpty ? item.audioId : item.title,
        title: item.title,
        artist: item.subtitle ?? '',
        audioUrl: item.streamUrl,
        imageUrl: item.image,
        jamendoShareUrl: item.jamendoShareUrl,
        playableMs: item.playableMs,
        sessionEligible: true,
      ),
    );
  }
  if (item.searchQuery.isNotEmpty) {
    return audio.playFromSearch(item.searchQuery, item.title);
  }
  return audio.playSong(item.audioId, item.title);
}
