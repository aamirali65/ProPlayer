import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/mini_player.dart';
import '../../core/extensions/extensions.dart';

class AudioLibraryScreen extends ConsumerWidget {
  const AudioLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(mediaLibraryProvider);
    final audioItems = libraryState.audioItems;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Audio Library',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: audioItems.isEmpty
                  ? const EmptyState(
                      icon: Icons.music_off,
                      title: 'No audio files found',
                      subtitle: 'Scan your device for music files',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: audioItems.length,
                      itemBuilder: (context, index) {
                        final item = audioItems[index];
                        return ListTile(
                          leading: MediaThumbnail(
                            mediaId: item.albumArt,
                            size: 48,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item.artist} • ${item.album}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            Duration(milliseconds: item.duration).toFormattedString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            ref.read(audioPlayerProvider.notifier).playQueue(
                                  audioItems,
                                  startIndex: index,
                                );
                            context.push('/audio-player');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: const MiniPlayer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
