// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/settings.dart';
import 'providers/list.dart';
import 'providers/music.dart';
import 'pages/home.dart';
import 'package:flutter/services.dart';
import 'dart:ffi';
import 'dart:io';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  String? fileToOpen;
  if (args.isNotEmpty) {
    fileToOpen = args.first;
    print('打开文件: $fileToOpen');
  }

  runApp(MyApp(initialFile: fileToOpen));
}

class MyApp extends StatelessWidget {
  final String? initialFile;

  const MyApp({super.key, this.initialFile});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ListProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider(), lazy: true),
      ],
      child: MaterialApp(
        title: 'KawaiEcho',
        theme: ThemeData(useMaterial3: true),
        debugShowCheckedModeBanner: false,
        home: HomePage(initialFile: initialFile),
      ),
    );
  }
}
