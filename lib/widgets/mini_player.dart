import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);
    final currentMedia = audioState.currentMedia;

    if (currentMedia == null) return const SizedBox.shrink();

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          context.push('/audio-player');
        }
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 56),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          elevation: 8,
          child: InkWell(
            onTap: () => context.push('/audio-player'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  MediaThumbnail(
                    mediaId: currentMedia.albumArt,
                    size: 44,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentMedia.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentMedia.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      audioState.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: audioState.isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () => ref.read(audioPlayerProvider.notifier).toggleFavorite(),
                  ),
                  IconButton(
                    icon: Icon(
                      audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () => ref.read(audioPlayerProvider.notifier).togglePlayPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => ref.read(audioPlayerProvider.notifier).next(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(audioPlayerProvider.notifier).clearQueue(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms);
  }
}
