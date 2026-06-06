// models/playlist.dart
import 'song.dart';
import 'dart:convert';  // 用于 jsonEncode/jsonDecode
import 'dart:io';       // 用于 File

class Playlist {
  final String id;
  final String name;
  final List<String> songIds;  // 存储歌曲ID
  final String? coverPath;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    this.coverPath,
    required this.createdAt,
  });

  factory Playlist.create(String name) {
    return Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
      coverPath: null,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
      'coverPath': coverPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      songIds: List<String>.from(map['songIds']),
      coverPath: map['coverPath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Playlist copyWith({
    String? name,
    List<String>? songIds,
    String? coverPath,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt,
    );
  }
}
