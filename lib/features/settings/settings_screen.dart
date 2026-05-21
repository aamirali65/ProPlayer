import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildSection(
                    context,
                    'Appearance',
                    [
                      NovaListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: 'Theme',
                        subtitle: settings.themeMode[0].toUpperCase() + settings.themeMode.substring(1),
                        onTap: () => _showThemeDialog(context, ref),
                      ),
                      NovaListTile(
                        leading: const Icon(Icons.color_lens_outlined),
                        title: 'Dynamic Colors',
                        trailing: Switch(
                          value: settings.useDynamicColors,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).toggleDynamicColors(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildSection(
                    context,
                    'Audio',
                    [
                      NovaListTile(
                        leading: const Icon(Icons.shuffle),
                        title: 'Shuffle by Default',
                        trailing: Switch(
                          value: settings.shuffleEnabled,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(shuffleEnabled: value),
                                );
                          },
                        ),
                      ),
                      NovaListTile(
                        leading: const Icon(Icons.repeat),
                        title: 'Gapless Playback',
                        trailing: Switch(
                          value: settings.gaplessPlayback,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(gaplessPlayback: value),
                                );
                          },
                        ),
                      ),
                      NovaListTile(
                        leading: const Icon(Icons.equalizer),
                        title: 'Equalizer',
                        onTap: () {},
                      ),
                    ],
                  ),
                  _buildSection(
                    context,
                    'Video',
                    [
                      NovaListTile(
                        leading: const Icon(Icons.rotate_90_degrees_cw),
                        title: 'Auto Rotate',
                        trailing: Switch(
                          value: settings.autoRotate,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(autoRotate: value),
                                );
                          },
                        ),
                      ),
                      NovaListTile(
                        leading: const Icon(Icons.picture_in_picture),
                        title: 'Picture in Picture',
                        trailing: Switch(
                          value: settings.pipMode,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(pipMode: value),
                                );
                          },
                        ),
                      ),
                      NovaListTile(
                        leading: const Icon(Icons.speed),
                        title: 'Hardware Acceleration',
                        trailing: Switch(
                          value: settings.hardwareAcceleration,
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(hardwareAcceleration: value),
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildSection(
                    context,
                    'Library',
                    [
                      NovaListTile(
                        leading: const Icon(Icons.folder_off),
                        title: 'Excluded Folders',
                        subtitle: '${settings.excludedFolders.length} folders',
                        onTap: () {},
                      ),
                      NovaListTile(
                        leading: const Icon(Icons.refresh),
                        title: 'Refresh Library',
                        onTap: () {
                          ref.read(mediaLibraryProvider.notifier).refreshMedia();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Library refreshed')),
                          );
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    context,
                    'About',
                    [
                      NovaListTile(
                        leading: const Icon(Icons.info_outline),
                        title: 'About ProPlayer',
                        onTap: () => context.push('/about'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final settings = ref.read(settingsProvider);
        return AlertDialog(
          title: const Text('Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('Dark'),
                value: 'dark',
                groupValue: settings.themeMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).toggleTheme(value.toString());
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text('Light'),
                value: 'light',
                groupValue: settings.themeMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).toggleTheme(value.toString());
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text('AMOLED'),
                value: 'amoled',
                groupValue: settings.themeMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).toggleTheme(value.toString());
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
