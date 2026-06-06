// pages/playlist_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list.dart';
import '../providers/settings.dart';
import '../models/playlist.dart';
import 'dart:convert';  // 用于 jsonEncode/jsonDecode
import 'dart:io';       // 用于 File
import '../models/song.dart';
import 'playlist_detail.dart';

class PlaylistManagerPage extends StatefulWidget {
  const PlaylistManagerPage({super.key});

  @override
  State<PlaylistManagerPage> createState() => _PlaylistManagerPageState();
}

class _PlaylistManagerPageState extends State<PlaylistManagerPage> {
  final TextEditingController _newPlaylistController = TextEditingController();

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: _newPlaylistController,
          decoration: const InputDecoration(
            hintText: '歌单名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _newPlaylistController.text.trim();
              if (name.isNotEmpty) {
                Provider.of<ListProvider>(context, listen: false).createPlaylist(name);
                _newPlaylistController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ListProvider, SettingsProvider>(
      builder: (context, listProvider, settings, child) {
        final playlists = listProvider.playlists;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('歌单管理'),
            backgroundColor: settings.colors.controlBarColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showCreateDialog,
                tooltip: '新建歌单',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
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
            child: playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 64,
                          color: settings.colors.textButtonColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无歌单\n点击右上角 + 创建歌单',
                          style: TextStyle(
                            color: settings.colors.textButtonColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final songs = listProvider.getSongsByPlaylist(playlist.id);
                      Song? firstWithCover;
                      for (final song in songs) {
                        if (song.coverPath != null) {
                          firstWithCover = song;
                          break;
                        }
                      }
                      final coverPath = firstWithCover?.coverPath;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: settings.colors.buttonBgColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: settings.colors.buttonBgColor,
                            backgroundImage: coverPath != null ? FileImage(File(coverPath)) : null,
                            child: coverPath == null
                                ? Icon(Icons.playlist_play, color: settings.colors.textButtonColor)
                                : null,
                          ),
                          title: Text(
                            playlist.name,
                            style: TextStyle(
                              color: settings.colors.textButtonColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${songs.length} 首歌曲',
                            style: TextStyle(color: settings.colors.textButtonColor.withOpacity(0.7)),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: settings.colors.textButtonColor.withOpacity(0.6)),
                            onPressed: () {
                              _showDeleteDialog(context, listProvider, playlist.id);
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistDetailPage(playlistId: playlist.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, ListProvider listProvider, String playlistId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除歌单'),
        content: const Text('确定要删除这个歌单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              listProvider.deletePlaylist(playlistId);
              Navigator.pop(context);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
