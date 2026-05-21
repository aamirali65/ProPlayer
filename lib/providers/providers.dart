import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../services/storage_service.dart';
import '../services/media_scanner_service.dart';
import '../services/audio_player_service.dart';
import '../models/models.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final mediaScannerServiceProvider = Provider<MediaScannerService>((ref) {
  return MediaScannerService();
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(storageServiceProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;

  SettingsNotifier(this._storageService) : super(AppSettings());

  Future<void> loadSettings() async {
    state = _storageService.settings;
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    await _storageService.saveSettings(settings);
  }

  Future<void> toggleTheme(String themeMode) async {
    final updated = state.copyWith(themeMode: themeMode);
    await updateSettings(updated);
  }

  Future<void> toggleDynamicColors(bool value) async {
    final updated = state.copyWith(useDynamicColors: value);
    await updateSettings(updated);
  }
}

final mediaLibraryProvider = StateNotifierProvider<MediaLibraryNotifier, MediaLibraryState>((ref) {
  return MediaLibraryNotifier(
    ref.watch(mediaScannerServiceProvider),
    ref.watch(storageServiceProvider),
  );
});

class MediaLibraryState {
  final List<MediaItem> audioItems;
  final List<MediaItem> videoItems;
  final bool isScanning;
  final double scanProgress;
  final List<String> artists;
  final List<String> albums;
  final List<String> folders;

  const MediaLibraryState({
    this.audioItems = const [],
    this.videoItems = const [],
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.artists = const [],
    this.albums = const [],
    this.folders = const [],
  });

  MediaLibraryState copyWith({
    List<MediaItem>? audioItems,
    List<MediaItem>? videoItems,
    bool? isScanning,
    double? scanProgress,
    List<String>? artists,
    List<String>? albums,
    List<String>? folders,
  }) {
    return MediaLibraryState(
      audioItems: audioItems ?? this.audioItems,
      videoItems: videoItems ?? this.videoItems,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      folders: folders ?? this.folders,
    );
  }

  List<MediaItem> getMediaByFolder(String folder) {
    return [...audioItems, ...videoItems].where((item) => item.folder == folder).toList();
  }
}

class MediaLibraryNotifier extends StateNotifier<MediaLibraryState> {
  final MediaScannerService _scanner;
  final StorageService _storageService;

  MediaLibraryNotifier(this._scanner, this._storageService)
      : super(const MediaLibraryState());

  Future<void> scanMedia() async {
    state = state.copyWith(isScanning: true, scanProgress: 0.0);
    final settings = _storageService.settings;
    final sub = _scanner.progressStream.listen((_) => _updateState());
    await _scanner.scanMedia(excludeFolders: settings.excludedFolders);
    await sub.cancel();
    _updateState();
  }

  Future<void> refreshMedia() async {
    final settings = _storageService.settings;
    await _scanner.refreshMedia(excludeFolders: settings.excludedFolders);
    _updateState();
  }

  void _updateState() {
    state = MediaLibraryState(
      audioItems: _scanner.audioItems,
      videoItems: _scanner.videoItems,
      isScanning: _scanner.isScanning,
      scanProgress: _scanner.scanProgress,
      artists: _scanner.getUniqueArtists(),
      albums: _scanner.getUniqueAlbums(),
      folders: _scanner.getUniqueFolders(),
    );
  }

  List<MediaItem> searchMedia(String query) {
    return _scanner.searchMedia(query);
  }

  List<MediaItem> getMediaByFolder(String folder) {
    return _scanner.getMediaByFolder(folder);
  }

  List<MediaItem> getAudioByArtist(String artist) {
    return _scanner.getAudioByArtist(artist);
  }

  List<MediaItem> getAudioByAlbum(String album) {
    return _scanner.getAudioByAlbum(album);
  }
}

final audioPlayerProvider = StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier(
    ref.watch(audioPlayerServiceProvider),
    ref.watch(storageServiceProvider),
  );
});

class AudioPlayerState {
  final MediaItem? currentMedia;
  final List<MediaItem> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final bool isPlaying;
  final bool isShuffled;
  final String repeatMode;
  final double speed;
  final bool isFavorite;

  const AudioPlayerState({
    this.currentMedia,
    this.queue = const [],
    this.currentIndex = -1,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.isPlaying = false,
    this.isShuffled = false,
    this.repeatMode = 'off',
    this.speed = 1.0,
    this.isFavorite = false,
  });

  AudioPlayerState copyWith({
    MediaItem? currentMedia,
    List<MediaItem>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    bool? isPlaying,
    bool? isShuffled,
    String? repeatMode,
    double? speed,
    bool? isFavorite,
  }) {
    return AudioPlayerState(
      currentMedia: currentMedia ?? this.currentMedia,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      isPlaying: isPlaying ?? this.isPlaying,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
      speed: speed ?? this.speed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  double get progress =>
      duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayerService _service;
  final StorageService _storageService;

  AudioPlayerNotifier(this._service, this._storageService)
      : super(const AudioPlayerState()) {
    _service.positionStream.listen((position) {
      state = state.copyWith(position: position);
      _savePosition(position);
    });

    _service.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });

    _service.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _service.speedStream.listen((speed) {
      state = state.copyWith(speed: speed);
    });
  }

  Future<void> playMedia(MediaItem item, {List<MediaItem>? queue}) async {
    await _service.playMediaItem(item, queue: queue);
    state = state.copyWith(
      currentMedia: _service.currentMediaItem,
      queue: _service.queue,
      currentIndex: _service.currentIndex,
      isPlaying: true,
      isFavorite: _isFavorite(_service.currentMediaItem?.id),
    );
  }

