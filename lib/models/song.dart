// models/song.dart
import 'dart:math';
import 'dart:io';

/// 本地歌曲数据模型
class Song {
  /// 唯一标识（基于文件路径的哈希值）
  final String id;

  /// 文件绝对路径（或 URI，跨平台兼容）
  final String filePath;

  /// 歌曲标题（从元数据读取，否则取文件名）
  final String title;

  /// 歌手名称
  final String artist;

  /// 专辑名称
  final String album;

  /// 播放时长
  final Duration duration;

  /// 音频格式（mp3/flac/wav/m4a/ogg 等）
  final String format;

  /// 文件大小（字节）
  final int size;

  /// 文件最后修改时间（毫秒时间戳）
  final int lastModified;

  /// 封面图片路径（本地缓存或嵌入封面提取的临时文件）
  final String? coverPath;

  /// 音轨编号（可选）
  final int? trackNumber;

  /// 发行年份（可选）
  final int? year;

  const Song({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.format,
    required this.size,
    required this.lastModified,
    this.coverPath,
    this.trackNumber,
    this.year,
  });

  /// 从文件路径创建最小模型（占位，等待元数据填充）
  factory Song.fromPath(String filePath) {
    final file = filePath;
    final extension = file.split('.').last.toLowerCase();
    final fileName = file.split(Platform.pathSeparator).last;
    final titleWithoutExt = fileName.replaceFirst(RegExp(r'\.[^.]*$'), '');

    return Song(
      id: _generateId(filePath),
      filePath: filePath,
      title: titleWithoutExt,
      artist: '未知艺术家',
      album: '未知专辑',
      duration: Duration.zero,
      format: extension,
      size: 0,
      lastModified: 0,
      coverPath: null,
      trackNumber: null,
      year: null,
    );
  }

  /// 生成唯一ID（基于文件路径的哈希值）
  static String _generateId(String path) {
    return path.hashCode.toRadixString(36);
  }

  /// 复制并修改
  Song copyWith({
    String? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? format,
    int? size,
    int? lastModified,
    String? coverPath,
    int? trackNumber,
    int? year,
  }) {
    return Song(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      format: format ?? this.format,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      coverPath: coverPath ?? this.coverPath,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
    );
  }

  /// 转换为 Map（用于本地存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'format': format,
      'size': size,
      'lastModified': lastModified,
      'coverPath': coverPath,
      'trackNumber': trackNumber,
      'year': year,
    };
  }

  /// 从 Map 创建
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      duration: Duration(milliseconds: map['durationMs'] as int),
      format: map['format'] as String,
      size: map['size'] as int,
      lastModified: map['lastModified'] as int,
      coverPath: map['coverPath'] as String?,
      trackNumber: map['trackNumber'] as int?,
      year: map['year'] as int?,
    );
  }

  /// 格式化时长显示 (MM:SS)
  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
