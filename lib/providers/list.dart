// providers/list.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/audio_scanner.dart';
import '../models/playlist.dart';
import 'dart:convert';  // 用于 jsonEncode/jsonDecode
import 'dart:io';       // 用于 File

class ListProvider extends ChangeNotifier {
  List<Song> _allSongs = [];
  List<Song> _currentList = [];
  String _currentCategory = '所有歌曲';
  final List<String> categories = ['所有歌曲', '艺术家', '专辑', '文件夹', '歌单'];

  bool _isScanning = false;
  List<String> _scannedDirectories = [];

  // ✅ 只保留一份声明（删除重复的）
  String _searchKeyword = '';

  // 搜索控制器（新增）
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  List<Song> get currentList => _currentList;
  String get currentCategory => _currentCategory;
  bool get isScanning => _isScanning;
  List<String> get scannedDirectories => _scannedDirectories;
  String get searchKeyword => _searchKeyword;
  bool get isSearching => _searchKeyword.isNotEmpty;

  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  ListProvider() {
    _loadScannedDirectories();
    _loadPlaylists();

    // 监听搜索框输入变化
    searchController.addListener(() {
      final value = searchController.text;
      if (value.isEmpty) {
        clearSearch();
      } else {
        searchSongs(value);
      }
    });
  }

  // 释放资源
  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // 加载已保存的文件夹列表
  Future<void> _loadScannedDirectories() async {
    final prefs = await SharedPreferences.getInstance();
    final directories = prefs.getStringList('scanned_directories') ?? [];
    _scannedDirectories = List.from(directories);

    if (_scannedDirectories.isNotEmpty) {
      print('加载已保存的文件夹: $_scannedDirectories');
      await _loadAllSongs();
    }
  }

