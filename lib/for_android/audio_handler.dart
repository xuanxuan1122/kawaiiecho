import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/song.dart';

class AndroidAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = -1;

  AndroidAudioHandler() {
    _init();
  }

  void _init() {
    // 合并多个流，用于更新 playbackState
    _player.playerStateStream
        .map((state) => state.processingState)
        .distinct()
        .listen((_) => _updatePlaybackState());

    _player.positionStream.listen((_) => _updatePlaybackState());
    _player.playingStream.listen((_) => _updatePlaybackState());

    // 播放完成自动下一首
    _player.playerStateStream
        .where((state) => state.processingState == ProcessingState.completed)
        .listen((_) => skipToNext());
  }

  void _updatePlaybackState() {
    final playing = _player.playing;
    final index = _player.currentIndex;
    final song = index != null && index < _playlist.length ? _playlist[index] : null;

    // 更新播放状态（不包含 mediaItem）
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _processingStateToAudioProcessingState(_player.processingState),
      playing: playing,
      updatePosition: _player.position,
      queueIndex: index,
    ));

    // 单独更新媒体项（用于通知栏显示）
    if (song != null) {
      final mediaItem = MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        artUri: song.coverPath != null ? Uri.file(song.coverPath!) : null,
      );
      this.mediaItem.add(mediaItem);
    } else {
      // 可选：清空媒体项
      this.mediaItem.add(null);
    }
  }

  AudioProcessingState _processingStateToAudioProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return AudioProcessingState.loading;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // 设置播放列表并开始播放
  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    _playlist = songs;
    final audioSources = songs.map((song) => AudioSource.uri(Uri.file(song.filePath))).toList();
    await _player.setAudioSource(ConcatenatingAudioSource(children: audioSources), initialIndex: startIndex);
    await _player.play();
    // 手动更新一次状态，确保通知栏立即刷新
    _updatePlaybackState();
  }

  // ==================== AudioService 接口实现 ====================

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_playlist.isNotEmpty) {
      // 循环到第一首
      await _player.seek(Duration.zero, index: 0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      // 已经在第一首，从头播放
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> seekTo(Duration position) => _player.seek(position);

  @override
  Future<void> addQueueItem(MediaItem mediaItem) {
    // 可选实现，暂不需要
    return super.addQueueItem(mediaItem);
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) {
    // 可选实现，暂不需要
    return super.removeQueueItem(mediaItem);
  }
}
