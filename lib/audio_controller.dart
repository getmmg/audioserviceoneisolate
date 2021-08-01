import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:oneisolatebeta/audiohandler.dart';
import 'package:oneisolatebeta/log/simple_log_printer.dart';

class AudioController extends GetxController {
  late AudioHandler audioHandler;
  final Logger _logger = getLogger('NowPlayingController');
  MediaItem? nowPlaying;
  RxString nowPlayingTitle = "...".obs;
  RxBool isPlaying = false.obs;
  RxBool queueLoaded = false.obs;

  @override
  void onInit() async {
    _logger.v("onInit");
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    audioHandler.mediaItem.listen((MediaItem? mediaItem) async {
      if (mediaItem != null) {
        nowPlaying = mediaItem;
        nowPlayingTitle.value = mediaItem.title;
      }
    });

    audioHandler.playbackState.listen((state) {
      isPlaying.value = state.playing;
    });
    super.onInit();
  }

  void playRadioStation(MediaItem mediaItem, List<MediaItem> queue) async {
    _logger.v("Playing ${mediaItem.title}");
    await audioHandler.addQueueItems(queue);
    queueLoaded.value = true;
    await play(mediaItem);
  }

  bool hasNext() => audioHandler.queue.value.length > 1;
  bool hasPrevious() => audioHandler.queue.value.length > 1;

  Future play(MediaItem mediaItem) async =>
      await audioHandler.playMediaItem(mediaItem);

  Future<void> previous() async {
    await audioHandler.skipToPrevious();
  }

  Future<void> next() async {
    await audioHandler.skipToNext();
  }

  Future<void> resume() async => await play(nowPlaying!);

  Future<void> pause() async => await audioHandler.pause();

  Future<void> stop() async => await audioHandler.stop();

  @override
  void dispose() {
    super.dispose();
  }
}
