import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _isLoading = false;
  String _status = 'Requesting permissions...';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting permissions...';
    });

    try {
      final mediaPermissions = await [
        Permission.audio,
        Permission.videos,
        Permission.photos,
      ].request();

      if ((mediaPermissions[Permission.audio]?.isGranted ?? false) &&
          (mediaPermissions[Permission.videos]?.isGranted ?? false)) {
        _navigateToHome();
        return;
      }

      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        _navigateToHome();
        return;
      }

      await Permission.storage.request();
      _navigateToHome();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error requesting permissions.';
      });
    }
  }

  void _navigateToHome() {
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
              const SizedBox(height: 32),
              Text(
                'Storage Access Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                'ProPlayer needs access to your media files to scan and play your music and videos.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator()
                    .animate()
                    .fadeIn()
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _requestPermissions,
                        icon: const Icon(Icons.security_rounded),
                        label: const Text('Grant Permission'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _navigateToHome,
                      child: const Text('Continue without permission'),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
