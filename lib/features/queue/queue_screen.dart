import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final queue = audioState.queue;
    final currentIndex = audioState.currentIndex;

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
                    'Queue',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (queue.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).clearQueue();
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const EmptyState(
                      icon: Icons.queue_music,
                      title: 'Queue is empty',
                      subtitle: 'Play some music to add to the queue',
                    )
                  : ReorderableListView.builder(
                      itemCount: queue.length,
                      onReorder: (oldIndex, newIndex) {
                        ref.read(audioPlayerProvider.notifier).moveQueueItem(
                              oldIndex,
                              newIndex > oldIndex ? newIndex - 1 : newIndex,
                            );
                      },
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isCurrent = index == currentIndex;

                        return ListTile(
                          key: ValueKey(item.id),
                          leading: MediaThumbnail(
                            mediaId: item.albumArt,
                            filePath: item.isAudio ? null : item.path,
                            isAudio: item.isAudio,
                            size: 48,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: Text(item.artist),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCurrent)
                                Icon(
                                  Icons.equalizer,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  ref
                                      .read(audioPlayerProvider.notifier)
                                      .removeFromQueue(index);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            ref.read(audioPlayerProvider.notifier).playQueue(
                                  queue,
                                  startIndex: index,
                                );
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
