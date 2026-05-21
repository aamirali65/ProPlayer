import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DurationExtension on Duration {
  String toFormattedString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

extension DateTimeExtension on DateTime {
  String toFormattedDate() {
    return DateFormat('MMM dd, yyyy').format(this);
  }
  
  String toRelativeDate() {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    return toFormattedDate();
  }
}

extension StringExtension on String {
  String get fileExtension {
    final index = lastIndexOf('.');
    return index != -1 ? substring(index).toLowerCase() : '';
  }
  
  String get fileName {
    final index = lastIndexOf('/');
    final lastIndex = lastIndexOf('\\');
    final finalIndex = index > lastIndex ? index : lastIndex;
    return finalIndex != -1 ? substring(finalIndex + 1) : this;
  }
  
  String get fileNameWithoutExtension {
    final name = fileName;
    final index = name.lastIndexOf('.');
    return index != -1 ? name.substring(0, index) : name;
  }
  
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension ListExtension<T> on List<T> {
  List<T> shuffledCopy() {
    final list = List<T>.from(this);
    list.shuffle();
    return list;
  }
}

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isTablet => screenWidth > 600;
  bool get isDesktop => screenWidth > 1200;
}
