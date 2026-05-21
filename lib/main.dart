import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/storage_service.dart';
import 'services/audio_player_service.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storageService = StorageService();
  await storageService.init();

  final audioService = AudioPlayerService();
  await audioService.init();
  await audioService.initAudioService();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        audioPlayerServiceProvider.overrideWithValue(audioService),
      ],
      child: const ProPlayerApp(),
    ),
  );
}

class ProPlayerApp extends ConsumerWidget {
  const ProPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ThemeData lightTheme = AppTheme.lightTheme;
        ThemeData darkTheme = AppTheme.darkTheme;
        ThemeData amoledTheme = AppTheme.amoledTheme;

        if (settings.useDynamicColors && darkDynamic != null) {
          darkTheme = darkTheme.copyWith(
            colorScheme: darkDynamic,
          );
        }

        return MaterialApp.router(
          title: 'ProPlayer',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: settings.themeMode == 'amoled' ? amoledTheme : darkTheme,
          themeMode: _getThemeMode(settings.themeMode),
          routerConfig: router,
        );
      },
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'amoled':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }
}
