import 'dart:typed_data';
import 'package:just_audio/just_audio.dart' as au;

class AudioMemorySource extends au.StreamAudioSource {
  final List<int> ints;
  final Uint8List bytes;
  AudioMemorySource(this.ints, this.bytes);

  @override
  Future<au.StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= ints.length;
    return au.StreamAudioResponse(
      sourceLength: ints.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(ints.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}