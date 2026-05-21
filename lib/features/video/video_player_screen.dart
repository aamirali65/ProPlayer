import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../core/extensions/extensions.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String? mediaId;

  const VideoPlayerScreen({super.key, this.mediaId});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isLocked = false;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  String _fitMode = 'contain';
  int _selectedSubtitle = -1;
  int _selectedAudioTrack = -1;
  List<String> _subtitleFiles = [];
  List<String> _subtitleContents = [];
  Timer? _hideTimer;
  Timer? _positionTimer;
  Timer? _subtitleTimer;
  String _currentSubtitleText = '';
  String _error = '';
  String _videoTitle = '';
  Uint8List? _posterImage;

  // Gesture tracking
  Offset? _lastDragPosition;
  double _brightness = 1.0;
  double _volume = 1.0;
  bool _isDraggingBrightness = false;
  bool _isDraggingVolume = false;
  String _seekTapSide = 'center';
  bool _isPortrait = false;

  // Seek gesture
  bool _isSeeking = false;
  Duration _seekPosition = Duration.zero;
  String _seekDirection = '';

  @override
  void initState() {
    super.initState();
    _setOrientation(false);
    WakelockPlus.enable();
    _initVideo();
  }

  void _setOrientation(bool portrait) {
    if (portrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _toggleOrientation() {
    final newPortrait = !_isPortrait;
    setState(() => _isPortrait = newPortrait);
    _setOrientation(newPortrait);
  }

  Future<void> _initVideo() async {
    try {
      final library = ref.read(mediaLibraryProvider);
      final mediaId = widget.mediaId;

      MediaItem? mediaItem;
      if (mediaId != null) {
        mediaItem = library.videoItems.where((v) => v.id == mediaId).firstOrNull;
      }

      final path = mediaItem?.path;
      if (path == null || path.isEmpty) {
        setState(() => _error = 'Video not found');
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        setState(() => _error = 'File not found: $path');
        return;
      }

      setState(() => _videoTitle = mediaItem!.title);

      _posterImage = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 480,
        quality: 50,
        timeMs: 1000,
      );

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      _controller!.addListener(_onVideoUpdate);

      setState(() {
        _isInitialized = true;
        _isPlaying = true;
      });

      _controller!.play();
      _controller!.setPlaybackSpeed(_playbackSpeed);
      _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted && _controller != null && _controller!.value.isInitialized) {
          setState(() {});
        }
      });

      await _loadSubtitles(path);
    } catch (e) {
      setState(() => _error = 'Failed to load video: $e');
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    if (value.hasError) {
      setState(() => _error = value.errorDescription ?? 'Video error');
    }
  }

  Future<void> _loadSubtitles(String videoPath) async {
    final dir = Directory(videoPath).parent;
    final baseName = videoPath.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
    final files = <String>[];
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (['srt', 'vtt', 'ass', 'ssa', 'sub'].contains(ext)) {
            files.add(entity.path);
          }
        }
      }
    } catch (_) {}

    if (files.isEmpty) return;

    files.sort((a, b) {
      final aMatch = a.contains(baseName) ? 0 : 1;
      final bMatch = b.contains(baseName) ? 0 : 1;
      if (aMatch != bMatch) return aMatch.compareTo(bMatch);
      return a.compareTo(b);
    });

    final contents = <String>[];
    for (final path in files) {
      try {
        contents.add(await File(path).readAsString());
      } catch (_) {
        contents.add('');
      }
    }

    final bestMatch = files.indexWhere((f) => f.contains(baseName));
    setState(() {
      _subtitleFiles = files;
      _subtitleContents = contents;
      _selectedSubtitle = bestMatch >= 0 ? bestMatch : 0;
      if (_selectedSubtitle >= 0) _startSubtitleParsing();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _positionTimer?.cancel();
    _subtitleTimer?.cancel();
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    if (_isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    if (_isLocked) {
      setState(() => _isLocked = false);
      _showControls = true;
      _scheduleHideControls();
      return;
    }
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) _scheduleHideControls();
  }

  void _togglePlayback() {
    if (_controller == null) return;
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
    if (_isPlaying) _scheduleHideControls();
  }

  void _seekRelative(int seconds, {String side = 'center'}) {
    if (_controller == null) return;
    final current = _controller!.value.position;
    final total = _controller!.value.duration;
    final candidate = current + Duration(seconds: seconds);
    final newPos = candidate < Duration.zero ? Duration.zero : (candidate > total ? total : candidate);
    _controller!.seekTo(newPos);
    setState(() {
      _seekPosition = newPos;
      _seekDirection = seconds > 0 ? 'forward' : 'backward';
      _seekTapSide = side;
    });
    _scheduleHideControls();
  }

  void _onDoubleTap(TapDownDetails details) {
    if (_isLocked) return;
    final screenWidth = context.screenWidth;
    final tapX = details.globalPosition.dx;
    if (tapX < screenWidth / 3) {
      _seekRelative(-10, side: 'left');
    } else if (tapX > screenWidth * 2 / 3) {
      _seekRelative(10, side: 'right');
    } else {
      _togglePlayback();
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isLocked || _controller == null) return;
    final screenWidth = context.screenWidth;
    final dx = details.globalPosition.dx;
    _lastDragPosition = details.globalPosition;
    if (dx < screenWidth / 2) {
      _isDraggingBrightness = true;
    } else {
      _isDraggingVolume = true;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_controller == null) return;
    final delta = details.globalPosition.dy - (_lastDragPosition?.dy ?? details.globalPosition.dy);
    _lastDragPosition = details.globalPosition;

    if (_isDraggingBrightness) {
      _brightness = (_brightness - delta / 500).clamp(0.0, 1.0);
    } else if (_isDraggingVolume) {
      _volume = (_volume - delta / 500).clamp(0.0, 1.0);
    }
    setState(() {});
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isDraggingBrightness = false;
    _isDraggingVolume = false;
    _scheduleHideControls();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isLocked || _controller == null) return;
    _lastDragPosition = details.globalPosition;
    _isSeeking = true;
    _seekPosition = _controller!.value.position;
    setState(() {
      _showControls = true;
      _seekDirection = '';
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller == null || !_isSeeking) return;
    final delta = details.globalPosition.dx - (_lastDragPosition?.dx ?? 0);
    _lastDragPosition = details.globalPosition;
    final totalMs = _controller!.value.duration.inMilliseconds;
    if (totalMs <= 0) return;
    final seekMs = (delta / context.screenWidth * totalMs).round();
    final current = _seekPosition.inMilliseconds;
    final newMs = (current + seekMs).clamp(0, totalMs);
    _seekPosition = Duration(milliseconds: newMs);
    _seekDirection = seekMs > 0 ? 'forward' : 'backward';
    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isSeeking && _controller != null) {
      _controller!.seekTo(_seekPosition);
    }
    _isSeeking = false;
    _scheduleHideControls();
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((s) {
            return ChoiceChip(
              label: Text('${s}x'),
              selected: s == _playbackSpeed,
              onSelected: (sel) {
                if (sel) {
                  setState(() => _playbackSpeed = s);
                  _controller?.setPlaybackSpeed(s);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList()),
        ]),
      ),
    );
  }

  void _showFitDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Video Fit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          ...[
            ('contain', 'Fit', 'Maintain aspect ratio, show entire video'),
            ('cover', 'Fill', 'Fill screen, may crop edges'),
            ('fill', 'Stretch', 'Stretch to fill screen'),
          ].map((m) => RadioListTile<String>(
                title: Text(m.$2, style: const TextStyle(color: Colors.white)),
                subtitle: Text(m.$3, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                value: m.$1,
                groupValue: _fitMode,
                activeColor: Colors.cyan,
                onChanged: (v) {
                  setState(() => _fitMode = v!);
                  Navigator.pop(ctx);
                },
              )),
        ]),
      ),
    );
  }

  void _showSubtitleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Subtitles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          RadioListTile<int>(
            title: const Text('Off', style: TextStyle(color: Colors.white)),
            value: -1,
            groupValue: _selectedSubtitle,
            activeColor: Colors.cyan,
            onChanged: (v) {
              setState(() {
                _selectedSubtitle = v!;
                _currentSubtitleText = '';
              });
              Navigator.pop(ctx);
            },
          ),
          ..._subtitleFiles.asMap().entries.map((e) {
            final name = e.value.split('/').last;
            return RadioListTile<int>(
              title: Text(name, style: const TextStyle(color: Colors.white)),
              value: e.key,
              groupValue: _selectedSubtitle,
              activeColor: Colors.cyan,
              onChanged: (v) {
                setState(() {
                  _selectedSubtitle = v!;
                  _startSubtitleParsing();
                });
                Navigator.pop(ctx);
              },
            );
          }),
        ]),
      ),
    );
  }

  void _startSubtitleParsing() {
    _subtitleTimer?.cancel();
    if (_selectedSubtitle < 0 || _selectedSubtitle >= _subtitleContents.length) return;
    _subtitleTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _controller == null) return;
      final pos = _controller!.value.position;
      final text = _parseSubtitleAt(_subtitleContents[_selectedSubtitle], pos);
      if (text != _currentSubtitleText) {
        setState(() => _currentSubtitleText = text);
      }
    });
  }

  String _parseSubtitleAt(String srt, Duration pos) {
    final ms = pos.inMilliseconds;
    final blocks = srt.split(RegExp(r'\n\s*\n'));
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;
      final timeLine = lines.firstWhere((l) => l.contains('-->'), orElse: () => '');
      if (timeLine.isEmpty) continue;
      final parts = timeLine.split('-->');
      if (parts.length != 2) continue;
      final startMs = _parseSrtTime(parts[0].trim());
      final endMs = _parseSrtTime(parts[1].trim());
      if (ms >= startMs && ms <= endMs) {
        return lines.skip(1).where((l) => l.trim().isNotEmpty && !l.contains('-->')).join('\n');
      }
    }
    return '';
  }

  int _parseSrtTime(String time) {
    final parts = time.split(RegExp(r'[:,]'));
    if (parts.length != 4) return 0;
    try {
      return int.parse(parts[0]) * 3600000 +
          int.parse(parts[1]) * 60000 +
          int.parse(parts[2]) * 1000 +
          int.parse(parts[3]);
    } catch (_) {
      return 0;
    }
  }

  void _showAudioDialog() async {
    if (_controller == null) return;
    if (!(_controller!.isAudioTrackSupportAvailable())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio track selection not available on this device')),
      );
      return;
    }
    final tracks = await _controller!.getAudioTracks();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Audio Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          if (tracks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No alternate audio tracks available', style: TextStyle(color: Colors.white54)),
            )
          else
            ...tracks.asMap().entries.map((e) {
              final track = e.value;
              final label = track.label ?? track.language ?? 'Track ${e.key + 1}';
              return RadioListTile<String>(
                title: Text(label, style: const TextStyle(color: Colors.white)),
                value: track.id,
                groupValue: _selectedAudioTrack >= 0 ? tracks[_selectedAudioTrack].id : '',
                activeColor: Colors.cyan,
                onChanged: (v) {
                  _controller!.selectAudioTrack(v!);
                  setState(() => _selectedAudioTrack = e.key);
                  Navigator.pop(ctx);
                },
              );
            }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
          ]),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_posterImage != null)
              Image.memory(_posterImage!, fit: BoxFit.contain)
            else
              Container(color: Colors.black),
            Container(
              color: Colors.black26,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(
                    width: 48, height: 48,
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
                  const SizedBox(height: 16),
                  Text(_videoTitle.isNotEmpty ? _videoTitle : 'Loading...',
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: _onDoubleTap,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            _buildVideoDisplay(),
            if (_isSeeking) _buildSeekIndicator(),
            if (_showControls && !_isLocked) _buildOverlay(),
            if (_isLocked) _buildLockIndicator(),
            if (_isDraggingBrightness) _buildBrightnessOverlay(),
            if (_isDraggingVolume) _buildVolumeOverlay(),
            if (_currentSubtitleText.isNotEmpty && !_showControls)
              _buildSubtitleOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDisplay() {
    final boxFit = _fitMode == 'cover' ? BoxFit.cover
        : _fitMode == 'fill' ? BoxFit.fill
        : BoxFit.contain;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Center(
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                fit: boxFit,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeekIndicator() {
    final pos = _seekPosition;
    final total = _controller?.value.duration ?? Duration.zero;
    final icon = _seekDirection == 'forward'
        ? Icons.forward_30_rounded
        : _seekDirection == 'backward'
            ? Icons.replay_30_rounded
            : Icons.play_circle_outline_rounded;
    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
          child: Text(
            '${pos.toFormattedString()} / ${total.toFormattedString()}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
    if (_seekTapSide == 'left') {
      return Positioned(
        top: 0, bottom: 0, left: 0,
        width: MediaQuery.of(context).size.width * 0.4,
        child: IgnorePointer(child: Center(child: indicator)),
      );
    } else if (_seekTapSide == 'right') {
      return Positioned(
        top: 0, bottom: 0, right: 0,
        width: MediaQuery.of(context).size.width * 0.4,
        child: IgnorePointer(child: Center(child: indicator)),
      );
    }
    return Positioned.fill(
      child: IgnorePointer(child: Center(child: indicator)),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        _buildTopBar(),
        _buildCenterControls(),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 8, right: 8, bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                context.pop();
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Text(
                _videoTitle,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _isLocked = !_isLocked),
              icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: Colors.white),
            ),
            IconButton(
              onPressed: _toggleOrientation,
              icon: Icon(
                _isPortrait ? Icons.screen_rotation : Icons.crop_portrait_rounded,
                color: Colors.white,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) {
                switch (v) {
                  case 'speed': _showSpeedDialog(); break;
                  case 'fit': _showFitDialog(); break;
                  case 'subtitle': _showSubtitleDialog(); break;
                  case 'audio': _showAudioDialog(); break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'speed', child: ListTile(leading: Icon(Icons.speed), title: Text('Speed'), dense: true)),
                const PopupMenuItem(value: 'fit', child: ListTile(leading: Icon(Icons.aspect_ratio), title: Text('Fit Mode'), dense: true)),
                const PopupMenuItem(value: 'subtitle', child: ListTile(leading: Icon(Icons.subtitles), title: Text('Subtitles'), dense: true)),
                const PopupMenuItem(value: 'audio', child: ListTile(leading: Icon(Icons.audiotrack), title: Text('Audio Track'), dense: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Positioned.fill(
      child: Row(
        children: [
          Expanded(child: GestureDetector(
            onTap: () => _seekRelative(-10, side: 'left'),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 4),
                  const Text('-10s', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          )),
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          Expanded(child: GestureDetector(
            onTap: () => _seekRelative(10, side: 'right'),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 4),
                  const Text('+10s', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final pos = _controller?.value.position ?? Duration.zero;
    final total = _controller?.value.duration ?? Duration.zero;
    final buffered = _controller?.value.buffered.isNotEmpty == true
        ? _controller!.value.buffered.last.end
        : Duration.zero;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressBar(
              progress: pos,
              total: total,
              buffered: buffered,
              onSeek: (d) => _controller?.seekTo(d),
              timeLabelTextStyle: const TextStyle(color: Colors.white, fontSize: 11),
              thumbGlowColor: Colors.cyan,
              baseBarColor: Colors.white24,
              progressBarColor: Colors.cyan,
              bufferedBarColor: Colors.white12,
              thumbRadius: 6,
              thumbGlowRadius: 12,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${_playbackSpeed}x', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const Spacer(),
                if (_subtitleFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.subtitles,
                        color: _selectedSubtitle >= 0 ? Colors.cyan : Colors.white24,
                        size: 16),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() => _isLocked = false);
          _showControls = true;
          _scheduleHideControls();
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.lock, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildBrightnessOverlay() {
    return Positioned(
      left: 16,
      top: 0, bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_brightness > 0.5 ? Icons.brightness_high : Icons.brightness_low,
                    color: Colors.white, size: 24),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: LinearProgressIndicator(
                      value: _brightness,
                      color: Colors.cyan,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeOverlay() {
    return Positioned(
      right: 16,
      top: 0, bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_volume > 0.5 ? Icons.volume_up : _volume > 0 ? Icons.volume_down : Icons.volume_mute,
                    color: Colors.white, size: 24),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: LinearProgressIndicator(
                      value: _volume,
                      color: Colors.cyan,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleOverlay() {
    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _currentSubtitleText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
