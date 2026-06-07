// for_android/init.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import 'audio_handler.dart';

/// Android 专用初始化：权限 + 音频会话 + 后台服务
Future<void> androidInit() async {
  // 1. 请求权限
  await _requestPermissions();

  // 2. 设置音频会话（处理音频焦点，例如被电话中断后自动恢复）
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());

  // 3. 启动后台音频服务（必须在 runApp 之前）
  await _initAudioService();

  print('Android initialization complete');
}

Future<void> _requestPermissions() async {
  // Android 13+ 需要音频权限
  if (await Permission.audio.isDenied) {
    await Permission.audio.request();
  }
  // Android 10 及以下需要存储权限
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
  // Android 11+ 可选的管理外部存储权限（用于全盘扫描，一般不需要）
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

Future<void> _initAudioService() async {
  // 这里需要你的自定义 AudioHandler 实现（例如 AndroidAudioHandler）
  // 具体实现参考后文
  await AudioService.init(
    builder: () => AndroidAudioHandler(),   // 你需要创建的类
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.kawaiiecho.channel.audio',
      androidNotificationChannelName: 'KawaiiEcho 音乐播放',
      androidNotificationIcon: 'drawable/ic_notification',
      androidShowNotificationBadge: true,
      androidNotificationOngoing: true,
      // 可选：通知栏点击后启动 Activity
      androidNotificationClickStartsActivity: true,
    ),
  );
}
