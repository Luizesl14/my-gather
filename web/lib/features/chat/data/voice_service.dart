import "dart:js_interop";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:record/record.dart";
import "package:web/web.dart" as web;

// Records a voice note in the browser, uploads it to the backend and returns
// the served URL. Web-only (uses MediaRecorder via the `record` package).
class VoiceRecorder {
  VoiceRecorder(this._token);

  final String _token;
  final AudioRecorder _rec = AudioRecorder();
  DateTime? _startedAt;

  bool get isRecording => _startedAt != null;

  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    await _rec.start(const RecordConfig(encoder: AudioEncoder.opus), path: "voice");
    _startedAt = DateTime.now();
    return true;
  }

  /// Stops recording, uploads the audio and returns its URL + duration.
  Future<({String url, int durationMs})?> stopAndUpload() async {
    final blobUrl = await _rec.stop();
    final ms = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inMilliseconds;
    _startedAt = null;
    if (blobUrl == null) return null;

    final bytes = await _blobBytes(blobUrl);
    if (bytes.isEmpty) return null;

    final dio = Dio(BaseOptions(
      baseUrl: "http://localhost:3000",
      headers: {"Authorization": "Bearer $_token"},
    ));
    final res = await dio.post<Map<String, dynamic>>(
      "/uploads/voice",
      data: Stream<List<int>>.fromIterable([bytes]),
      options: Options(
        contentType: "audio/webm",
        headers: {Headers.contentLengthHeader: bytes.length},
      ),
    );
    return (url: res.data!["url"] as String, durationMs: ms);
  }

  Future<void> cancel() async {
    await _rec.stop();
    _startedAt = null;
  }

  void dispose() => _rec.dispose();

  static Future<Uint8List> _blobBytes(String blobUrl) async {
    final resp = await web.window.fetch(blobUrl.toJS).toDart;
    final buffer = await resp.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }
}
