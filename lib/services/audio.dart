// services/audio.dart
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  Song? _currentSong;

  AudioPlayer get player => _player;
  Song? get currentSong => _currentSong;

  /// 播放新歌曲
  Future<void> playSong(Song song) async {
    if (_currentSong?.filePath == song.filePath) return;
    _currentSong = song;
    await _player.setAudioSource(AudioSource.uri(Uri.file(song.filePath)));
    await _player.play();
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);
  Future<void> setVolume(double volume) async => await _player.setVolume(volume);
  Future<void> dispose() async => await _player.dispose();

  // 为了兼容 MusicProvider 的现有调用
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }
}
