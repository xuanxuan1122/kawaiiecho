import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// 平台特定初始化文件
import 'for_android/init.dart' if (dart.library.html) 'for_android/init.dart';
import 'for_linux/init.dart' if (dart.library.io) 'for_linux/init.dart';

// 原有 Providers
import 'providers/settings.dart';
import 'providers/list.dart';
import 'providers/music.dart';
import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    // Android 专用初始化（包括权限、后台服务、音频会话）
    await androidInit();
  } else {
    // Linux 或其他桌面平台初始化
    await linuxInit();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ListProvider()),
        // MusicProvider 现在依赖 AudioService（在 Android 上）或 AudioPlayer（Linux）
        // 注意：MusicProvider 的构造函数需要根据平台注入不同的 audio handler
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: MaterialApp(
        title: 'KawaiiEcho',
        theme: ThemeData(useMaterial3: true),
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
    );
  }
}
