class AppConstants {
  AppConstants._();

  static const String appName = 'ProPlayer';
  static const String appVersion = '1.0.0';
  
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxFavorites = 'favorites';
  static const String hiveBoxPlayHistory = 'play_history';
  static const String hiveBoxPlaylists = 'playlists';
  static const String hiveBoxResumePositions = 'resume_positions';
  static const String hiveBoxVideoHistory = 'video_history';
  
  static const List<String> audioExtensions = [
    '.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus'
  ];
  
  static const List<String> videoExtensions = [
    '.mp4', '.mkv', '.avi', '.mov', '.webm', '.flv', '.ts', '.m4v'
  ];
  
  static const List<String> subtitleExtensions = [
    '.srt', '.ass', '.ssa', '.vtt', '.sub'
  ];
  
  static const List<String> defaultExcludeFolders = [
    'Android', 'iOS', 'System', '.thumbnails', 'WhatsApp', 'Telegram',
    'com.whatsapp', 'com.telegram', 'LOST.DIR'
  ];
  
  static const int maxPlaylistNameLength = 50;
  static const int maxSearchResults = 100;
  static const Duration sleepTimerDefault = Duration(minutes: 30);
  static const double defaultPlaybackSpeed = 1.0;
  static const List<double> playbackSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
}
