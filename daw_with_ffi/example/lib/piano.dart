import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:daw_with_ffi/daw_with_ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:just_audio/just_audio.dart' as au;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'constants.dart';
import 'audio_memory.dart';
part 'export_audio.dart';
part 'daw_project.dart';
part 'daw.dart';

class MainRoute extends StatefulWidget {
  const MainRoute({super.key});

  @override
  State<MainRoute> createState() => MainRouteState();
}

class MainRouteState extends State<MainRoute> {
  final srcPaths = List<String>.empty(growable: true);
  final sources = List<AudioMemorySource>.empty(growable: true);
  final players = List<au.AudioPlayer>.empty(growable: true);
  final pressedNotes = List<bool>.filled(nrNotes, false, growable: true);
  final recordedNotes = List<List<List<bool>>>.empty(growable: true);
  int? activeTrackIndex;
  bool srcReadyToPlay = true;
  bool recording = false;
  bool preplaying = false;
  int currentStep = 0;
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mainMenuTitle),
      ),
      body: Column(
        children: [
          // Show keys
          Expanded(
            flex: 1,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nrNotes ~/ 2,
              itemBuilder: (context, index) => TextButton(
                onPressed: () async {
                  pressedNotes[index] = true;
                  await playNote(index);
                },
                child: Text("$index"),
              ),
              separatorBuilder: (context, _) => const SizedBox(width: 2),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nrNotes - nrNotes ~/ 2,
              itemBuilder: (context, index) => TextButton(
                onPressed: () async {
                  pressedNotes[index + nrNotes ~/ 2] = true;
                  await playNote(index + nrNotes ~/ 2);
                },
                child: Text("${index + nrNotes ~/ 2}"),
              ),
              separatorBuilder: (context, _) => const SizedBox(width: 2),
            ),
          ),
          // Menu
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_right_alt_outlined),
                  tooltip: AppLocalizations.of(context)!.selectTrackTooltip,
                  onPressed: () async {
                    final selected = await Navigator.pushNamed(
                            context, '/track', arguments: {
                              'nrSources': sources.length,
                              'srcPaths': srcPaths,
                            })
                        as int?;
                    if (selected != null && selected >= 0) {
                      await prepareSource(selected);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle),
                  tooltip: AppLocalizations.of(context)!.startRecordingTooltip,
                  onPressed: () {
                    startRecording();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.pause_circle),
                  tooltip: AppLocalizations.of(context)!.stopRecordingTooltip,
                  onPressed: () {
                    recording = false;
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: AppLocalizations.of(context)!.playTrackTooltip,
                  onPressed: () {
                    preplayTrack();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  tooltip: AppLocalizations.of(context)!.stopPlayingTooltip,
                  onPressed: () {
                    preplaying = false;
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.grid_3x3),
                  tooltip: AppLocalizations.of(context)!.showTimelineTooltip,
                  onPressed: () async {
                    if (activeTrackIndex != null && recordedNotes.isNotEmpty) {
                      await Navigator.pushNamed(context, '/timeline',
                          arguments: {
                            'nrSteps': recordedNotes[activeTrackIndex!].length,
                            'isCurrentStep': currentStep,
                            'track': recordedNotes[activeTrackIndex!]
                          });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.my_library_music_outlined),
                  tooltip: AppLocalizations.of(context)!.exportTooltip,
                  onPressed: () async {
                    if (recordedNotes.isEmpty) {
                      return;
                    }

                    final pathTmp = await Navigator.pushNamed(
                        context, '/storage',
                        arguments: {'title': AppLocalizations.of(context)!.selectDirectoryTitle});
                    final path = pathTmp as io.FileSystemEntity?;
                    if (path == null) {
                      return;
                    }
                    int success = await export('${path.parent.path}/daw_out.wav');
                    if (0 == success) {
                      debugPrint("Failed");
                    } 
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: AppLocalizations.of(context)!.saveProjectTooltip,
                  onPressed: () async {
                    if (recordedNotes.isEmpty) {
                      return;
                    }

                    final fileTmp = await Navigator.pushNamed(
                        context, '/storage',
                        arguments: {'title': AppLocalizations.of(context)!.selectDirectoryTitle});
                    final file = fileTmp as io.FileSystemEntity?;
                    if (file == null) {
                      return;
                    }
                    save('${file.parent.path}/daw_out.txt');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.text_snippet),
                  tooltip: AppLocalizations.of(context)!.loadProjectTooltip,
                  onPressed: () async {
                    if (!srcReadyToPlay) {
                      return;
                    }
                    final pathTmp = await Navigator.pushNamed(
                        context, '/storage',
                        arguments: {'title': AppLocalizations.of(context)!.selectDawFileTitle});
                    final file = pathTmp as io.FileSystemEntity?;
                    if (file == null) {
                      return;
                    }
                    await load(file.path);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: IconButton(
        tooltip: AppLocalizations.of(context)!.newSourceTooltip,
        onPressed: () async {
          final fileTmp = await Navigator.pushNamed(context, '/storage',
              arguments: {'title': AppLocalizations.of(context)!.selectWavFileTitle});
          final fileEntity = fileTmp as io.FileSystemEntity?;
          if (fileEntity == null) {
            return;
          }
          final file = io.File(fileEntity.path);
          final contents = await file.readAsBytes();
          final source = AudioMemorySource(List<int>.from(contents), contents);
          sources.add(source);
          srcPaths.add(fileEntity.path);
          recordedNotes.add(List<List<bool>>.empty(growable: true));
          await prepareSource(sources.length - 1);
        },
        icon: const Icon(Icons.storage),
      ),
    );
  }
}

