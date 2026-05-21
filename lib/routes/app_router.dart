import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/permission/permission_screen.dart';
import '../features/home/home_screen.dart';
import '../features/audio/audio_library_screen.dart';
import '../features/video/video_library_screen.dart';
import '../features/folder/folder_screen.dart';
import '../features/audio/audio_player_screen.dart';
import '../features/video/video_player_screen.dart';
import '../features/search/search_screen.dart';
import '../features/playlist/playlist_screen.dart';
import '../features/playlist/playlist_details_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/about/about_screen.dart';
import '../features/queue/queue_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/permission',
      builder: (context, state) => const PermissionScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/audio',
      builder: (context, state) => const AudioLibraryScreen(),
    ),
    GoRoute(
      path: '/video',
      builder: (context, state) => const VideoLibraryScreen(),
    ),
    GoRoute(
      path: '/folder',
      builder: (context, state) {
        final folderPath = state.uri.queryParameters['path'] ?? '';
        return FolderScreen(folderPath: folderPath);
      },
    ),
    GoRoute(
      path: '/audio-player',
      builder: (context, state) {
        final mediaId = state.uri.queryParameters['id'];
        return AudioPlayerScreen(mediaId: mediaId);
      },
    ),
    GoRoute(
      path: '/video-player',
      builder: (context, state) {
        final mediaId = state.uri.queryParameters['id'];
        return VideoPlayerScreen(mediaId: mediaId);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/playlists',
      builder: (context, state) => const PlaylistScreen(),
    ),
    GoRoute(
      path: '/playlist/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return PlaylistDetailsScreen(playlistId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/queue',
      builder: (context, state) => const QueueScreen(),
    ),
  ],
);