  Future<void> playQueue(List<MediaItem> items, {int startIndex = 0}) async {
    await _service.playQueue(items, startIndex: startIndex);
    state = state.copyWith(
      currentMedia: _service.currentMediaItem,
      queue: _service.queue,
      currentIndex: _service.currentIndex,
      isPlaying: true,
      isFavorite: _isFavorite(_service.currentMediaItem?.id),
    );
  }

  Future<void> togglePlayPause() async {
    await _service.togglePlayPause();
    state = state.copyWith(isPlaying: _service.player.playing);
  }

  Future<void> next() async {
    await _service.next();
    state = state.copyWith(
      currentMedia: _service.currentMediaItem,
      currentIndex: _service.currentIndex,
      isFavorite: _isFavorite(_service.currentMediaItem?.id),
    );
  }

  Future<void> previous() async {
    await _service.previous();
    state = state.copyWith(
      currentMedia: _service.currentMediaItem,
      currentIndex: _service.currentIndex,
      isFavorite: _isFavorite(_service.currentMediaItem?.id),
    );
  }

  Future<void> seekTo(Duration position) async {
    await _service.seekTo(position);
  }

  Future<void> setSpeed(double speed) async {
    await _service.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  Future<void> toggleShuffle() async {
    final newShuffle = !state.isShuffled;
    await _service.setShuffleModeEnabled(newShuffle);
    state = state.copyWith(isShuffled: newShuffle);
  }

  Future<void> toggleRepeat() async {
    String newMode;
    LoopMode loopMode;
    switch (state.repeatMode) {
      case 'off':
        newMode = 'all';
        loopMode = LoopMode.all;
        break;
      case 'all':
        newMode = 'one';
        loopMode = LoopMode.one;
        break;
      default:
        newMode = 'off';
        loopMode = LoopMode.off;
    }
    await _service.setLoopMode(loopMode);
    state = state.copyWith(repeatMode: newMode);
  }

  Future<void> toggleFavorite() async {
    if (state.currentMedia == null) return;
    final mediaId = state.currentMedia!.id;
    final playState = _storageService.getPlayState(mediaId) ?? {};
    final newFavorite = !(playState['isFavorite'] ?? false);
    playState['isFavorite'] = newFavorite;
    playState['mediaId'] = mediaId;
    await _storageService.savePlayState(mediaId, playState);
    state = state.copyWith(isFavorite: newFavorite);
  }

  void _savePosition(Duration position) {
    if (state.currentMedia != null) {
      final playState = _storageService.getPlayState(state.currentMedia!.id) ?? {};
      playState['mediaId'] = state.currentMedia!.id;
      playState['position'] = position.inMilliseconds;
      playState['lastPlayed'] = DateTime.now().millisecondsSinceEpoch;
      playState['playCount'] = (playState['playCount'] ?? 0) + 1;
      _storageService.savePlayState(state.currentMedia!.id, playState);
    }
  }

  bool _isFavorite(String? mediaId) {
    if (mediaId == null) return false;
    final playState = _storageService.getPlayState(mediaId);
    return playState?['isFavorite'] ?? false;
  }

  Future<void> loadResumePosition() async {
    if (state.currentMedia == null) return;
    final playState = _storageService.getPlayState(state.currentMedia!.id);
    if (playState != null && playState['position'] != null) {
      await _service.seekTo(Duration(milliseconds: playState['position']));
    }
  }

  Future<void> clearQueue() async {
    _service.clearQueue();
    state = const AudioPlayerState();
  }

  Future<void> removeFromQueue(int index) async {
    await _service.removeFromQueue(index);
    state = state.copyWith(
      queue: _service.queue,
      currentIndex: _service.currentIndex,
      currentMedia: _service.currentMediaItem,
    );
  }

  Future<void> moveQueueItem(int from, int to) async {
    await _service.moveQueueItem(from, to);
    state = state.copyWith(
      queue: _service.queue,
      currentIndex: _service.currentIndex,
    );
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  return PlaylistNotifier(ref.watch(storageServiceProvider));
});

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  final StorageService _storageService;

  PlaylistNotifier(this._storageService) : super([]) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    state = _storageService.getAllPlaylists();
  }

  Future<void> createPlaylist(String name, {String? description}) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    await _storageService.addPlaylist(playlist);
    await loadPlaylists();
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await _storageService.updatePlaylist(playlist);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _storageService.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<void> addMediaToPlaylist(String playlistId, String mediaId) async {
    final playlist = _storageService.getPlaylist(playlistId);
    if (playlist != null && !playlist.mediaIds.contains(mediaId)) {
      final updated = playlist.copyWith(
        mediaIds: [...playlist.mediaIds, mediaId],
        updatedAt: DateTime.now(),
      );
      await _storageService.updatePlaylist(updated);
      await loadPlaylists();
    }
  }

  Future<void> removeMediaFromPlaylist(String playlistId, String mediaId) async {
    final playlist = _storageService.getPlaylist(playlistId);
    if (playlist != null) {
      final updated = playlist.copyWith(
        mediaIds: playlist.mediaIds.where((id) => id != mediaId).toList(),
        updatedAt: DateTime.now(),
      );
      await _storageService.updatePlaylist(updated);
      await loadPlaylists();
    }
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(mediaScannerServiceProvider));
});

class SearchState {
  final String query;
  final List<MediaItem> results;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<MediaItem>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final MediaScannerService _scanner;

  SearchNotifier(this._scanner) : super(const SearchState());

  void search(String query) {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(query: query, isSearching: true);
    final results = _scanner.searchMedia(query);
    state = state.copyWith(results: results, isSearching: false);
  }

  void clear() {
    state = const SearchState();
  }
}
