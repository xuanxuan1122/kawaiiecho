// pages/playlist_detail.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list.dart';
import '../providers/music.dart';
import '../providers/settings.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'dart:io';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  bool _isAddingSongs = false;
  String _searchQuery = '';  // ✅ 添加搜索关键词状态

  @override
  Widget build(BuildContext context) {
    return Consumer3<ListProvider, MusicProvider, SettingsProvider>(
      builder: (context, listProvider, musicProvider, settings, child) {
        final playlist = listProvider.playlists.firstWhere((p) => p.id == widget.playlistId);
        final songs = listProvider.getSongsByPlaylist(widget.playlistId);
        final allSongs = listProvider.currentList;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(playlist.name),
            backgroundColor: settings.colors.controlBarColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: () {
                  setState(() {
                    _isAddingSongs = !_isAddingSongs;
                    _searchQuery = '';  // 切换时清空搜索
                  });
                },
                tooltip: _isAddingSongs ? '完成' : '添加歌曲',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  settings.colors.controlBarColor.withOpacity(0.9),
                  settings.colors.listBgColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                if (_isAddingSongs)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: settings.colors.controlBarColor.withOpacity(0.8),
                    child: TextField(
                      autofocus: true,
                      style: TextStyle(color: settings.colors.textButtonColor),
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '搜索歌曲添加到歌单...',
                        hintStyle: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.6)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: settings.colors.buttonBgColor.withOpacity(0.5),
                        prefixIcon: Icon(Icons.search, color: settings.colors.textButtonColor),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: settings.colors.textButtonColor, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                Expanded(
                  child: _isAddingSongs
                      ? _buildAddSongsList(context, settings, listProvider, allSongs, playlist)
                      : _buildPlaylistSongsList(context, settings, listProvider, musicProvider, songs),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistSongsList(BuildContext context, SettingsProvider settings, ListProvider listProvider, MusicProvider musicProvider, List<Song> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: settings.colors.textButtonColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              '歌单为空\n点击右上角 + 添加歌曲',
              style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: settings.colors.buttonBgColor,
            backgroundImage: song.coverPath != null ? FileImage(File(song.coverPath!)) : null,
            child: song.coverPath == null
                ? Icon(Icons.music_note, color: settings.colors.textButtonColor, size: 20)
                : null,
          ),
          title: Text(
            song.title,
            style: TextStyle(color: settings.colors.textButtonColor),
          ),
          subtitle: Text(
            song.artist,
            style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.formattedDuration,
                style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.6), fontSize: 12),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: settings.colors.textButtonColor.withOpacity(0.6)),
                onPressed: () {
                  listProvider.removeSongFromPlaylist(widget.playlistId, song.id);
                },
              ),
            ],
          ),
          onTap: () {
            musicProvider.playSong(song, songs);
          },
        );
      },
    );
  }

  Widget _buildAddSongsList(BuildContext context, SettingsProvider settings, ListProvider listProvider, List<Song> allSongs, Playlist playlist) {
    final existingSongIds = playlist.songIds.toSet();

    // ✅ 根据搜索关键词过滤
    List<Song> availableSongs = allSongs.where((s) => !existingSongIds.contains(s.id)).toList();

    if (_searchQuery.isNotEmpty) {
      availableSongs = availableSongs.where((song) {
        return song.title.toLowerCase().contains(_searchQuery) ||
            song.artist.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (availableSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.check_circle,
              size: 64,
              color: settings.colors.textButtonColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? '未找到 "${_searchQuery}" 相关歌曲'
                  : '所有歌曲都已添加到歌单',
              style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: availableSongs.length,
      itemBuilder: (context, index) {
        final song = availableSongs[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: settings.colors.buttonBgColor,
            backgroundImage: song.coverPath != null ? FileImage(File(song.coverPath!)) : null,
            child: song.coverPath == null
                ? Icon(Icons.music_note, color: settings.colors.textButtonColor, size: 20)
                : null,
          ),
          title: Text(
            song.title,
            style: TextStyle(color: settings.colors.textButtonColor),
          ),
          subtitle: Text(
            song.artist,
            style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7)),
          ),
          trailing: IconButton(
            icon: Icon(Icons.add_circle_outline, color: settings.colors.textButtonColor),
            onPressed: () {
              listProvider.addSongToPlaylist(widget.playlistId, song.id);
              setState(() {});
            },
          ),
          onTap: () {
            listProvider.addSongToPlaylist(widget.playlistId, song.id);
            setState(() {});
          },
        );
      },
    );
  }
}
