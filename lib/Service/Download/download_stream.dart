import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:ytdownloader/Models/query_video.dart';
import 'package:ytdownloader/Models/Single%20Track/single_track.dart';
import 'package:ytdownloader/View/Video_Stream_Info/stream_info.dart';

enum StreamType { audio, video }

abstract class DownloadManager {

  Future<void> downloadStream(
      YoutubeExplode yt, QueryVideo video, StreamType type,
      {StreamInfo? singleStream, StreamMerge? merger, String? ffmpegContainer});

  Future<void> removeVideo(SingleTrack video);

  List<SingleTrack> get videos;
}
