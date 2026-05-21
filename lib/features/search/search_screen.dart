import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../core/extensions/extensions.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search songs, artists, albums, videos...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  ref.read(searchProvider.notifier).clear();
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        ref.read(searchProvider.notifier).search(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: searchState.query.isEmpty
                  ? _buildSuggestions(context)
                  : searchState.isSearching
                      ? const LoadingIndicator()
                      : searchState.results.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off,
                              title: 'No results found',
                              subtitle: 'Try a different search term',
                            )
                          : _buildResults(context, searchState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final libraryState = ref.watch(mediaLibraryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Browse All',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(icon: Icons.music_note, label: 'Songs', onTap: () => context.push('/audio')),
            _CategoryChip(icon: Icons.movie, label: 'Videos', onTap: () => context.push('/video')),
            _CategoryChip(icon: Icons.person, label: 'Artists', onTap: () {}),
            _CategoryChip(icon: Icons.album, label: 'Albums', onTap: () {}),
            _CategoryChip(icon: Icons.playlist_play, label: 'Playlists', onTap: () => context.push('/playlists')),
            _CategoryChip(icon: Icons.folder, label: 'Folders', onTap: () => context.push('/folder')),
          ],
        ),
        const SizedBox(height: 24),
        if (libraryState.artists.isNotEmpty) ...[
          Text(
            'Top Artists',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...libraryState.artists.take(5).map((artist) {
            return NovaListTile(
              leading: const Icon(Icons.person),
              title: artist,
              onTap: () {},
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildResults(BuildContext context, SearchState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final item = state.results[index];
        return ListTile(
          leading: MediaThumbnail(
            mediaId: item.albumArt,
            filePath: item.isAudio ? null : item.path,
            size: 48,
            isAudio: item.isAudio,
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
            if (item.isAudio) {
              ref.read(audioPlayerProvider.notifier).playMedia(item);
              context.push('/audio-player');
            } else {
              context.push('/video-player');
            }
          },
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
