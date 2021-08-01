import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:oneisolatebeta/log/simple_log_printer.dart';


class AudioPlayerHandler extends BaseAudioHandler with QueueHandler {
  Logger logger = getLogger('AudioPlayerHandler');
  late AudioPlayer _player = AudioPlayer();

  List<MediaItem> get mediaQueue => queue.value;
  int _queueIndex = -1;
  bool _playbackInterrupted = false;

  AudioPlayerHandler() {
    _configureAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    //# Playback
    _player.playbackEventStream.listen((PlaybackEvent event) {
      _broadcastState(event);
    }, onError: (Object e, StackTrace stackTrace) {
      logger.e(e);
      logger.e("Playback stream error");
      _broadcastState(_player.playbackEvent);
    });

   
  }

  Future<void> _broadcastState(PlaybackEvent event) async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
        ],
        // systemActions: const {
        //   MediaAction.seek,
        // },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _getProcessingState(),
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return _playbackInterrupted
            ? AudioProcessingState.error
            : AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }

  // void printQueue(List<MediaItem> queue) {
  //   for (int i = 0; i < queue.length; i++) {
  //     logger.v("$i : ${queue[i].title}");
  //   }
  // }


  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    logger.d("addQueueItems");
    try {
      //mediaQueue = mediaItems;
      //queue.value = mediaItems;
      queue.add(mediaItems);
      logger.d("Queue length is " + queue.value.length.toString());
    } catch (e) {
      logger.e(e.toString());
    }
  }

  @override
  Future<void> skipToNext() => _skip(1);

  @override
  Future<void> skipToPrevious() => _skip(-1);

  Future<void> _skip(int offset) async {
    int newPos = _queueIndex + offset;
    if (newPos < 0) {
      newPos = mediaQueue.length - 1;
    } else if (newPos >= mediaQueue.length) {
      newPos = 0;
    }
    _playMedia(newPos);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere(
        (state) => state.processingState == AudioProcessingState.idle);
  }

  // @override
  // Future<void> stop() => _player.stop();

  Future<void> _playMedia(int newPos, {bool retry = false}) async {
    _queueIndex = newPos;
    MediaItem currentMediaItem = mediaQueue[_queueIndex];
    mediaItem.add(currentMediaItem);
    logger
        .v("$retry value will determine header for ${currentMediaItem.title}");


    logger.d(currentMediaItem.id);
    _player
        .setUrl(currentMediaItem.id)
        .then((value) async {
      // Resume playback if we were playing
      await play();
      //_setState(processingState: AudioProcessingState.ready);
    }).catchError((e) async {
      _broadcastState(_player.playbackEvent);
      logger.e("_playMedia : $e");
    });
  }



  @override
  Future<void> play() async {
    logger.v("onPlay ${queue.length}");
    try {
      await _player.play();
    } catch (e) {
      logger.e("onPlay : $e");
    }
  }

  @override
  Future<void> pause() async {
    logger.v("onPause");
    try {
      //await _setState(processingState: AudioProcessingState.ready);
      await _player.pause();
    } catch (e) {
      logger.e("onPause : $e");
    }
  }

  @override
  Future<void> playMediaItem(MediaItem thisMediaItem) async {
    logger.v('onPlayMediaItem');
    int queueIndex = getMediaIndex(thisMediaItem.id);
    logger.v("$queueIndex is the index for ${thisMediaItem.title}");
    _playMedia(queueIndex);
  }

  int getMediaIndex(String mediaId) {
    try {
      for (int i = 0; i < mediaQueue.length; i++) {
        MediaItem mediaItemInQueue = mediaQueue[i];
        if (mediaItemInQueue.id == mediaId) {
          return i;
        }
      }
      return -1;
    } catch (e) {
      logger.e(e.toString());
      return -1;
    }
  }


}