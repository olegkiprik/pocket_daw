part of 'piano.dart';

// see daw_with_ffi.h

extension _MainRouteStateExport on MainRouteState {
  Future<int> export(String path) async {
    debugPrint('Export started, preparing sources...');

    ffi.Pointer<ffi.Pointer<ffi.Uint8>> wavSrcs;
    ffi.Pointer<ffi.Uint64> srcLengths;
    ffi.Pointer<ffi.Pointer<ffi.Uint8>> playedArr;
    ffi.Pointer<ffi.Uint64> playedLengths;
    int nrTracks;
    ffi.Pointer<ffi.Uint8> wavOut;

    ffi.Arena allocator = ffi.Arena();

    try {
      wavSrcs = allocator.call(sources.length);

      for (int i = 0; i < sources.length; ++i) {
        wavSrcs[i] = allocator.allocate(sources[i].bytes.length, alignment: 2);
        wavSrcs[i].asTypedList(sources[i].bytes.length).setAll(0, sources[i].bytes);
      }

      srcLengths = allocator.call(sources.length);

      for (int i = 0; i < sources.length; ++i) {
        srcLengths.asTypedList(sources.length)[i] = sources[i].bytes.length;
      }

      playedArr = allocator.call(sources.length);

      for (int i = 0; i < sources.length; ++i) {
        playedArr[i] = allocator.call(recordedNotes[i].length * nrNotes);
        for (int j = 0; j < recordedNotes[i].length; ++j) { 
          playedArr[i].asTypedList(recordedNotes[i].length * nrNotes)
            .setRange(j * nrNotes, (j+1) * nrNotes, 
            recordedNotes[i][j].map((value) { return (value ? 1 : 0); }));
        }
      }

      playedLengths = allocator.call(sources.length);
      playedLengths.asTypedList(sources.length)
        .setAll(0, recordedNotes.map((value) { return value.length; }));
      nrTracks = sources.length;
      wavOut = allocator.allocate(wavHeaderSize + nrSamplesInTrack * 2, alignment: 2);

      debugPrint('Mixing...');
      final result = await ffi.exportWavAsync(
        wavSrcs, srcLengths, playedArr, 
        playedLengths, nrTracks, wavOut);

      if (result == 0) {
        allocator.releaseAll();
        return 0;
      }

    } catch (e) {
      return 0;
    }

    debugPrint('Uploading...');
    final outFile = io.File(path);
    outFile.writeAsBytesSync(wavOut.asTypedList(wavHeaderSize + nrSamplesInTrack * 2));

    allocator.releaseAll();

    debugPrint('Export finished');
    return 1;
  }
}