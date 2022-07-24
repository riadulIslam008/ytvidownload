import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ytdownloader/Service/Download/download_stream.dart';

part 'single_track.g.dart';

enum DownloadStatus { downloading, success, failed, muxing, canceled }

@JsonSerializable()
class SingleTrack extends ChangeNotifier {
  final int id;
  final String title;
  final String size;
  final int totalSize;
  @JsonKey(required: false, defaultValue: StreamType.video)
  final StreamType streamType;

  String _path;

  int _downloadPerc = 0;
  DownloadStatus _downloadStatus = DownloadStatus.downloading;
  int _downloadedBytes = 0;
  String _error = '';

  // ignore: unnecessary_getters_setters
  String get path => _path;

  int get downloadPerc => _downloadPerc;

  DownloadStatus get downloadStatus => _downloadStatus;

  int get downloadedBytes => _downloadedBytes;

  String get error => _error;

  set path(String path) {
    _path = path;
  }

  set downloadPerc(int value) {
    _downloadPerc = value;

    // _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadStatus(DownloadStatus value) {
    _downloadStatus = value;

    //  _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadedBytes(int value) {
    _downloadedBytes = value;

    //  _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set error(String value) {
    _error = value;
    //  _prefs?.setString('video_$id', json.encode(this));

    notifyListeners();
  }

  @JsonKey(ignore: true)
  VoidCallback? cancelCallback;

  SingleTrack(this.id, String path, this.title, this.size, this.totalSize,
      this.streamType)
      : _path = path;

    factory SingleTrack.fromJson(Map<String, dynamic> json) =>
      _$SingleTrackFromJson(json);

  Map<String, dynamic> toJson() => _$SingleTrackToJson(this);

  void cancelDownload() {
    if (cancelCallback == null) {
      debugPrint('Tried to cancel an uncancellable video');
      return;
    }
    cancelCallback!();
  }
}