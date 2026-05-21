import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box _playStateBox;
  late Box _playlistBox;
  late SharedPreferences _prefs;

  AppSettings _settings = AppSettings();

  Future<void> init() async {
    await Hive.initFlutter();
    _playStateBox = await Hive.openBox(AppConstants.hiveBoxPlayHistory);
    _playlistBox = await Hive.openBox(AppConstants.hiveBoxPlaylists);
    _prefs = await SharedPreferences.getInstance();
    
    _loadSettings();
  }

  void _loadSettings() {
    _settings = AppSettings(
      themeMode: _prefs.getString('theme_mode') ?? 'dark',
      useDynamicColors: _prefs.getBool('dynamic_colors') ?? false,
      shuffleEnabled: _prefs.getBool('shuffle') ?? false,
      gaplessPlayback: _prefs.getBool('gapless') ?? true,
      autoRotate: _prefs.getBool('auto_rotate') ?? true,
      pipMode: _prefs.getBool('pip_mode') ?? true,
      hardwareAcceleration: _prefs.getBool('hw_accel') ?? true,
      gestureControls: _prefs.getBool('gestures') ?? true,
      resumePlayback: _prefs.getBool('resume') ?? true,
      backgroundPlayback: _prefs.getBool('background') ?? true,
    );
  }

  AppSettings get settings => _settings;

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    await _prefs.setString('theme_mode', settings.themeMode);
    await _prefs.setBool('dynamic_colors', settings.useDynamicColors);
    await _prefs.setBool('shuffle', settings.shuffleEnabled);
    await _prefs.setBool('gapless', settings.gaplessPlayback);
    await _prefs.setBool('auto_rotate', settings.autoRotate);
    await _prefs.setBool('pip_mode', settings.pipMode);
    await _prefs.setBool('hw_accel', settings.hardwareAcceleration);
    await _prefs.setBool('gestures', settings.gestureControls);
    await _prefs.setBool('resume', settings.resumePlayback);
    await _prefs.setBool('background', settings.backgroundPlayback);
  }

  Future<void> savePlayState(String mediaId, Map<String, dynamic> state) async {
    await _playStateBox.put(mediaId, state);
  }

  Map<String, dynamic>? getPlayState(String mediaId) {
    final data = _playStateBox.get(mediaId);
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  List<String> getFavoriteIds() {
    final favorites = <String>[];
    for (final key in _playStateBox.keys) {
      final data = _playStateBox.get(key);
      if (data is Map && data['isFavorite'] == true) {
        favorites.add(key.toString());
      }
    }
    return favorites;
  }

  Future<void> addPlaylist(Playlist playlist) async {
    await _playlistBox.put(playlist.id, {
      'id': playlist.id,
      'name': playlist.name,
      'description': playlist.description,
      'mediaIds': playlist.mediaIds,
      'createdAt': playlist.createdAt.millisecondsSinceEpoch,
      'updatedAt': playlist.updatedAt.millisecondsSinceEpoch,
    });
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await addPlaylist(playlist);
  }

  Future<void> deletePlaylist(String id) async {
    await _playlistBox.delete(id);
  }

  List<Playlist> getAllPlaylists() {
    final playlists = <Playlist>[];
    for (final key in _playlistBox.keys) {
      final data = _playlistBox.get(key);
      if (data is Map) {
        playlists.add(Playlist(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          description: data['description'],
          mediaIds: List<String>.from(data['mediaIds'] ?? []),
          createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
        ));
      }
    }
    return playlists;
  }

  Playlist? getPlaylist(String id) {
    final data = _playlistBox.get(id);
    if (data is Map) {
      return Playlist(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'],
        mediaIds: List<String>.from(data['mediaIds'] ?? []),
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
      );
    }
    return null;
  }

  Future<void> clearAll() async {
    await _playStateBox.clear();
    await _playlistBox.clear();
  }

  Future<void> close() async {
    await _playStateBox.close();
    await _playlistBox.close();
  }
}
