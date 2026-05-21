class Failure {
  final String message;
  final String? code;
  
  const Failure({
    required this.message,
    this.code,
  });
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({required super.message});
}

class MediaNotFoundFailure extends Failure {
  const MediaNotFoundFailure({required super.message});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message});
}
