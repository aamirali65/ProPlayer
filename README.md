# 🎧 ProPlayer

ProPlayer is a modern, high-performance offline media player built using Flutter.  
It combines a powerful music player and advanced video player in one app, inspired by MX Player, VLC, and Poweramp.

---

## 📥 Download ProPlayer

Download the latest version of ProPlayer here:

➡️ **[Download APK](https://github.com/aamirali65/ProPlayer/releases/tag/v1.0.0)**

---

## 🚀 Features

### 🎵 Music Player
- Background audio playback
- Lock screen controls
- Notification controls
- Playlists system
- Favorites system
- Shuffle & repeat modes
- Sleep timer
- Resume last played position
- Queue management
- Folder-based music browsing
- Smooth waveform progress UI
- Album art support
- Audio metadata extraction

---

### 🎬 Video Player
- Fullscreen video playback
- Gesture controls like MX Player:
  - Swipe left/right → seek
  - Left vertical swipe → brightness
  - Right vertical swipe → volume
  - Double tap → seek 10 seconds
- Subtitle support (.srt)
- Playback speed control
- Picture-in-Picture mode
- Auto rotate support
- Resume video playback
- Fit / fill / stretch screen modes
- Lock screen mode for videos

---

### 📁 Media Library
- Auto scan device storage
- Separate audio & video library
- Folder browsing
- Recently played section
- Favorites section
- Fast local indexing

---

### 🔖 Playlists & Favorites
- Create custom playlists
- Add/remove songs
- Rename/delete playlists
- Favorite songs & videos
- Smart sorting options

---

### 🎨 UI / UX
- Modern Material 3 design
- Dark / Light / AMOLED themes
- Dynamic theme switching
- Smooth animations
- Minimal premium UI
- Floating mini player
- Clean navigation system

---

### ⚙️ Settings
- Theme selection
- Playback settings
- Gesture controls toggle
- Subtitle settings
- Sleep timer
- Cache management
- About section

---

## 🧱 Tech Stack

- Flutter (Latest Stable)
- Riverpod (State Management)
- Hive (Local Storage)
- just_audio (Audio playback)
- audio_service (Background audio)
- video_player / better_player (Video playback)
- on_audio_query (Media scanning)
- permission_handler (Permissions)
- path_provider (File access)
- flutter_animate (UI animations)
- screen_brightness (Video gestures)
- volume_controller (Video gestures)

---

## 🗂️ Architecture

Feature-first clean architecture:
lib/
├── core/
├── features/
│ ├── audio/
│ ├── video/
│ ├── library/
│ ├── playlist/
│ ├── settings/
├── models/
├── services/
├── providers/
├── widgets/
├── routes/


---

## 📱 Supported Platforms

- Android (fully optimized)
- iOS (limited features due to system restrictions)

---

## ⚡ Performance

- Lightweight media scanning
- Smooth playback engine
- Efficient memory usage
- Fast library loading
- Background optimized audio service

---

## ⚠️ Disclaimer

ProPlayer is intended for personal and educational use only.  
It does not support downloading copyrighted or DRM-protected content.

---

## 👨‍💻 Author

Built with Flutter by Aamir

---

## ⭐ Support

If you like this project, consider giving it a star ⭐ and contributing.
