part of 'piano.dart';

extension _MainRouteStateProject on MainRouteState {
  void save(String path) {
    debugPrint('Saving...');
    final outFile = io.File(path);
    final buff = StringBuffer();

    // write number of tracks
    buff.write('${sources.length}\n');
    for (int i = 0; i < sources.length; ++i) {
      debugPrint("Tracks: $i/${sources.length}");

      // write path
      buff.write('${srcPaths[i]}\n');

      // write number of steps
      buff.write('${recordedNotes[i].length}\n');
      
      // write played notes
      for (int j = 0; j < recordedNotes[i].length; ++j) {
        for (int k = 0; k < nrNotes; ++k) {
          buff.write('${recordedNotes[i][j][k]}\n');
        }
      }
    }
    outFile.writeAsStringSync(buff.toString());
    debugPrint('Saved');
  }

  Future<void> load(String path) async {
    debugPrint('Clearing DAW states');

    if (players.isNotEmpty) {
      for (int i = 0; i < nrNotes; i++) {
        await players[i].dispose();
      }
    }

    players.clear();
    srcPaths.clear();
    sources.clear();
    activeTrackIndex = 0;
    recording = false;
    preplaying = false;
    currentStep = 0;
    pressedNotes.fillRange(0, nrNotes, false);
    recordedNotes.clear();

    debugPrint('Loading...');

    try {
      final inFile = io.File(path);
      List<String> data = inFile.readAsLinesSync();
      int index = 0;
      
      // read number of tracks
      int nrSources = int.parse(data[index++]);
      if (nrSources <= 0) {
        debugPrint('Loading failed');
        return;
      }

      for (int i = 0; i < nrSources; ++i) {
        debugPrint("Tracks: $i/$nrSources");

        // read path
        String srcPath = data[index++];
        srcPaths.add(srcPath);
        final srcFile = io.File(srcPath);
        final contents = await srcFile.readAsBytes();
        final source = AudioMemorySource(contents, contents);
        sources.add(source);
        recordedNotes.add(List<List<bool>>.empty(growable: true));

        // read number of steps
        int nrUnits = int.parse(data[index++]);

        // read played notes
        for (int j = 0; j < nrUnits; ++j) {
          recordedNotes[i].add(List<bool>.filled(nrNotes, false));
          for (int k = 0; k < nrNotes; ++k) {
            recordedNotes[i][j][k] = bool.parse(data[index++]);
          }
        }
      }
    } catch (e) {
      debugPrint('Loading failed');
      return;
    }

    debugPrint('Preparing source...');
    await prepareSource(0);
    debugPrint('Loaded');
  }
}