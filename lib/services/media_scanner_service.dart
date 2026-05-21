import 'dart:async';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import '../core/utils/logger.dart';

class MediaScannerService {
  static final MediaScannerService _instance = MediaScannerService._internal();
  factory MediaScannerService() => _instance;
  MediaScannerService._internal();

  final OnAudioQuery _audioQuery = OnAudioQuery();
  OnAudioQuery get audioQuery => _audioQuery;
  List<MediaItem> _audioItems = [];
  List<MediaItem> _videoItems = [];
  bool _isScanning = false;
  double _scanProgress = 0.0;
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  List<MediaItem> get audioItems => _audioItems;
  List<MediaItem> get videoItems => _videoItems;
  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;

  Future<void> scanMedia({List<String>? excludeFolders}) async {
    if (_isScanning) return;
    _isScanning = true;
    _scanProgress = 0.0;

    try {
      _scanProgress = 0.1;
      _progressController.add(_scanProgress);
      final audioSongs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      _scanProgress = 0.4;
      _progressController.add(_scanProgress);
      _audioItems = audioSongs
          .where((song) => !_isExcluded(song.data, excludeFolders))
          .map((song) => MediaItem(
                id: song.id.toString(),
                title: song.title,
                artist: song.artist ?? 'Unknown Artist',
                album: song.album ?? 'Unknown Album',
                path: song.data,
                duration: song.duration ?? 0,
                size: song.size ?? 0,
                dateAdded: DateTime.fromMillisecondsSinceEpoch(song.dateAdded ?? 0),
                dateModified: DateTime.fromMillisecondsSinceEpoch(song.dateModified ?? 0),
                albumArt: song.id.toString(),
                isAudio: true,
                folder: p.dirname(song.data),
                trackNumber: song.track,
              ))
          .toList();
      _progressController.add(_scanProgress);

      _scanProgress = 0.6;
      _progressController.add(_scanProgress);
      await _scanVideos(excludeFolders);

      _scanProgress = 1.0;
      _progressController.add(_scanProgress);
      AppLogger.info('Scan complete: ${_audioItems.length} audio, ${_videoItems.length} video');
    } catch (e) {
      AppLogger.error('Media scan failed', e);
    } finally {
      _isScanning = false;
    }
  }

  Future<void> refreshMedia({List<String>? excludeFolders}) async {
    await scanMedia(excludeFolders: excludeFolders);
  }

  Future<void> _scanVideos(List<String>? excludeFolders) async {
    const channel = MethodChannel('com.proplayer.app/video_scanner');
    try {
      final result = await channel.invokeMethod<List<dynamic>>('queryVideos');
      if (result == null) {
        AppLogger.warning('Video query returned null');
        _videoItems = [];
        return;
      }

      final allExcludes = [
        ...?excludeFolders,
        'Android',
        'obb',
        'cache',
        'tmp',
        '.thumbnails',
        'LOST.DIR',
        'System',
      ];

      final videoFiles = <MediaItem>[];
      for (final entry in result) {
        final map = entry as Map<dynamic, dynamic>;
        final path = map['path'] as String? ?? '';
        if (path.isEmpty) continue;

        final lowerPath = path.toLowerCase();
        if (allExcludes.any((e) => lowerPath.contains('/${e.toLowerCase()}/'))) continue;

        final durationMs = map['duration'] as int? ?? 0;
        final dateModifiedMs = map['dateModified'] as int? ?? 0;
        final dateAddedMs = map['dateAdded'] as int? ?? 0;

        videoFiles.add(MediaItem(
          id: map['id'] as String? ?? path.hashCode.toString(),
          title: map['title'] as String? ?? p.basenameWithoutExtension(path),
          path: path,
          duration: durationMs,
          size: map['size'] as int? ?? 0,
          dateModified: DateTime.fromMillisecondsSinceEpoch(dateModifiedMs),
          dateAdded: DateTime.fromMillisecondsSinceEpoch(dateAddedMs),
          isAudio: false,
          folder: p.dirname(path),
        ));
      }

      videoFiles.sort((a, b) => b.dateModified.compareTo(a.dateModified));
      _videoItems = videoFiles.take(500).toList();
    } catch (e) {
      AppLogger.warning('Platform video query failed: $e');
      _videoItems = [];
    }
  }

  bool _isExcluded(String filePath, List<String>? excludeFolders) {
    if (excludeFolders == null || excludeFolders.isEmpty) return false;
    final lowerPath = filePath.toLowerCase();
    return excludeFolders.any((folder) => lowerPath.contains('/${folder.toLowerCase()}/'));
  }

  List<MediaItem> searchMedia(String query) {
    final lowerQuery = query.toLowerCase();
    return [
      ..._audioItems,
      ..._videoItems,
    ].where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.artist.toLowerCase().contains(lowerQuery) ||
          item.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<String> getUniqueFolders() {
    final folders = <String>{};
    for (final item in [..._audioItems, ..._videoItems]) {
      if (item.folder != null) folders.add(item.folder!);
    }
    return folders.toList()..sort();
  }

  List<MediaItem> getMediaByFolder(String folderPath) {
    return [..._audioItems, ..._videoItems]
        .where((item) => item.folder == folderPath)
        .toList();
  }

  List<MediaItem> getAudioByArtist(String artist) {
    return _audioItems.where((item) => item.artist == artist).toList();
  }

  List<MediaItem> getAudioByAlbum(String album) {
    return _audioItems.where((item) => item.album == album).toList();
  }

  List<String> getUniqueArtists() {
    return _audioItems.map((item) => item.artist).toSet().toList()..sort();
  }

  List<String> getUniqueAlbums() {
    return _audioItems.map((item) => item.album).toSet().toList()..sort();
  }
}
