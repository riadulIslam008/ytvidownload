import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:get/get.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:ytdownloader/Models/Muxed%20Track/muxed_track.dart';
import 'package:ytdownloader/Models/Single%20Track/single_track.dart';
import 'package:path/path.dart' as path;
import 'package:ytdownloader/Models/query_video.dart';
import 'package:ytdownloader/Service/Download/download_stream.dart';
import 'package:ytdownloader/Service/Notification/notifications.dart';
import 'package:ytdownloader/View/Video_Stream_Info/stream_info.dart';

class DownloadManagerImpl implements DownloadManager {
  DownloadManagerImpl(this.videoIds, this.videos);

  static final invalidChars = RegExp(r'[\\\/:*?"<>|]');

  @override
  final List<SingleTrack> videos;
  final List<String> videoIds;
  final int _nextId = 0;

  final Map<int, bool> cancelTokens = {};

  int get nextId {
    return _nextId;
  }

  void addVideo(SingleTrack video) {
    final id = 'video_${video.id}';
    videoIds.add(id);
  }

  @override
  Future<void> removeVideo(SingleTrack video) async {
    final id = 'video_${video.id}';

    videoIds.remove(id);
    videos.removeWhere((e) => e.id == video.id);

    final file = File(video.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> getValidPath(String strPath) async {
    final file = File(strPath);
    if (!(await file.exists())) {
      return strPath;
    }
    final basename = path
        .withoutExtension(strPath)
        .replaceFirst(RegExp(r' \([0-9]+\)$'), '');
    final ext = path.extension(strPath);

    var count = 0;

    while (true) {
      final newPath = '$basename (${++count})$ext';
      final file = File(newPath);
      if (await file.exists()) {
        continue;
      }
      return newPath;
    }
  }

  @override
  Future<void> downloadStream(
      YoutubeExplode yt, QueryVideo video, StreamType type,
      {StreamInfo? singleStream,
      StreamMerge? merger,
      String? ffmpegContainer}) async {
    assert(singleStream != null || merger != null);
    assert(merger == null ||
        merger.video != null &&
            merger.audio != null &&
            ffmpegContainer != null);

    if (Platform.isAndroid) {
      final req = await Permission.storage.request();
      if (!req.isGranted) {
        showSnackbar("permissionError");
        return;
      }
    }

    final isMerging = singleStream == null;
    final stream = singleStream ?? merger!.video!;
    final id = nextId;
    final Directory directory = await getDefaultDownloadDir();
    final String saveDir = directory.path;

    if (isMerging) {
//Download Video and Audio File
      processMuxedTrack(
          yt, video, merger!, stream, saveDir, id, ffmpegContainer!);
    } else {
//Download only Audio or Video File
      processSingleTrack(yt, video, stream, saveDir, id, type);
    }
  }

  Future<void> processSingleTrack(
    YoutubeExplode yt,
    QueryVideo video,
    StreamInfo stream,
    String saveDir,
    int id,
    StreamType type,
  ) async {
    final downloadPath = await getValidPath(
        '${path.join(saveDir, video.title.replaceAll(invalidChars, '_'))}${'.${stream.container.name}'}');

    final tempPath = path.join(saveDir, 'Unconfirmed $id.ytdownload');

    final file = File(tempPath);
    final sink = file.openWrite();
    final Stream<List<int>> dataStream = yt.videos.streamsClient.get(stream);

//Download  Stream
    final downloadVideo = SingleTrack(id, downloadPath, video.title,
        bytesToString(stream.size.totalBytes), stream.size.totalBytes, type);

    addVideo(downloadVideo);
    videos.add(downloadVideo);

    // await for (var data in dataStream) {}

    final sub = dataStream
        .listen((data) => handleData(data, sink, downloadVideo),
            onError: (error, __) async {
      showSnackbar("Download Falied", color: Colors.red);
      NotificationApi.showDownloadInfoNotification(icon: "@drawable/ic_downloading",
          title: video.title, body: "Download Failed ");
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.failed;
      downloadVideo.error = error.toString();
    }, onDone: () async {
      final newPath = await cleanUp(sink, file, downloadPath);
      downloadVideo.downloadStatus = DownloadStatus.success;
      downloadVideo.path = newPath!;
      NotificationApi.showDownloadInfoNotification(icon: "@drawable/ic_download_complete",
          title: video.title, body: "Download Complete");
    }, cancelOnError: true);

    downloadVideo.cancelCallback = () async {
      sub.cancel();
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.canceled;

      showSnackbar("cancelDownload(video.title)");
    };

    // showSnackbar("startDownload(video.title");
  }

  Future<void> processMuxedTrack(
      YoutubeExplode yt,
      QueryVideo video,
      StreamMerge merger,
      StreamInfo stream,
      String saveDir,
      int id,
      String ffmpegContainer) async {
    final downloadPath = await getValidPath(
        '${path.join(saveDir, video.title.replaceAll(invalidChars, '_'))}$ffmpegContainer');

//Download Audio File
    final audioTrack = processTrack(yt, merger.audio!, saveDir,
        stream.container.name, video, StreamType.audio);

//Download Video File
    final videoTrack = processTrack(yt, merger.video!, saveDir,
        stream.container.name, video, StreamType.video);

// Muxed Both File
    final muxedTrack = MuxedTrack(
        id,
        downloadPath,
        video.title,
        bytesToString(videoTrack.totalSize + audioTrack.totalSize),
        videoTrack.totalSize + audioTrack.totalSize,
        audioTrack,
        videoTrack);
    muxedTrack.cancelCallback = () {
      audioTrack.cancelCallback!();
      videoTrack.cancelCallback!();

      muxedTrack.downloadStatus = DownloadStatus.canceled;

      //localizations.cancelDownload(video.title);
    };

    Future<void> downloadListener() async {
      muxedTrack.downloadedBytes =
          audioTrack.downloadedBytes + videoTrack.downloadedBytes;
      muxedTrack.downloadPerc =
          (muxedTrack.downloadedBytes / muxedTrack.totalSize * 100).floor();

      if (audioTrack.downloadStatus == DownloadStatus.success &&
          videoTrack.downloadStatus == DownloadStatus.success) {
        muxedTrack.downloadStatus = DownloadStatus.muxing;
        final path = await getValidPath(muxedTrack.path);
        muxedTrack.path = path;
        NotificationApi.showDownloadInfoNotification(icon: "@drawable/ic_download_complete",
            title: video.title, body: "Download Complete");

        final args = [
          '-i',
          audioTrack.path,
          '-i',
          videoTrack.path,
          '-progress',
          '-',
          '-y',
          '-shortest',
          path,
        ];

        mobileFFMPEG(muxedTrack, audioTrack, videoTrack, path, args,
            downloadListener, video);
      }
    }

    audioTrack.addListener(downloadListener);
    videoTrack.addListener(downloadListener);

    addVideo(muxedTrack);
    videos.add(muxedTrack);

    // showSnackbar("startDownload(video.title");
  }

  Future<void> mobileFFMPEG(
      MuxedTrack muxedTrack,
      SingleTrack audioTrack,
      SingleTrack videoTrack,
      String outPath,
      List<String> args,
      VoidCallback downloadListener,
      QueryVideo video) async {
    final ffmpeg = FlutterFFmpeg();
    final id = await ffmpeg.executeAsyncWithArguments(args, (execution) async {
      //killed
      if (execution.returnCode == 255) {
        return;
      }
      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();
    });

    final file = File(outPath);
    var oldSize = -1;

    // Currently the ffmpeg's executionCallback is never called so we have to
    // pool and check if the file is created and written to.
    Future.doWhile(() async {
      if (muxedTrack.downloadStatus == DownloadStatus.canceled) {
        return false;
      }

      if (!(await file.exists())) {
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
      final stat = await file.stat();
      final size = stat.size;
      if (oldSize != size) {
        oldSize = size;
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
      return false;
    }).then((_) async {
      if (muxedTrack.downloadStatus == DownloadStatus.canceled) {
        return;
      }

      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();
    });

    muxedTrack.cancelCallback = () async {
      audioTrack.cancelCallback!();
      videoTrack.cancelCallback!();

      ffmpeg.cancelExecution(id);
      muxedTrack.downloadStatus = DownloadStatus.canceled;
    };
  }

  SingleTrack processTrack(YoutubeExplode yt, StreamInfo stream, String saveDir,
      String container, QueryVideo video, StreamType type) {
    final id = nextId;
    final tempPath =
        path.join(saveDir, 'Unconfirmed $id.ytdownload.$container');

    final file = File(tempPath);
    final sink = file.openWrite();

    final downloadVideo = SingleTrack(id, tempPath, 'Temp$id',
        bytesToString(stream.size.totalBytes), stream.size.totalBytes, type);

    final dataStream = yt.videos.streamsClient.get(stream);
    final sub = dataStream
        .listen((data) => handleData(data, sink, downloadVideo),
            onError: (error, __) async {
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.failed;
      downloadVideo.error = error.toString();

      showSnackbar("failDownload(video.title");
    }, onDone: () async {
      await sink.flush();
      await sink.close();
      downloadVideo.downloadStatus = DownloadStatus.success;
    }, cancelOnError: true);

    downloadVideo.cancelCallback = () async {
      sub.cancel();
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.canceled;
    };
    return downloadVideo;
  }
}

void showSnackbar(String message, {Color color = Colors.green}) =>
    Get.snackbar("Erorr", message, backgroundColor: color);

Future<Directory> getDefaultDownloadDir() async {
  if (Platform.isAndroid) {
    // final paths =
    //     await getExternalStorageDirectories(type: StorageDirectory.downloads);
    // return paths!.first;
    ///storage/emulated/0/Android/data/com.example.ytdownloader/files/Download
    final dir = await DownloadsPath.downloadsDirectory();
    return dir!;
    //'/storage/emulated/0/Download'

  }
  throw UnsupportedError(
      'Platform: ${Platform.operatingSystem} is not supported!');
}

Future<String> getValidPath(String strPath) async {
  final file = File(strPath);
  if (!(await file.exists())) {
    return strPath;
  }
  final basename =
      path.withoutExtension(strPath).replaceFirst(RegExp(r' \([0-9]+\)$'), '');
  final ext = path.extension(strPath);

  var count = 0;

  while (true) {
    final newPath = '$basename (${++count})$ext';
    final file = File(newPath);
    if (await file.exists()) {
      continue;
    }
    return newPath;
  }
}

//Check Download Progress Data
void handleData(List<int> bytes, IOSink sink, SingleTrack video) {
  sink.add(bytes);
  video.downloadedBytes += bytes.length;
  final newProgress = (video.downloadedBytes / video.totalSize * 100).floor();
  video.downloadPerc = newProgress;
  NotificationApi.showNotification(
      title: video.title, progress: video.downloadPerc, icon: "@drawable/ic_downloading");
}

Future<String?> cleanUp(IOSink sink, File file, [String? path]) async {
  await sink.flush();
  await sink.close();
  if (path != null) {
    // ignore: parameter_assignments
    path = await getValidPath(path);
    await file.rename(path);
    return path;
  }
  await file.delete();
  return null;
}
