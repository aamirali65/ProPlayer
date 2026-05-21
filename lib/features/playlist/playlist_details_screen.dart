import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../core/extensions/extensions.dart';

class PlaylistDetailsScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailsScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final library = ref.watch(mediaLibraryProvider);
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;

    if (playlist == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(child: Text('Playlist not found', style: Theme.of(context).textTheme.bodyLarge)),
        ),
      );
    }

    final allMedia = [...library.audioItems, ...library.videoItems];
    final mediaItems = playlist.mediaIds
        .map((id) => allMedia.where((m) => m.id == id).firstOrNull)
        .whereType<MediaItem>()
        .toList();

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          '${playlist.itemCount} songs',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (mediaItems.isNotEmpty) {
                        final audioItems = mediaItems.where((m) => m.isAudio).toList();
                        if (audioItems.isNotEmpty) {
                          ref.read(audioPlayerProvider.notifier).playQueue(audioItems);
                        }
                      }
                    },
                    icon: const Icon(Icons.playlist_play),
                  ),
                ],
              ),
            ),
            Expanded(
              child: mediaItems.isEmpty
                  ? const EmptyState(
                      icon: Icons.music_off,
                      title: 'No media found',
                      subtitle: 'Media files may need to be rescanned',
                    )
                  : ListView.builder(
                      itemCount: mediaItems.length,
                      itemBuilder: (context, index) {
                        final item = mediaItems[index];
                        return ListTile(
                          leading: MediaThumbnail(
                            mediaId: item.albumArt,
                            filePath: item.isAudio ? null : item.path,
                            isAudio: item.isAudio,
                            size: 48,
                          ),
                          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(item.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isAudio)
                                Text(
                                  Duration(milliseconds: item.duration).toFormattedString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  ref
                                      .read(playlistProvider.notifier)
                                      .removeMediaFromPlaylist(playlistId, item.id);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            if (item.isAudio) {
                              final audioItems = mediaItems.where((m) => m.isAudio).toList();
                              final startIndex = audioItems.indexOf(item);
                              ref.read(audioPlayerProvider.notifier).playQueue(
                                audioItems,
                                startIndex: startIndex < 0 ? 0 : startIndex,
                              );
                              context.push('/audio-player');
                            } else {
                              context.push('/video-player?id=${item.id}');
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
