// pages/home.dart
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/settings.dart';
import '../providers/list.dart';
import '../providers/music.dart';
import '../models/song.dart';
import 'settings.dart';
import 'playlist_queue.dart';
import 'playlist_manager.dart';
import 'playlist_detail.dart';

class HomePage extends StatefulWidget {
  final String? initialFile;

  const HomePage({super.key, this.initialFile});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openFile(widget.initialFile!);
      });
    }
  }

  Future<void> _openFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件不存在: $filePath')),
        );
      }
      return;
    }

    const supportedExtensions = ['mp3', 'flac', 'wav', 'm4a', 'ogg', 'aac', 'opus'];
    final extension = filePath.split('.').last.toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('不支持的音频格式: $extension')),
        );
      }
      return;
    }

    final directory = file.parent.path;
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    if (!listProvider.scannedDirectories.contains(directory)) {
      await listProvider.addDirectory(directory);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final songs = listProvider.currentList;
    Song? song;
    try {
      song = songs.firstWhere((s) => s.filePath == filePath);
    } catch (_) {
      // 没找到精确匹配，尝试按标题匹配
      final fileName = filePath.split('/').last.split('.').first;
      try {
        song = songs.firstWhere((s) => s.title == fileName);
      } catch (_) {
        song = songs.isNotEmpty ? songs.first : null;
      }
    }

    if (song != null && mounted) {
      musicProvider.playSong(song, songs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正在播放: ${song.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SettingsProvider, ListProvider, MusicProvider>(
      builder: (context, settings, listProvider, musicProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: settings.backgroundImagePath != null
                    ? (settings.backgroundImagePath!.startsWith('http')
                        ? NetworkImage(settings.backgroundImagePath!)
                        : AssetImage(settings.backgroundImagePath!) as ImageProvider)
                    : const NetworkImage('https://picsum.photos/id/100/1080/2400'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildTopBar(context, settings, listProvider),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildMiddleGlassPanel(context, settings, listProvider),
                  ),
                  const SizedBox(height: 12),
                  _buildBottomControlBar(context, settings, musicProvider),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: settings.searchBarBlur, sigmaY: settings.searchBarBlur),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: settings.colors.searchBarColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: TextField(
                    controller: listProvider.searchController,
                    focusNode: listProvider.searchFocusNode,
                    style: TextStyle(color: settings.colors.textButtonColor),
                    decoration: InputDecoration(
                      hintText: '搜索歌名或艺术家',
                      hintStyle: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      suffixIcon: listProvider.isSearching
                          ? IconButton(
                              icon: Icon(Icons.close, color: settings.colors.textButtonColor, size: 20),
                              onPressed: () => listProvider.clearSearch(),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildCircleIcon(context, Icons.folder_open, '添加文件夹', settings,
              onTap: () => _showFolderInputDialog(context, settings, listProvider)),
          _buildCircleIcon(context, Icons.playlist_play, '歌单管理', settings,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistManagerPage()))),
          const SizedBox(width: 8),
          _buildCircleIcon(context, Icons.refresh, '刷新', settings,
              onTap: () => _refreshSongs(context, listProvider)),
          const SizedBox(width: 8),
          _buildCircleIcon(context, Icons.settings, '设置', settings,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(settingsProvider: settings)))),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(BuildContext context, IconData icon, String tooltip, SettingsProvider settings,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => debugPrint('点击了 $tooltip'),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: settings.searchBarBlur, sigmaY: settings.searchBarBlur),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: settings.colors.buttonBgColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: settings.colors.textButtonColor, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleGlassPanel(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: settings.panelBlur, sigmaY: settings.panelBlur),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: settings.colors.listBgColor.withOpacity(0.35),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildOptionsRow(context, settings, listProvider),
                const SizedBox(height: 16),
                Expanded(child: _buildCategoryContent(context, settings, listProvider)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsRow(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    const options = ["所有歌曲", "艺术家", "专辑", "文件夹", "歌单"];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, index) {
          final isSelected = listProvider.currentCategory == options[index];
          return GestureDetector(
            onTap: () => listProvider.switchCategory(options[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? settings.colors.controlBarColor : settings.colors.buttonBgColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(options[index],
                  style: TextStyle(color: settings.colors.textButtonColor, fontWeight: FontWeight.w500, fontSize: 15)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    switch (listProvider.currentCategory) {
      case '艺术家':
        return _buildArtistView(context, settings, listProvider);
      case '专辑':
        return _buildAlbumView(context, settings, listProvider);
      case '文件夹':
        return _buildFolderView(context, settings, listProvider);
      case '歌单':
        return _buildPlaylistView(context, settings, listProvider);
      default:
        return _buildSongList(context, settings, listProvider);
    }
  }

  // ==================== 艺术家视图 ====================
  Widget _buildArtistView(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    final artists = listProvider.songsByArtist;
    if (artists.isEmpty) return _buildEmptyView(settings, '暂无艺术家');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: artists.keys.length,
      itemBuilder: (context, index) {
        final artistName = artists.keys.elementAt(index);
        final songs = artists[artistName]!;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: settings.colors.buttonBgColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: settings.colors.controlBarColor,
              child: Icon(Icons.person, color: settings.colors.textButtonColor),
            ),
            title: Text(artistName,
                style: TextStyle(color: settings.colors.textButtonColor, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${songs.length} 首歌曲',
                style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7))),
            children: songs
                .map((song) => _buildCategorySongItem(context, song, settings, listProvider, categorySongs: songs))
                .toList(),
          ),
        );
      },
    );
  }

  // ==================== 专辑视图 ====================
  Widget _buildAlbumView(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    final albums = listProvider.songsByAlbum;
    if (albums.isEmpty) return _buildEmptyView(settings, '暂无专辑');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: albums.keys.length,
      itemBuilder: (context, index) {
        final albumName = albums.keys.elementAt(index);
        final songs = albums[albumName]!;
        String? coverPath;
        for (final s in songs) {
          if (s.coverPath != null) {
            coverPath = s.coverPath;
            break;
          }
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: settings.colors.buttonBgColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: settings.colors.buttonBgColor,
              backgroundImage: coverPath != null ? FileImage(File(coverPath)) : null,
              child: coverPath == null ? Icon(Icons.album, color: settings.colors.textButtonColor) : null,
            ),
            title: Text(albumName,
                style: TextStyle(color: settings.colors.textButtonColor, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis),
            subtitle: Text('${songs.length} 首歌曲',
                style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7))),
            children: songs
                .map((song) => _buildCategorySongItem(context, song, settings, listProvider, categorySongs: songs))
                .toList(),
          ),
        );
      },
    );
  }

  // ==================== 文件夹视图 ====================
  Widget _buildFolderView(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    final folders = listProvider.songsByFolder;
    if (folders.isEmpty) return _buildEmptyView(settings, '暂无文件夹');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: folders.keys.length,
      itemBuilder: (context, index) {
        final folderPath = folders.keys.elementAt(index);
        final folderName = folderPath.split('/').last;
        final songs = folders[folderPath]!;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: settings.colors.buttonBgColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: settings.colors.controlBarColor,
              child: Icon(Icons.folder, color: settings.colors.textButtonColor),
            ),
            title: Text(folderName,
                style: TextStyle(color: settings.colors.textButtonColor, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis),
            subtitle: Text('${songs.length} 首歌曲\n$folderPath',
                style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7), fontSize: 11),
                overflow: TextOverflow.ellipsis),
            children: songs
                .map((song) => _buildCategorySongItem(context, song, settings, listProvider, categorySongs: songs))
                .toList(),
          ),
        );
      },
    );
  }

  // ==================== 歌单视图 ====================
  Widget _buildPlaylistView(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    final playlists = listProvider.playlists;
    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add, size: 64, color: settings.colors.textButtonColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('暂无歌单\n点击右上角歌单管理创建',
                style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7)), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final songs = listProvider.getSongsByPlaylist(playlist.id);
        String? coverPath;
        for (final s in songs) {
          if (s.coverPath != null) {
            coverPath = s.coverPath;
            break;
          }
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: settings.colors.buttonBgColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: settings.colors.buttonBgColor,
              backgroundImage: coverPath != null ? FileImage(File(coverPath)) : null,
              child: coverPath == null ? Icon(Icons.playlist_play, color: settings.colors.textButtonColor) : null,
            ),
            title: Text(playlist.name,
                style: TextStyle(color: settings.colors.textButtonColor, fontWeight: FontWeight.bold)),
            subtitle: Text('${songs.length} 首歌曲',
                style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7))),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PlaylistDetailPage(playlistId: playlist.id))),
          ),
        );
      },
    );
  }

  // ==================== 所有歌曲列表 ====================
  Widget _buildSongList(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    if (listProvider.isScanning) return const Center(child: CircularProgressIndicator());
    if (listProvider.isSearching && listProvider.currentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: settings.colors.textButtonColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('未找到 "${listProvider.searchKeyword}" 相关歌曲',
                style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7)), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (listProvider.currentList.isEmpty) return _buildEmptyView(settings, '暂无歌曲，请添加音乐文件夹');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: listProvider.currentList.length,
      itemBuilder: (context, index) =>
          _buildSongItem(context, listProvider.currentList[index], settings, listProvider),
    );
  }

  // ==================== 歌曲项（全部歌曲列表） ====================
  Widget _buildSongItem(BuildContext context, Song song, SettingsProvider settings, ListProvider listProvider) {
    return ListTile(
      onTap: () => Provider.of<MusicProvider>(context, listen: false).playSong(song, listProvider.currentList),
      leading: CircleAvatar(
        radius: 23,
        backgroundColor: settings.colors.buttonBgColor,
        backgroundImage: song.coverPath != null ? FileImage(File(song.coverPath!)) : null,
        child: song.coverPath == null ? Icon(Icons.music_note, color: settings.colors.textButtonColor) : null,
      ),
      title: Text(song.title,
          style: TextStyle(color: settings.colors.textButtonColor, fontSize: 16, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist,
          style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7), fontSize: 13),
          overflow: TextOverflow.ellipsis),
      trailing: Text(song.formattedDuration,
          style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.6), fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      dense: true,
    );
  }

  // ==================== 分类视图歌曲项 ====================
  Widget _buildCategorySongItem(BuildContext context, Song song, SettingsProvider settings, ListProvider listProvider,
      {required List<Song> categorySongs}) {
    return ListTile(
      onTap: () => Provider.of<MusicProvider>(context, listen: false).playSong(song, categorySongs),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: settings.colors.buttonBgColor,
        backgroundImage: song.coverPath != null ? FileImage(File(song.coverPath!)) : null,
        child: song.coverPath == null ? Icon(Icons.music_note, color: settings.colors.textButtonColor, size: 18) : null,
      ),
      title: Text(song.title,
          style: TextStyle(color: settings.colors.textButtonColor, fontSize: 14), overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist,
          style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7), fontSize: 12),
          overflow: TextOverflow.ellipsis),
      trailing: Text(song.formattedDuration,
          style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.6), fontSize: 11)),
      dense: true,
    );
  }

  // ==================== 空状态视图 ====================
  Widget _buildEmptyView(SettingsProvider settings, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 64, color: settings.colors.textButtonColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  // ==================== 底部控制栏 ====================
  Widget _buildBottomControlBar(BuildContext context, SettingsProvider settings, MusicProvider musicProvider) {
    final currentSong = musicProvider.currentSong;
    final isPlaying = musicProvider.isPlaying;
    final position = musicProvider.position;
    final duration = musicProvider.duration;
    final playMode = musicProvider.playMode;
    final playModeIcon = musicProvider.playModeIcon;
    final playModeHint = musicProvider.playModeHint;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 96,
      decoration: BoxDecoration(color: settings.colors.controlBarColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: settings.colors.buttonBgColor,
                  backgroundImage:
                      currentSong?.coverPath != null ? FileImage(File(currentSong!.coverPath!)) : null,
                  child: currentSong?.coverPath == null ? Icon(Icons.music_note, color: settings.colors.textButtonColor) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currentSong?.title ?? '未播放',
                            style: TextStyle(color: settings.colors.textButtonColor, fontSize: 16, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text(currentSong?.artist ?? '',
                            style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.8), fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                Tooltip(
                  message: playModeHint,
                  child: IconButton(
                    icon: Icon(playModeIcon, color: settings.colors.textButtonColor, size: 24),
                    onPressed: musicProvider.togglePlayMode,
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.skip_previous, color: settings.colors.textButtonColor, size: 28),
                    onPressed: musicProvider.previousTrack),
                IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: settings.colors.textButtonColor, size: 32),
                    onPressed: musicProvider.togglePlayPause),
                IconButton(
                    icon: Icon(Icons.skip_next, color: settings.colors.textButtonColor, size: 28),
                    onPressed: musicProvider.nextTrack),
                IconButton(
                    icon: Icon(Icons.queue_music, color: settings.colors.textButtonColor, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistQueuePage()))),
              ],
            ),
          ),
          if (duration.inMilliseconds > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SizedBox(
                height: 20,
                child: Slider(
                  value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                  max: duration.inMilliseconds.toDouble(),
                  activeColor: settings.colors.textButtonColor,
                  inactiveColor: settings.colors.textButtonColor.withOpacity(0.3),
                  onChanged: (value) => musicProvider.seekTo(Duration(milliseconds: value.toInt())),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== 文件夹选择对话框 ====================
  void _showFolderInputDialog(BuildContext context, SettingsProvider settings, ListProvider listProvider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加音乐文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入要扫描的文件夹绝对路径：'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '/home/yourname/Music', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            if (listProvider.scannedDirectories.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text('已添加的文件夹：', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...listProvider.scannedDirectories.map((dir) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.folder, size: 20),
                    title: Text(dir, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                      onPressed: () {
                        listProvider.removeDirectory(dir);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已移除: $dir')));
                        _showFolderInputDialog(context, settings, listProvider);
                      },
                    ),
                  )),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          ElevatedButton(
            onPressed: () async {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在扫描，请稍候...')));
                await listProvider.addDirectory(path);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('扫描完成，共 ${listProvider.currentList.length} 首歌曲')));
              }
            },
            child: const Text('添加并扫描'),
          ),
        ],
      ),
    );
  }

  void _refreshSongs(BuildContext context, ListProvider listProvider) async {
    if (listProvider.scannedDirectories.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在重新扫描所有文件夹...')));
      await listProvider.rescanAllDirectories();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('刷新完成，共 ${listProvider.currentList.length} 首歌曲')));
    } else {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _showFolderInputDialog(context, settings, listProvider);
    }
  }
}
