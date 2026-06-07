// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'for_android/init.dart' if (dart.library.html) 'for_android/init.dart';
import 'for_linux/init.dart' if (dart.library.io) 'for_linux/init.dart';
import 'providers/settings.dart';
import 'providers/list.dart';
import 'providers/music.dart';
import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await androidInit();               // 占位，不做事
    runApp(const MyApp());
  } else {
    await linuxInit();
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ListProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider(), lazy: true),
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
