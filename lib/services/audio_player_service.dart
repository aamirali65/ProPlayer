import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import '../models/models.dart' as app_models;
import '../core/utils/logger.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  late AudioPlayer _player;
  audio_service.BaseAudioHandler? _audioHandler;
  List<app_models.MediaItem> _queue = [];
  int _currentIndex = -1;

  AudioPlayer get player => _player;
  List<app_models.MediaItem> get queue => _queue;
  int get currentIndex => _currentIndex;
  app_models.MediaItem? get currentMediaItem =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  Future<void> init() async {
    _player = AudioPlayer();

    _player.processingStateStream.listen((state) {
      AppLogger.debug('Audio processing state: $state');
    });

    _player.playerStateStream.listen((state) {
      AppLogger.debug('Player state: playing=${state.playing}');
    });
  }

  Future<void> initAudioService() async {
    try {
      final handler = await audio_service.AudioService.init(
        builder: () => AudioHandlerImpl(_player, this),
        config: const audio_service.AudioServiceConfig(
          androidNotificationChannelId: 'com.proplayer.audio',
          androidNotificationChannelName: 'ProPlayer',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      );
      _audioHandler = handler as audio_service.BaseAudioHandler;
    } catch (e) {
      AppLogger.warning('Audio service init failed (background playback may not work): $e');
      _audioHandler = null;
    }
  }

  Future<void> playMediaItem(app_models.MediaItem item, {List<app_models.MediaItem>? queue}) async {
    if (queue != null) {
      _queue = List.from(queue);
      _currentIndex = _queue.indexWhere((m) => m.id == item.id);
    } else if (!_queue.any((m) => m.id == item.id)) {
      _queue.add(item);
      _currentIndex = _queue.length - 1;
    } else {
      _currentIndex = _queue.indexWhere((m) => m.id == item.id);
    }

    await _setSource(item);
    await _player.play();
    _updateNotification();
  }

  Future<void> playQueue(List<app_models.MediaItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;
    _queue = List.from(items);
    _currentIndex = startIndex.clamp(0, items.length - 1);
    await _setSource(_queue[_currentIndex]);
    await _player.play();
    _updateNotification();
  }

  Future<void> play() async {
    await _player.play();
    _updateNotification();
  }

  Future<void> pause() async {
    await _player.pause();
    _updateNotification();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _setSource(_queue[_currentIndex]);
      await _player.play();
      _updateNotification();
    }
  }

  Future<void> previous() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await _setSource(_queue[_currentIndex]);
      await _player.play();
      _updateNotification();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> addToQueue(app_models.MediaItem item) async {
    _queue.add(item);
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        if (_queue.isNotEmpty) {
          _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
          await _setSource(_queue[_currentIndex]);
        }
      }
    }
  }

  Future<void> moveQueueItem(int from, int to) async {
    if (from >= 0 && from < _queue.length && to >= 0 && to < _queue.length) {
      final item = _queue.removeAt(from);
      _queue.insert(to, item);
      if (from == _currentIndex) {
        _currentIndex = to;
      } else if (from < _currentIndex && to >= _currentIndex) {
        _currentIndex--;
      } else if (from > _currentIndex && to <= _currentIndex) {
        _currentIndex++;
      }
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
  }

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Duration get bufferedPosition => _player.bufferedPosition;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get speedStream => _player.speedStream;

  Future<void> _setSource(app_models.MediaItem item) async {
    try {
      await _player.setFilePath(item.path);
    } catch (e) {
      AppLogger.error('Failed to set audio source', e);
    }
  }

  void _updateNotification() {
    if (currentMediaItem != null && _audioHandler != null) {
      final item = currentMediaItem!;
      _audioHandler!.mediaItem.add(audio_service.MediaItem(
        id: item.id,
        title: item.title,
        artist: item.artist,
        artUri: item.albumArt != null ? Uri.tryParse(item.albumArt!) : null,
        duration: Duration(milliseconds: item.duration),
      ));
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _audioHandler?.stop();
  }
}

class AudioHandlerImpl extends audio_service.BaseAudioHandler {
  final AudioPlayer _player;
  final AudioPlayerService _service;

  AudioHandlerImpl(this._player, this._service) {
    _player.playingStream.listen((playing) {
      playbackState.add(playbackState.value.copyWith(
        playing: playing,
        controls: [
          audio_service.MediaControl.skipToPrevious,
          if (playing) audio_service.MediaControl.pause else audio_service.MediaControl.play,
          audio_service.MediaControl.skipToNext,
          audio_service.MediaControl.stop,
        ],
        systemActions: const {
          audio_service.MediaAction.seek,
          audio_service.MediaAction.seekForward,
          audio_service.MediaAction.seekBackward,
        },
        processingState: const {
          ProcessingState.idle: audio_service.AudioProcessingState.idle,
          ProcessingState.loading: audio_service.AudioProcessingState.loading,
          ProcessingState.buffering: audio_service.AudioProcessingState.buffering,
          ProcessingState.ready: audio_service.AudioProcessingState.ready,
          ProcessingState.completed: audio_service.AudioProcessingState.completed,
        }[_player.processingState]!,
        updatePosition: _player.position,
      ));
    });

    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _service.clearQueue();
    mediaItem.add(null);
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seek(
        Duration(seconds: _player.position.inSeconds + 10),
      );

  @override
  Future<void> skipToPrevious() => _player.seek(
        Duration(seconds: _player.position.inSeconds - 10),
      );

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
