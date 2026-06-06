// services/audio_scanner.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import '../models/song.dart';

class AudioScanner {
  static const List<String> supportedExtensions = [
    'mp3', 'flac', 'wav', 'm4a', 'ogg', 'aac', 'opus'
  ];

  /// 扫描目录并缓存（自动管理多目录）
  static Future<List<Song>> scanDirectory(String directoryPath, {bool forceRescan = false}) async {
    final cacheFile = await _getCacheFile(directoryPath);

    // 读取元数据缓存索引
    final index = await _loadIndex();

    // 检查是否需要重新扫描（文件变化检测）
    if (!forceRescan && await cacheFile.exists()) {
      final lastScanTime = index[directoryPath];
      final dirModified = await _getDirectoryLastModified(directoryPath);

      // 如果目录没有变化且缓存存在，直接加载缓存
      if (lastScanTime != null && dirModified != null && lastScanTime >= dirModified) {
        try {
          final jsonStr = await cacheFile.readAsString();
          final List<dynamic> jsonList = json.decode(jsonStr);
          return jsonList.map((json) => Song.fromMap(json)).toList();
        } catch (e) {
          print('读取缓存失败，将重新扫描: $e');
        }
      }
    }

    // 执行扫描
    print('开始扫描目录: $directoryPath');
    final songs = await _scanDirectoryInternal(directoryPath);

    // 保存缓存
    try {
      final jsonList = songs.map((s) => s.toMap()).toList();
      await cacheFile.writeAsString(json.encode(jsonList));

      // 更新索引
      index[directoryPath] = DateTime.now().millisecondsSinceEpoch;
      await _saveIndex(index);
      print('扫描完成: ${songs.length} 首歌曲，已缓存');
    } catch (e) {
      print('保存缓存失败: $e');
    }

    return songs;
  }

  /// 获取目录最后修改时间（用于增量扫描）
  static Future<int?> _getDirectoryLastModified(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return null;

    int latestTime = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.millisecondsSinceEpoch > latestTime) {
          latestTime = stat.modified.millisecondsSinceEpoch;
        }
      } else if (entity is Directory) {
        // 递归获取子目录的最晚修改时间
        final subTime = await _getDirectoryLastModified(entity.path);
        if (subTime != null && subTime > latestTime) {
          latestTime = subTime;
        }
      }
    }
    return latestTime > 0 ? latestTime : null;
  }

  /// 加载缓存索引（记录每个目录的扫描时间）
  static Future<Map<String, int>> _loadIndex() async {
    final indexFile = await _getIndexFile();
    if (await indexFile.exists()) {
      try {
        final jsonStr = await indexFile.readAsString();
        final Map<String, dynamic> map = json.decode(jsonStr);
        return map.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        print('加载索引失败: $e');
      }
    }
    return {};
  }

  /// 保存缓存索引
  static Future<void> _saveIndex(Map<String, int> index) async {
    final indexFile = await _getIndexFile();
    try {
      await indexFile.writeAsString(json.encode(index));
    } catch (e) {
      print('保存索引失败: $e');
    }
  }

  /// 获取索引文件路径
  static Future<File> _getIndexFile() async {
    final cacheDir = await getTemporaryDirectory();
    return File('${cacheDir.path}/scan_index.json');
  }

  /// 获取指定目录的缓存文件路径
  static Future<File> _getCacheFile(String directoryPath) async {
    final cacheDir = await getTemporaryDirectory();
    final safeName = directoryPath.replaceAll('/', '_').replaceAll(':', '_');
    return File('${cacheDir.path}/scan_cache_$safeName.json');
  }

  /// 清除指定目录的缓存
  static Future<void> clearCache(String directoryPath) async {
    final cacheFile = await _getCacheFile(directoryPath);
    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }

    // 从索引中移除
    final index = await _loadIndex();
    index.remove(directoryPath);
    await _saveIndex(index);
  }

  /// 清除所有缓存
  static Future<void> clearAllCache() async {
    final cacheDir = await getTemporaryDirectory();
    final files = await cacheDir.list().toList();
    for (final file in files) {
      if (file.path.contains('scan_cache_') || file.path.contains('scan_index.json')) {
        await file.delete();
      }
    }
  }

  /// 内部扫描实现
  static Future<List<Song>> _scanDirectoryInternal(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return [];

    final List<Song> songs = [];
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase().replaceFirst('.', '');
        if (supportedExtensions.contains(ext)) {
          final song = await _songFromFile(entity);
          songs.add(song);
        }
      }
    }
    return songs;
  }

  /// 从文件读取元数据
  static Future<Song> _songFromFile(File file) async {
    // ... 保持原有实现 ...
    final filePath = file.path;
    final stat = await file.stat();
    final ext = path.extension(filePath).toLowerCase().replaceFirst('.', '');
    final id = filePath.hashCode.toRadixString(36);

    Duration duration = Duration.zero;
    String title = path.basenameWithoutExtension(filePath);
    String artist = '未知艺术家';
    String album = '未知专辑';
    String? coverPath;
    int? trackNumber;
    int? year;

    try {
      final metadata = readMetadata(file, getImage: true);

      if (metadata.title != null && metadata.title!.isNotEmpty) title = metadata.title!;
      if (metadata.artist != null && metadata.artist!.isNotEmpty) artist = metadata.artist!;
      if (metadata.album != null && metadata.album!.isNotEmpty) album = metadata.album!;
      if (metadata.duration != null) duration = metadata.duration!;
      trackNumber = metadata.trackNumber;
      if (metadata.year != null && metadata.year!.year > 0) year = metadata.year!.year;

      if (metadata.pictures != null && metadata.pictures!.isNotEmpty) {
        final firstPicture = metadata.pictures!.first;
        if (firstPicture.bytes != null && firstPicture.bytes!.isNotEmpty) {
          final cacheDir = await getTemporaryDirectory();
          final cacheFileName = '${id}_cover.jpg';
          final cacheFile = File('${cacheDir.path}/$cacheFileName');
          if (!await cacheFile.exists()) {
            await cacheFile.writeAsBytes(firstPicture.bytes!);
          }
          coverPath = cacheFile.path;
        }
      }
    } catch (e) {
      print('读取元数据失败 "$filePath": $e');
    }

    return Song(
      id: id,
      filePath: filePath,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      format: ext,
      size: stat.size,
      lastModified: stat.modified.millisecondsSinceEpoch,
      coverPath: coverPath,
      trackNumber: trackNumber,
      year: year,
    );
  }
}
