import 'package:json_annotation/json_annotation.dart';
import 'package:ytdownloader/Models/Single%20Track/single_track.dart';
import 'package:ytdownloader/Service/Download/download_stream.dart';

part 'muxed_track.g.dart';

@JsonSerializable()
class MuxedTrack extends SingleTrack {
  final SingleTrack audio;
  final SingleTrack video;

  @JsonKey()
  @override
  // ignore: overridden_fields
  final StreamType streamType;

  MuxedTrack(int id, String path, String title, String size, int totalSize,
      this.audio, this.video,
      {this.streamType = StreamType.video})
      : super(id, path, title, size, totalSize, streamType);

  factory MuxedTrack.fromJson(Map<String, dynamic> json) =>
      _$MuxedTrackFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MuxedTrackToJson(this);
}