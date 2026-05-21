import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../widgets/mini_player.dart';
import '../../core/extensions/extensions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mediaLibraryProvider.notifier).scanMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(mediaLibraryProvider);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _HomeTab(
              libraryState: libraryState,
              onRefresh: () => ref.read(mediaLibraryProvider.notifier).refreshMedia(),
              ref: ref,
            ),
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(mediaLibraryProvider);
                return AudioLibraryTab(libraryState: state);
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(mediaLibraryProvider);
                return VideoLibraryTab(libraryState: state);
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(mediaLibraryProvider);
                return FolderTab(libraryState: state, ref: ref);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Audio',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Video',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Folders',
          ),
        ],
      ),
      floatingActionButton: const MiniPlayer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final MediaLibraryState libraryState;
  final VoidCallback onRefresh;
  final WidgetRef ref;

  const _HomeTab({
    required this.libraryState,
    required this.onRefresh,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'ProPlayer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),
          if (libraryState.isScanning)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: libraryState.scanProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Scanning media... ${(libraryState.scanProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recently Played',
              onSeeAll: () => context.push('/audio'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: libraryState.audioItems.isEmpty
                  ? const Center(child: Text('No media found'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: libraryState.audioItems.take(10).length,
                      itemBuilder: (context, index) {
                        final item = libraryState.audioItems[index];
                        return _MediaCard(item: item);
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Continue Watching',
              onSeeAll: () => context.push('/video'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: libraryState.videoItems.isEmpty
                  ? const Center(child: Text('No videos found'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: libraryState.videoItems.take(10).length,
                      itemBuilder: (context, index) {
                        final item = libraryState.videoItems[index];
                        return _VideoCard(item: item);
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Quick Access',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _QuickAccessCard(
                    icon: Icons.favorite_rounded,
                    label: 'Favorites',
                    onTap: () => context.push('/playlists'),
                  ),
                  _QuickAccessCard(
                    icon: Icons.playlist_play_rounded,
                    label: 'Playlists',
                    onTap: () => context.push('/playlists'),
                  ),
                  _QuickAccessCard(
                    icon: Icons.person_rounded,
                    label: 'Artists',
                    onTap: () => context.push('/audio'),
                  ),
                  _QuickAccessCard(
                    icon: Icons.album_rounded,
                    label: 'Albums',
                    onTap: () => context.push('/audio'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recently Added',
              onSeeAll: () => context.push('/audio'),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = libraryState.audioItems[index];
                return _ListItem(
                  item: item,
                      onTap: () {
                        ref.read(audioPlayerProvider.notifier).playQueue(
                              libraryState.audioItems,
                              startIndex: index,
                            );
                      },
                );
              },
              childCount: libraryState.audioItems.take(5).length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final dynamic item;

  const _MediaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/audio-player');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaThumbnail(
                  mediaId: item.albumArt,
                  size: 140,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              item.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 100)).scale();
  }
}

class _VideoCard extends StatelessWidget {
  final dynamic item;

  const _VideoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/video-player'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 200,
                  height: 112,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MediaThumbnail(
                      mediaId: item.id,
                      size: 200,
                      isAudio: false,
                      filePath: item.path,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      Duration(milliseconds: item.duration).toFormattedString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 100)).scale();
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _ListItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
        item.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        Duration(milliseconds: item.duration).toFormattedString(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}

class AudioLibraryTab extends ConsumerWidget {
  final MediaLibraryState libraryState;

  const AudioLibraryTab({super.key, required this.libraryState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
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
          child: libraryState.audioItems.isEmpty
              ? const EmptyState(
                  icon: Icons.music_off,
                  title: 'No audio files found',
                  subtitle: 'Scan your device for music files',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: libraryState.audioItems.length,
                  itemBuilder: (context, index) {
                    final item = libraryState.audioItems[index];
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
                          libraryState.audioItems,
                          startIndex: index,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class VideoLibraryTab extends ConsumerWidget {
  final MediaLibraryState libraryState;

  const VideoLibraryTab({super.key, required this.libraryState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Video Library',
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
          child: libraryState.videoItems.isEmpty
              ? const EmptyState(
                  icon: Icons.movie_outlined,
                  title: 'No video files found',
                  subtitle: 'Scan your device for video files',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: libraryState.videoItems.length,
                  itemBuilder: (context, index) {
                    final item = libraryState.videoItems[index];
                    return GestureDetector(
                      onTap: () {
                        final videoPath = item.path;
                        if (videoPath.isNotEmpty) {
                          context.push('/video-player?id=${item.id}');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: MediaThumbnail(
                                    mediaId: item.id,
                                    size: 200,
                                    isAudio: false,
                                    filePath: item.path,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class FolderTab extends StatelessWidget {
  final MediaLibraryState libraryState;
  final WidgetRef ref;

  const FolderTab({super.key, required this.libraryState, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          child: libraryState.folders.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_off,
                  title: 'No folders found',
                  subtitle: 'Media folders will appear here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: libraryState.folders.length,
                  itemBuilder: (context, index) {
                    final folder = libraryState.folders[index];
                    final folderName = folder.split('/').last;
                    final media = libraryState.getMediaByFolder(folder);

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
                      subtitle: '${media.length} files',
                      onTap: () => context.push('/folder?path=$folder'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
