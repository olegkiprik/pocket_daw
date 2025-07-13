// see dart_with_ffi.c
const int minNote = -12;
const int maxNote = 12;
const int nrNotes = 25;
const int stepDurationMs = 50;
const int nrMaxSteps = 12000;
const int dawSampleRateHz = 44100;
const int wavHeaderSize = 44;
const int nrSamplesInTrack = dawSampleRateHz *
  nrMaxSteps * stepDurationMs ~/ 1000;