class MediaItem {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int duration;
  final int size;
  final DateTime dateAdded;
  final DateTime dateModified;
  final String? albumArt;
  final bool isAudio;
  final String? folder;
  final int? trackNumber;
  final int? year;
  final String? genre;

  MediaItem({
    required this.id,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    required this.path,
    this.duration = 0,
    this.size = 0,
    DateTime? dateAdded,
    DateTime? dateModified,
    this.albumArt,
    this.isAudio = true,
    this.folder,
    this.trackNumber,
    this.year,
    this.genre,
  })  : dateAdded = dateAdded ?? DateTime.now(),
        dateModified = dateModified ?? DateTime.now();

  MediaItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? path,
    int? duration,
    int? size,
    DateTime? dateAdded,
    DateTime? dateModified,
    String? albumArt,
    bool? isAudio,
    String? folder,
    int? trackNumber,
    int? year,
    String? genre,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      albumArt: albumArt ?? this.albumArt,
      isAudio: isAudio ?? this.isAudio,
      folder: folder ?? this.folder,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String? description;
  final List<String> mediaIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverArt;
  final bool isSmart;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    List<String>? mediaIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.coverArt,
    this.isSmart = false,
  })  : mediaIds = mediaIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? mediaIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverArt,
    bool? isSmart,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mediaIds: mediaIds ?? this.mediaIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverArt: coverArt ?? this.coverArt,
      isSmart: isSmart ?? this.isSmart,
    );
  }

  int get itemCount => mediaIds.length;
}

class PlayState {
  final String mediaId;
  final int position;
  final DateTime lastPlayed;
  final int playCount;
  final bool isFavorite;

  PlayState({
    required this.mediaId,
    this.position = 0,
    DateTime? lastPlayed,
    this.playCount = 0,
    this.isFavorite = false,
  }) : lastPlayed = lastPlayed ?? DateTime.now();

  PlayState copyWith({
    String? mediaId,
    int? position,
    DateTime? lastPlayed,
    int? playCount,
    bool? isFavorite,
  }) {
    return PlayState(
      mediaId: mediaId ?? this.mediaId,
      position: position ?? this.position,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playCount: playCount ?? this.playCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class AppSettings {
  final String themeMode;
  final String accentColor;
  final bool useDynamicColors;
  final bool gaplessPlayback;
  final bool shuffleEnabled;
  final String repeatMode;
  final double playbackSpeed;
  final bool hardwareAcceleration;
  final List<String> excludedFolders;
  final bool autoRotate;
  final bool pipMode;
  final String videoFitMode;
  final bool gestureControls;
  final int sleepTimerMinutes;
  final bool resumePlayback;
  final bool showLyrics;
  final String equalizerPreset;
  final int bassBoost;
  final bool backgroundPlayback;

  AppSettings({
    this.themeMode = 'dark',
    this.accentColor = 'cyan',
    this.useDynamicColors = false,
    this.gaplessPlayback = true,
    this.shuffleEnabled = false,
    this.repeatMode = 'off',
    this.playbackSpeed = 1.0,
    this.hardwareAcceleration = true,
    List<String>? excludedFolders,
    this.autoRotate = true,
    this.pipMode = true,
    this.videoFitMode = 'fit',
    this.gestureControls = true,
    this.sleepTimerMinutes = 0,
    this.resumePlayback = true,
    this.showLyrics = false,
    this.equalizerPreset = 'normal',
    this.bassBoost = 0,
    this.backgroundPlayback = true,
  }) : excludedFolders = excludedFolders ?? [];

  AppSettings copyWith({
    String? themeMode,
    String? accentColor,
    bool? useDynamicColors,
    bool? gaplessPlayback,
    bool? shuffleEnabled,
    String? repeatMode,
    double? playbackSpeed,
    bool? hardwareAcceleration,
    List<String>? excludedFolders,
    bool? autoRotate,
    bool? pipMode,
    String? videoFitMode,
    bool? gestureControls,
    int? sleepTimerMinutes,
    bool? resumePlayback,
    bool? showLyrics,
    String? equalizerPreset,
    int? bassBoost,
    bool? backgroundPlayback,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      autoRotate: autoRotate ?? this.autoRotate,
      pipMode: pipMode ?? this.pipMode,
      videoFitMode: videoFitMode ?? this.videoFitMode,
      gestureControls: gestureControls ?? this.gestureControls,
      sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
      resumePlayback: resumePlayback ?? this.resumePlayback,
      showLyrics: showLyrics ?? this.showLyrics,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      bassBoost: bassBoost ?? this.bassBoost,
      backgroundPlayback: backgroundPlayback ?? this.backgroundPlayback,
    );
  }
}
