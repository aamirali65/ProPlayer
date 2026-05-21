import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/mini_player.dart';
import '../../models/models.dart';

class FolderScreen extends ConsumerWidget {
  final String folderPath;

  const FolderScreen({
    super.key,
    this.folderPath = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(mediaLibraryProvider);
    final folders = libraryState.folders;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Folders',
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
              child: folders.isEmpty
                  ? const EmptyState(
                      icon: Icons.folder_off,
                      title: 'No folders found',
                      subtitle: 'Media folders will appear here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        final folderName = folder.split('/').last;
                        final mediaCount = libraryState.getMediaByFolder(folder).length;

                        return NovaListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: folderName,
                          subtitle: '$mediaCount files • $folder',
                          onTap: () {
                            final media = libraryState.getMediaByFolder(folder);
                            if (media.isNotEmpty) {
                              _showFolderMedia(context, ref, media, folderName);
                            }
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

  void _showFolderMedia(BuildContext context, WidgetRef ref, List<dynamic> media, String folderName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final audioFiles = media.where((m) => m.isAudio).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      folderName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${media.length} files',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: media.length,
                  itemBuilder: (context, index) {
                    final item = media[index];
                    return ListTile(
                      leading: MediaThumbnail(
                        mediaId: item.albumArt,
                        filePath: item.isAudio ? null : item.path,
                        isAudio: item.isAudio,
                        size: 48,
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.artist ?? ''),
                      trailing: item.isAudio
                          ? Icon(Icons.music_note, size: 20,
                              color: Theme.of(context).colorScheme.primary)
                          : Icon(Icons.movie, size: 20,
                              color: Theme.of(context).colorScheme.secondary),
                      onTap: () {
                        Navigator.pop(context);
                        if (item.isAudio && audioFiles.isNotEmpty) {
                          final startIndex = audioFiles.indexOf(item);
                          ref.read(audioPlayerProvider.notifier).playQueue(
                            audioFiles.cast<MediaItem>(),
                            startIndex: startIndex < 0 ? 0 : startIndex,
                          );
                        } else {
                          context.push('/video-player?id=${item.id}');
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
