import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chat_message.dart';
import 'bluetooth_repository.dart';
import 'local_storage_repository.dart';
import 'bluetooth_bloc.dart';
import 'chat_bloc.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ChatMessageAdapter());

  await Hive.openBox<ChatMessage>('blue_mesh_history');
  await Hive.openBox('user_profile_box');
  await Hive.openBox<ChatMessage>('offline_message_queue');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => BluetoothRepository(),
        ),
        RepositoryProvider(
          create: (context) => LocalStorageRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => BluetoothBloc(
              context.read<BluetoothRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ChatBloc(
              btRepository: context.read<BluetoothRepository>(),
              storageRepository: context.read<LocalStorageRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Blue Mesh',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0B0F14), // Dark tactical slate
            cardColor: const Color(0xFF141C24),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FF66),
              secondary: Color(0xFF00E5FF),
              surface: Color(0xFF141C24),
              error: Color(0xFFFF2A5F),
            ),
            fontFamily: 'RobotoMono',
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}