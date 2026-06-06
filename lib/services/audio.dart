// services/audio.dart
import 'package:media_kit/media_kit.dart';
import '../models/song.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Player _player = Player();
  Song? _currentSong;
  bool _isPlaying = false;

  Player get player => _player;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;

  Future<void> playSong(Song song) async {
    if (_currentSong?.filePath == song.filePath && _isPlaying) return;
    _currentSong = song;
    await _player.open(Media(song.filePath));
    await _player.play();
    _isPlaying = true;
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    await _player.play();
    _isPlaying = true;
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentSong = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
