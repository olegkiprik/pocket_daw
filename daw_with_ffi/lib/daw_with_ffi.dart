
import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'daw_with_ffi_bindings_generated.dart';

Future<int> exportWavAsync(
    ffi.Pointer<ffi.Pointer<ffi.Uint8>> wavSrcs,
    ffi.Pointer<ffi.Uint64> srcLengths,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>> playedArr,
    ffi.Pointer<ffi.Uint64> playedLengths,
    int nrTracks,
    ffi.Pointer<ffi.Uint8> wavOut,
    ) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextExportRequestId++;
  final _ExportRequest request = 
    _ExportRequest(requestId, wavSrcs, srcLengths, playedArr,
                   playedLengths, nrTracks, wavOut);
  final Completer<int> completer = Completer<int>();
  _exportRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

const String _libName = 'daw_with_ffi';

/// The dynamic library in which the symbols for [DawWithFfiBindings] can be found.
final ffi.DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final DawWithFfiBindings _bindings = DawWithFfiBindings(_dylib);

/// A request to compute `export_wav`.
///
/// Typically sent from one isolate to another.
class _ExportRequest {
  final int id;
  final ffi.Pointer<ffi.Pointer<ffi.Uint8>> wavSrcs;
  final ffi.Pointer<ffi.Uint64> srcLengths;
  final ffi.Pointer<ffi.Pointer<ffi.Uint8>> playedArr;
  final ffi.Pointer<ffi.Uint64> playedLengths;
  final int nrTracks;
  final ffi.Pointer<ffi.Uint8> wavOut;

  const _ExportRequest(this.id, this.wavSrcs, this.srcLengths, this.playedArr,
                       this.playedLengths, this.nrTracks, this.wavOut);
}

/// A response with the result of `export_wav`.
///
/// Typically sent from one isolate to another.
class _ExportResponse {
  final int id;
  final int result;

  const _ExportResponse(this.id, this.result);
}

/// Counter to identify [_ExportRequest]s and [_ExportResponse]s.
int _nextExportRequestId = 0;

/// Mapping from [_ExportRequest] `id`s to the completers corresponding
/// to the correct future of the pending request.
final Map<int, Completer<int>> _exportRequests = <int, Completer<int>>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is _ExportResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<int> completer = _exportRequests[data.id]!;
        _exportRequests.remove(data.id);
        completer.complete(data.result);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) async {
    final ReceivePort helperReceivePort = ReceivePort()
      ..listen((dynamic data) {
        // On the helper isolate listen to requests and respond to them.
        if (data is _ExportRequest) {
          final int result =
            _bindings.export_wav(data.wavSrcs, data.srcLengths, data.playedArr,
              data.playedLengths, data.nrTracks, data.wavOut);
          final _ExportResponse response = _ExportResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}();
