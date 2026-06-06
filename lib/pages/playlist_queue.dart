// pages/playlist_queue.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music.dart';
import '../providers/settings.dart';
import '../models/song.dart';
import 'dart:io';
import 'dart:convert';  // 用于 jsonEncode/jsonDecode

class PlaylistQueuePage extends StatelessWidget {
  const PlaylistQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicProvider, SettingsProvider>(
      builder: (context, musicProvider, settings, child) {
        final playlist = musicProvider.playlist;
        final currentIndex = musicProvider.currentIndex;
        final playMode = musicProvider.playMode;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('播放队列'),
            backgroundColor: settings.colors.controlBarColor,
            elevation: 0,
            actions: [
              // 清空队列按钮
              if (playlist.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearDialog(context, musicProvider),
                ),
              // 关闭按钮
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
            child: playlist.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 64,
                          color: settings.colors.textButtonColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '播放队列为空',
                          style: TextStyle(
                            color: settings.colors.textButtonColor.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: playlist.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      musicProvider.reorderPlaylist(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = playlist[index];
                      final isCurrent = index == currentIndex;
                      return Card(
                        key: ValueKey(song.id),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        color: isCurrent
                            ? settings.colors.controlBarColor.withOpacity(0.5)
                            : Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: settings.colors.buttonBgColor,
                            backgroundImage: song.coverPath != null
                                ? FileImage(File(song.coverPath!))
                                : null,
                            child: song.coverPath == null
                                ? Icon(Icons.music_note, color: settings.colors.textButtonColor, size: 20)
                                : null,
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              color: settings.colors.textButtonColor,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            style: TextStyle(
                              color: settings.colors.textButtonColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCurrent)
                                Icon(
                                  Icons.play_arrow,
                                  color: settings.colors.textButtonColor,
                                  size: 20,
                                ),
                              IconButton(
                                icon: Icon(Icons.close, color: settings.colors.textButtonColor.withOpacity(0.6), size: 20),
                                onPressed: () {
                                  musicProvider.removeFromPlaylist(index);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            musicProvider.playFromPlaylist(index);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
          bottomNavigationBar: playlist.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: settings.colors.controlBarColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '共 ${playlist.length} 首',
                        style: TextStyle(color: settings.colors.textButtonColor),
                      ),
                      Row(
                        children: [
                          // 播放模式显示
                          Icon(
                            musicProvider.playModeIcon,
                            color: settings.colors.textButtonColor,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          // 清空队列
                          TextButton(
                            onPressed: () => _showClearDialog(context, musicProvider),
                            child: Text(
                              '清空队列',
                              style: TextStyle(color: settings.colors.textButtonColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, MusicProvider musicProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空队列'),
        content: const Text('确定要清空播放队列吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              musicProvider.clearPlaylist();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
