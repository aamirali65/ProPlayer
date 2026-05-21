import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class NovaCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;

  const NovaCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    return onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            child: card,
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95))
        : card.animate().fadeIn(duration: 300.ms);
  }
}

class NovaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const NovaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = backgroundColor ?? theme.colorScheme.primary;

    final child = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color,
        border: isOutlined ? Border.all(color: color, width: 1.5) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: isOutlined ? color : textColor ?? theme.colorScheme.onPrimary),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isOutlined ? color : textColor ?? theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}

class NovaListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? customLeading;

  const NovaListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.customLeading,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: customLeading ?? leading,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, size: 20)
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class MediaThumbnail extends StatefulWidget {
  final String? mediaId;
  final double size;
  final bool isAudio;
  final BorderRadius? borderRadius;
  final String? filePath;

  const MediaThumbnail({
    super.key,
    this.mediaId,
    this.size = 48,
    this.isAudio = true,
    this.borderRadius,
    this.filePath,
  });

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  Uint8List? _videoThumbnail;
  bool _loadingThumbnail = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isAudio && widget.filePath != null) {
      _loadVideoThumbnail();
    }
  }

  @override
  void didUpdateWidget(MediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath && widget.filePath != null && !widget.isAudio) {
      _loadVideoThumbnail();
    }
  }

  Future<void> _loadVideoThumbnail() async {
    if (_loadingThumbnail || widget.filePath == null) return;
    _loadingThumbnail = true;
    try {
      final data = await VideoThumbnail.thumbnailData(
        video: widget.filePath!,
        imageFormat: ImageFormat.JPEG,
        maxWidth: widget.size.toInt() * 3,
        quality: 30,
        timeMs: 1000,
      );
      if (mounted && data != null) {
        setState(() => _videoThumbnail = data);
      }
    } catch (_) {}
    _loadingThumbnail = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isAudio) {
      return _buildAudioContent(context);
    }
    if (_videoThumbnail != null) {
      return Image.memory(_videoThumbnail!, fit: BoxFit.cover, width: widget.size, height: widget.size);
    }
    return _buildFallback(context, Icons.movie);
  }

  Widget _buildAudioContent(BuildContext context) {
    if (widget.mediaId == null) {
      return _buildFallback(context, Icons.music_note_rounded);
    }
    final id = int.tryParse(widget.mediaId!);
    if (id == null || id <= 0) {
      return _buildFallback(context, Icons.music_note_rounded);
    }
    return QueryArtworkWidget(
      id: id,
      type: ArtworkType.AUDIO,
      size: (widget.size * 3).toInt(),
      artworkWidth: widget.size,
      artworkHeight: widget.size,
      quality: 100,
      format: ArtworkFormat.JPEG,
      nullArtworkWidget: _buildFallback(context, Icons.music_note_rounded),
      errorBuilder: (context, error, stackTrace) => _buildFallback(context, Icons.music_note_rounded),
    );
  }

  Widget _buildFallback(BuildContext context, IconData icon) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(icon, size: widget.size * 0.5, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          action ??
              (onSeeAll != null
                  ? TextButton(
                      onPressed: onSeeAll,
                      child: const Text('See All'),
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class GradientOverlay extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final Alignment begin;
  final Alignment end;

  const GradientOverlay({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ??
              [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.transparent,
              ],
        ),
      ),
      child: child,
    );
  }
}
