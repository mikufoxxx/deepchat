import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'providers/chat_provider.dart';
import 'services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(storage),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 设置系统UI样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    
    // 启用边到边显示
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DeepChat',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.themeColor,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.themeColor,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: themeProvider.followSystem
              ? ThemeMode.system
              : themeProvider.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,
          home: const ChatScreen(),
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.light 
                    ? Brightness.dark 
                    : Brightness.light,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Theme.of(context).brightness == Brightness.light 
                    ? Brightness.dark 
                    : Brightness.light,
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
