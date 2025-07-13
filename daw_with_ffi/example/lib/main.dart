import 'package:flutter/material.dart';
import 'piano.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'storage.dart';
import 'track.dart';
import 'timeline.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// https://pub.dev/packages/just_audio_media_kit
void main() {
  // on Linux:
  // apt install libmpv-dev
  JustAudioMediaKit.ensureInitialized(
    linux: true,
  );
  JustAudioMediaKit.mpvLogLevel = MPVLogLevel.debug;
  JustAudioMediaKit.bufferSize = 32 * 1024 * 1024;
  JustAudioMediaKit.title = 'Pocket DAW';
  JustAudioMediaKit.pitch = true;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket DAW',
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: [
        Locale('en'),
        Locale('pl')
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      ),
      routes: {
        '/': (context) => const MainRoute(),
        '/storage': (context) => const StorageRoute(),
        '/track': (context) => const TrackRoute(),
        '/timeline': (context) => const TimelineRoute(),
      },
    );
  }
}