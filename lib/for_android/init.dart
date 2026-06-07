// for_android/init.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';

/// 占位初始化（在 runApp 之前调用，不做实际工作）
Future<void> androidInit() async {
  print('Android init placeholder');
}

/// 真正的 Android 功能初始化，在 runApp 之后调用
Future<void> initAndroidFeatures() async {
  await _requestPermissions();
  await _initAudioService();
}

Future<void> _requestPermissions() async {
  // 请求存储权限（Android 10 及以下）
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
  // Android 13+ 需要单独的音频权限
  if (await Permission.audio.isDenied) {
    await Permission.audio.request();
  }
}

Future<void> _initAudioService() async {
  await AudioService.init(
    builder: () => AndroidAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.kawaiiecho.channel.audio',
      androidNotificationChannelName: 'KawaiiEcho 音乐播放',
      androidNotificationIcon: 'drawable/ic_notification',
      androidShowNotificationBadge: true,
      androidNotificationOngoing: true,   // 注意参数名
    ),
  );
}