  // 保存文件夹列表
  Future<void> _saveScannedDirectories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('scanned_directories', _scannedDirectories);
  }

  // 加载所有文件夹中的歌曲（合并）
  Future<void> _loadAllSongs() async {
    if (_scannedDirectories.isEmpty) return;

    _isScanning = true;
    notifyListeners();

    final List<Song> allSongs = [];
    for (final dir in _scannedDirectories) {
      try {
        final songs = await AudioScanner.scanDirectory(dir, forceRescan: false);
        allSongs.addAll(songs);
        print('加载 $dir: ${songs.length} 首歌曲');
      } catch (e) {
        print('加载失败 $dir: $e');
      }
    }

    _allSongs = _deduplicateSongs(allSongs);
    _applyFilter();

    _isScanning = false;
    notifyListeners();
    print('总计: ${_allSongs.length} 首歌曲');
  }

  // 歌曲去重
  List<Song> _deduplicateSongs(List<Song> songs) {
    final seen = <String>{};
    return songs.where((song) {
      if (seen.contains(song.filePath)) return false;
      seen.add(song.filePath);
      return true;
    }).toList();
  }

  // 添加新文件夹
  Future<void> addDirectory(String path, {bool forceRescan = false}) async {
    if (_scannedDirectories.contains(path)) {
      print('文件夹已存在: $path');
      return;
    }

    _scannedDirectories.add(path);
    await _saveScannedDirectories();

    _isScanning = true;
    notifyListeners();

    try {
      final songs = await AudioScanner.scanDirectory(path, forceRescan: forceRescan);
      _allSongs.addAll(songs);
      _allSongs = _deduplicateSongs(_allSongs);
      _applyFilter();
      print('添加文件夹成功: $path, 新增 ${songs.length} 首歌曲');
    } catch (e) {
      print('扫描失败: $e');
      _scannedDirectories.remove(path);
      await _saveScannedDirectories();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // 移除文件夹
  Future<void> removeDirectory(String path) async {
    if (!_scannedDirectories.contains(path)) return;

    _scannedDirectories.remove(path);
    await _saveScannedDirectories();
    await _loadAllSongs();
  }

  // 重新扫描所有文件夹
  Future<void> rescanAllDirectories() async {
    if (_scannedDirectories.isEmpty) return;

    _isScanning = true;
    notifyListeners();

    final List<Song> allSongs = [];
    for (final dir in _scannedDirectories) {
      try {
        final songs = await AudioScanner.scanDirectory(dir, forceRescan: true);
        allSongs.addAll(songs);
      } catch (e) {
        print('重新扫描失败 $dir: $e');
      }
    }

    _allSongs = _deduplicateSongs(allSongs);
    _applyFilter();

    _isScanning = false;
    notifyListeners();
    print('重新扫描完成: ${_allSongs.length} 首歌曲');
  }

  // 清空所有文件夹
  Future<void> clearAllDirectories() async {
    _scannedDirectories.clear();
    await _saveScannedDirectories();
    _allSongs = [];
    _currentList = [];
    notifyListeners();
  }

  // 切换分类
  void switchCategory(String category) {
    _currentCategory = category;
    _applyFilter();
  }

  // 搜索歌曲
  void searchSongs(String keyword) {
    _searchKeyword = keyword.trim().toLowerCase();
    _applyFilter();
  }

  // 清除搜索
  void clearSearch() {
    if (_searchKeyword.isNotEmpty) {
      _searchKeyword = '';
      searchController.clear();
      _applyFilter();
    }
  }

  // 应用过滤（搜索 + 分类）
  void _applyFilter() {
    List<Song> filtered = List.from(_allSongs);

    // 搜索过滤
    if (_searchKeyword.isNotEmpty) {
      filtered = filtered.where((song) {
        return song.title.toLowerCase().contains(_searchKeyword) ||
            song.artist.toLowerCase().contains(_searchKeyword);
      }).toList();
    }

    // 分类过滤
    switch (_currentCategory) {
      case '艺术家':
      case '专辑':
      default:
        _currentList = filtered;
    }

    notifyListeners();
  }

  /// 获取按艺术家分组的歌曲
  Map<String, List<Song>> get songsByArtist {
    final map = <String, List<Song>>{};
    for (final song in _allSongs) {
      final artist = song.artist.isNotEmpty ? song.artist : '未知艺术家';
      map.putIfAbsent(artist, () => []).add(song);
    }
    // 对每个艺术家的歌曲按标题排序
    map.forEach((key, value) {
      value.sort((a, b) => a.title.compareTo(b.title));
    });
    return map;
  }

  /// 获取按专辑分组的歌曲
  Map<String, List<Song>> get songsByAlbum {
    final map = <String, List<Song>>{};
    for (final song in _allSongs) {
      final album = song.album.isNotEmpty ? song.album : '未知专辑';
      map.putIfAbsent(album, () => []).add(song);
    }
    // 对每个专辑的歌曲按音轨号或标题排序
    map.forEach((key, value) {
      value.sort((a, b) {
        if (a.trackNumber != null && b.trackNumber != null) {
          return a.trackNumber!.compareTo(b.trackNumber!);
        }
        return a.title.compareTo(b.title);
      });
    });
    return map;
  }

  /// 获取按文件夹分组的歌曲
  Map<String, List<Song>> get songsByFolder {
    final map = <String, List<Song>>{};
    for (final song in _allSongs) {
      // 获取文件所在目录
      final folder = song.filePath.substring(0, song.filePath.lastIndexOf('/'));
      map.putIfAbsent(folder, () => []).add(song);
    }
    return map;
  }

  // 加载保存的歌单
  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getStringList('playlists');
    if (playlistsJson != null) {
      _playlists = playlistsJson
          .map((json) => Playlist.fromMap(jsonDecode(json) as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  // 保存歌单到本地
  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = _playlists
        .map((playlist) => jsonEncode(playlist.toMap()))
        .toList();
    await prefs.setStringList('playlists', playlistsJson);
  }

  // 创建歌单
  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    final newPlaylist = Playlist.create(name.trim());
    _playlists.add(newPlaylist);
    await _savePlaylists();
    notifyListeners();
  }

  // 删除歌单
  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  // 添加歌曲到歌单
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    if (!_playlists[index].songIds.contains(songId)) {
      _playlists[index].songIds.add(songId);
      await _savePlaylists();
      notifyListeners();
    }
  }

  // 从歌单移除歌曲
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    _playlists[index].songIds.remove(songId);
    await _savePlaylists();
    notifyListeners();
  }

  // 获取歌单中的歌曲列表
  List<Song> getSongsByPlaylist(String playlistId) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    return _allSongs.where((song) => playlist.songIds.contains(song.id)).toList();
  }

  // 获取所有歌单名（兼容之前的接口）
  List<String> get playlistNames {
    return _playlists.map((p) => p.name).toList();
  }
}
