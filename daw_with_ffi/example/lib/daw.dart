part of 'piano.dart';

extension _MainRouteStateDaw on MainRouteState {
  void startRecording() {
    recording = true;
    preplaying = false;
    pressedNotes.fillRange(0, nrNotes, false);
    if (timer != null && timer!.isActive) {
      timer?.cancel();
    }
    timer = Timer.periodic(
      Duration(milliseconds: stepDurationMs),
      (Timer timer) {
        if (recording && activeTrackIndex != null) {
          if (recordedNotes.length < nrMaxSteps) {
            recordedNotes[activeTrackIndex!].add(List<bool>.from(pressedNotes));
          }
          pressedNotes.fillRange(0, nrNotes, false);
        }
      },
    );
  }

  void preplayTrack() {
    preplaying = true;
    recording = false;
    currentStep = 0;
    if (timer != null && timer!.isActive) {
      timer?.cancel();
    }
    timer = Timer.periodic(
      Duration(milliseconds: stepDurationMs),
      (Timer timer) {
        if (preplaying && activeTrackIndex != null && recordedNotes.isNotEmpty) {
          for (int i = 0; i < nrNotes; ++i) {
            if (currentStep >= recordedNotes[activeTrackIndex!].length) {
              preplaying = false;
              currentStep = 0;
              return;
            }
            if (recordedNotes[activeTrackIndex!][currentStep][i]) {
              playNote(i);
            }
          }
          ++currentStep;
        }
      },
    );
  }

  Future<void> playNote(int index) async {
    if (srcReadyToPlay && players.isNotEmpty) {
      // seek to 0
      await players.elementAt(index).seek(Duration());
      await players.elementAt(index).play();
    }
  }

  Future<void> prepareSource(int index) async {
    srcReadyToPlay = false;
    activeTrackIndex = index;
    if (players.isNotEmpty) {
      for (int i = 0; i < nrNotes; i++) {
        await players[i].dispose();
      }
    }
    players.clear();
    for (int lvl = minNote; lvl <= maxNote; lvl++) {
      final player = au.AudioPlayer();
      final factor = math.exp(lvl / 12.0 / math.log(2));
      await player.setAudioSource(sources[index]);
      await player.setPitch(factor);
      await player.setSpeed(factor);
      players.add(player);
    }
    debugPrint('Preparing source: Ready');
    srcReadyToPlay = true;
  }
}
