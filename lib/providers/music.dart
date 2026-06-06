// providers/music.dart
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio.dart';
import 'dart:math';
import 'package:media_kit/media_kit.dart';

enum PlayMode {
  repeat,      // 列表循环
  repeatOne,   // 单曲循环
  shuffle,     // 随机播放
  sequential,  // 顺序播放（播放完停止）
}

class MusicProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  List<Song> _playlist = [];
  List<Song> _originalPlaylist = []; // 原始播放列表（用于随机播放）
  int _currentIndex = -1;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  PlayMode _playMode = PlayMode.repeat; // 默认列表循环

  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  PlayMode get playMode => _playMode;

  // 获取播放模式图标
  IconData get playModeIcon {
    switch (_playMode) {
      case PlayMode.repeat:
        return Icons.repeat;
      case PlayMode.repeatOne:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.sequential:
        return Icons.playlist_play;
    }
  }

  // 获取播放模式提示文字
  String get playModeHint {
    switch (_playMode) {
      case PlayMode.repeat:
        return '列表循环';
      case PlayMode.repeatOne:
        return '单曲循环';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.sequential:
        return '顺序播放';
    }
  }

  MusicProvider() {
    _initListeners();
  }

  void _initListeners() {
    _audioService.player.stream.position.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _audioService.player.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
    _audioService.player.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });
    _audioService.player.stream.completed.listen((_) {
      _onPlaybackCompleted();
    });
  }

  // 播放完成时的处理
  void _onPlaybackCompleted() {
    switch (_playMode) {
      case PlayMode.repeatOne:
        // 单曲循环：重新播放当前歌曲
        _replayCurrent();
        break;
      case PlayMode.repeat:
      case PlayMode.shuffle:
      case PlayMode.sequential:
        // 自动播放下一首
        nextTrack();
        break;
    }
  }

  // 切换播放模式
  void togglePlayMode() {
    switch (_playMode) {
      case PlayMode.repeat:
        _playMode = PlayMode.repeatOne;
        break;
      case PlayMode.repeatOne:
        _playMode = PlayMode.shuffle;
        break;
      case PlayMode.shuffle:
        _playMode = PlayMode.sequential;
        break;
      case PlayMode.sequential:
        _playMode = PlayMode.repeat;
        break;
    }

    // 如果是随机播放模式且播放列表为空，重新生成随机列表
    if (_playMode == PlayMode.shuffle && _originalPlaylist.isNotEmpty) {
      _generateShufflePlaylist();
    }

    notifyListeners();
  }

  // 生成随机播放列表
  void _generateShufflePlaylist() {
    _originalPlaylist = List.from(_playlist);
    final currentSongId = currentSong?.id;

    // 随机打乱列表
    _playlist.shuffle();

    // 确保当前播放的歌曲在新列表中的位置正确
    if (currentSongId != null) {
      final newIndex = _playlist.indexWhere((s) => s.id == currentSongId);
      if (newIndex != -1) {
        _currentIndex = newIndex;
      }
    }
  }

  // 恢复原始播放列表（退出随机模式时）
  void _restoreOriginalPlaylist() {
    if (_originalPlaylist.isNotEmpty) {
      final currentSongId = currentSong?.id;
      _playlist = List.from(_originalPlaylist);
      if (currentSongId != null) {
        _currentIndex = _playlist.indexWhere((s) => s.id == currentSongId);
        if (_currentIndex == -1) _currentIndex = 0;
      }
      _originalPlaylist.clear();
    }
  }

  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _originalPlaylist = List.from(songs);

    if (_playMode == PlayMode.shuffle) {
      _playlist = List.from(songs);
      _playlist.shuffle();
      // 找到原索引对应的歌曲在新列表中的位置
      final targetSong = songs[startIndex];
      _currentIndex = _playlist.indexWhere((s) => s.id == targetSong.id);
      if (_currentIndex == -1) _currentIndex = 0;
    } else {
      _playlist = List.from(songs);
      _currentIndex = startIndex;
    }

    _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    final song = _playlist[_currentIndex];
    await _audioService.playSong(song);
  }

  void playSong(Song song, List<Song> fullList) {
    final index = fullList.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      setPlaylist(fullList, startIndex: index);
    } else {
      setPlaylist([song], startIndex: 0);
    }
  }

  Future<void> _replayCurrent() async {
    await _audioService.seek(Duration.zero);
    await _audioService.resume();
  }

  Future<void> nextTrack() async {
    if (_playlist.isEmpty) return;

    if (_playMode == PlayMode.shuffle) {
      // 随机播放：随机选择下一首
      final newIndex = Random().nextInt(_playlist.length);
      _currentIndex = newIndex;
      await _playCurrent();
    } else if (_playMode == PlayMode.sequential) {
      // 顺序播放：播放完停止
      if (_currentIndex + 1 < _playlist.length) {
        _currentIndex++;
        await _playCurrent();
      } else {
        await _audioService.stop();
        _isPlaying = false;
        notifyListeners();
      }
    } else {
      // 列表循环：播放下一首，到头则回到第一首
      if (_currentIndex + 1 < _playlist.length) {
        _currentIndex++;
        await _playCurrent();
      } else {
        _currentIndex = 0;
        await _playCurrent();
      }
    }
  }

  Future<void> previousTrack() async {
    if (_playlist.isEmpty) return;

    if (_playMode == PlayMode.shuffle) {
      // 随机播放：随机选择上一首
      final newIndex = Random().nextInt(_playlist.length);
      _currentIndex = newIndex;
      await _playCurrent();
    } else {
      if (_currentIndex - 1 >= 0) {
        _currentIndex--;
        await _playCurrent();
      } else if (_playMode != PlayMode.sequential) {
        // 列表循环：回到最后一首
        _currentIndex = _playlist.length - 1;
        await _playCurrent();
      } else {
        await _playCurrent();
      }
    }
  }

  void removeFromPlaylist(int index) {
    if (index < 0 || index >= _playlist.length) return;

    _playlist.removeAt(index);

    // 调整当前索引
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      // 如果移除的是当前播放的歌曲
      if (_playlist.isEmpty) {
        _currentIndex = -1;
        _audioService.stop();
      } else if (_currentIndex >= _playlist.length) {
        _currentIndex = _playlist.length - 1;
        _playCurrent();
      } else {
        // 播放下一首
        _playCurrent();
      }
    }

    // 同步更新原始播放列表（如果是随机模式）
    if (_playMode == PlayMode.shuffle && _originalPlaylist.isNotEmpty) {
      final removedSongId = _originalPlaylist[index].id;
      _originalPlaylist.removeWhere((s) => s.id == removedSongId);
    }

    notifyListeners();
  }

  /// 清空播放队列
  void clearPlaylist() {
    _playlist.clear();
    _originalPlaylist.clear();
    _currentIndex = -1;
    _audioService.stop();
    notifyListeners();
  }

  /// 重新排序队列
  void reorderPlaylist(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    final song = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, song);

    // 调整当前索引
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    // 同步更新原始播放列表
    if (_playMode == PlayMode.shuffle && _originalPlaylist.isNotEmpty) {
      _originalPlaylist = List.from(_playlist);
    }

    notifyListeners();
  }

  /// 从队列指定位置播放
  void playFromPlaylist(int index) {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    _playCurrent();
  }

  Future<void> seekTo(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
