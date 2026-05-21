import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../../providers/providers.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final String? mediaId;

  const AudioPlayerScreen({super.key, this.mediaId});

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioPlayerProvider);
    final currentMedia = audioState.currentMedia;

    if (currentMedia == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No media playing')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildAlbumArt(context, audioState),
                      const SizedBox(height: 40),
                      _buildTrackInfo(context, currentMedia),
                      const SizedBox(height: 32),
                      _buildProgressBar(context, audioState),
                      const SizedBox(height: 24),
                      _buildControls(context, audioState),
                      const SizedBox(height: 24),
                      _buildExtraControls(context, audioState),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconSize: 32,
        ),
        const Spacer(),
        Text(
          'Now Playing',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'queue':
                context.push('/queue');
                break;
              case 'playlist':
                _showAddToPlaylistDialog(context);
                break;
              case 'sleep':
                _showSleepTimerDialog(context);
                break;
              case 'equalizer':
                _showEqualizerDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'queue', child: Text('Queue')),
            const PopupMenuItem(value: 'playlist', child: Text('Add to Playlist')),
            const PopupMenuItem(value: 'sleep', child: Text('Sleep Timer')),
            const PopupMenuItem(value: 'equalizer', child: Text('Equalizer')),
          ],
        ),
      ],
    );
  }

  Widget _buildAlbumArt(BuildContext context, AudioPlayerState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: state.isPlaying
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.music_note_rounded,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (state.isPlaying)
              CustomPaint(
                painter: _WavePainter(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  animation: _waveController,
                ),
                size: const Size(280, 280),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildTrackInfo(BuildContext context, dynamic media) {
    return Column(
      children: [
        Text(
          media.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          media.artist,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          media.album,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioPlayerState state) {
    return ProgressBar(
      progress: state.position,
      total: state.duration,
      buffered: state.bufferedPosition,
      onSeek: (duration) {
        ref.read(audioPlayerProvider.notifier).seekTo(duration);
      },
      timeLabelTextStyle: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      thumbGlowColor: Theme.of(context).colorScheme.primary,
      baseBarColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      progressBarColor: Theme.of(context).colorScheme.primary,
      bufferedBarColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      thumbRadius: 6,
      thumbGlowRadius: 12,
    );
  }

  Widget _buildControls(BuildContext context, AudioPlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => ref.read(audioPlayerProvider.notifier).toggleShuffle(),
          icon: Icon(
            Icons.shuffle_rounded,
            color: state.isShuffled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          onPressed: () => ref.read(audioPlayerProvider.notifier).previous(),
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 40,
        ),
        GestureDetector(
          onTap: () => ref.read(audioPlayerProvider.notifier).togglePlayPause(),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        IconButton(
          onPressed: () => ref.read(audioPlayerProvider.notifier).next(),
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 40,
        ),
        IconButton(
          onPressed: () => ref.read(audioPlayerProvider.notifier).toggleRepeat(),
          icon: Icon(
            state.repeatMode == 'one'
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: state.repeatMode != 'off'
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraControls(BuildContext context, AudioPlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => ref.read(audioPlayerProvider.notifier).toggleFavorite(),
          icon: Icon(
            state.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: state.isFavorite
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          onPressed: () => _showSpeedDialog(context),
          icon: Icon(
            Icons.speed_rounded,
            color: state.speed != 1.0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${state.speed}x',
          style: TextStyle(
            fontSize: 12,
            color: state.speed != 1.0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showSpeedDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Playback Speed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: speeds.map((speed) {
                  final isSelected = speed == ref.read(audioPlayerProvider).speed;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(audioPlayerProvider.notifier).setSpeed(speed);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final durations = [0, 5, 10, 15, 30, 45, 60];
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sleep Timer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: durations.map((minutes) {
                  return ChoiceChip(
                    label: Text(minutes == 0 ? 'Off' : '${minutes}m'),
                    selected: false,
                    onSelected: (selected) {
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEqualizerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Equalizer'),
          content: const Text('Equalizer settings coming soon'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    final playlists = ref.read(playlistProvider);
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a playlist first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add to Playlist',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              ...playlists.map((playlist) {
                return ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.itemCount} songs'),
                  onTap: () {
                    final mediaId = ref.read(audioPlayerProvider).currentMedia?.id;
                    if (mediaId != null) {
                      ref
                          .read(playlistProvider.notifier)
                          .addMediaToPlaylist(playlist.id, mediaId);
                    }
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _WavePainter({required this.color, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * (0.8 + animation.value * 0.2);

    path.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
