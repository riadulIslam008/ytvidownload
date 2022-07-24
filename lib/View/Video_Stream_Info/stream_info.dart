import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:ytdownloader/Core/app_assets.dart';
import 'package:ytdownloader/Models/Single%20Track/single_track.dart';
import 'package:ytdownloader/Service/Download/download_impl.dart';
import 'package:ytdownloader/Service/Download/download_stream.dart';
import 'package:ytdownloader/controller/controller.dart';

class VideoByteInfo extends StatelessWidget {
 const VideoByteInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AlertBoxController>(
      init: AlertBoxController(),
      builder: (controller) {
        return (controller.streamManifest == null &&
                controller.filteredList == null && controller.video == null)
            ?  Center(child: Lottie.asset(AppAssets.downloadLoading,height: 200))
            : AlertDialog(
                contentPadding: const EdgeInsets.only(top: 9),
                title: Text(
                  controller.video!.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
                content: SizedBox(
                  height: Get.height * 0.80,
                  width: Get.width * 0.80,
                  child: ListView.builder(
                    itemCount: controller.filteredList!.length,
                    itemBuilder: (context, index) {
                      final stream = controller.filteredList![index];
                      if (stream is MuxedStreamInfo) {
                        return MaterialButton(
                          onPressed: () async {
                            final Directory directory =
                                await getDefaultDownloadDir();

                            final DownloadManager downloadManager =
                                DownloadManagerImpl([
                              controller.video!.id
                            ], [
                              SingleTrack(
                                  0,
                                  controller.video!.title,
                                  directory.path,
                                  bytesToString(stream.size.totalBytes),
                                  stream.size.totalBytes,
                                  StreamType.video),
                            ]);
                            downloadManager.downloadStream(
                                controller.youtubeExplode,
                                controller.video!,
                                StreamType.video,
                                singleStream: stream);
                            Get.back();
                          },
                          child: ListTile(
                            subtitle: Text(
                                '${stream.qualityLabel}- ${stream.videoCodec} | ${stream.audioCodec}'),
                            title: Text(
                                'Video + Audio (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                          ),
                        );
                      }
                      if (stream is VideoOnlyStreamInfo) {
                        return MaterialButton(
                          onLongPress: () {
                            controller.streamMerge.video = stream;
                          },
                          onPressed: () {
                            // controller.downloadManager.downloadStream(
                            //     controller.yt, video, StreamType.video,
                            //     singleStream: stream);
                          },
                          child: ListTile(
                            subtitle: Text(
                                '${stream.videoQualityLabel} - ${stream.videoCodec}'),
                            title: Text(
                                'Video Only (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                            trailing: stream == controller.streamMerge.video
                                ? const Icon(Icons.done)
                                : null,
                          ),
                        );
                      }
                      if (stream is AudioOnlyStreamInfo) {
                        return MaterialButton(
                          onLongPress: () {
                            controller.streamMerge.audio = stream;
                          },
                          onPressed: () {
                            // controller.downloadManager.downloadStream(
                            //     controller.yt, video, StreamType.audio,
                            //     singleStream: stream);
                          },
                          child: ListTile(
                            subtitle: Text(
                                '${stream.audioCodec} | Bitrate: ${stream.bitrate}'),
                            title: Text(
                                'Audio Only (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                            trailing: stream == controller.streamMerge.audio
                                ? const Icon(Icons.done)
                                : null,
                          ),
                        );
                      }
                      return ListTile(
                          title: Text(
                              '${stream.container} ${stream.runtimeType}'));
                    },
                  ),
                ),
                actions: <Widget>[
                  OutlinedButton(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all<EdgeInsets>(
                              const EdgeInsets.all(20))),
                      onPressed: () => Get.back(),
                      child: const Text('Go Back')),
                ],
              );
      },
    );
  }
}

List<StreamInfo> filterStream(StreamManifest manifest, Filter filter) {
  switch (filter) {
    case Filter.all:
      return manifest.streams.toList(growable: false);
    case Filter.videoAudio:
      return manifest.muxed.toList(growable: false);
    case Filter.audio:
      return manifest.audioOnly.toList(growable: false);
    case Filter.video:
      return manifest.videoOnly.toList(growable: false);
  }
}

class StreamMerge extends ChangeNotifier {
  AudioOnlyStreamInfo? _audio;

  AudioOnlyStreamInfo? get audio => _audio;

  set audio(AudioOnlyStreamInfo? audio) {
    _audio = audio;
    notifyListeners();
  }

  VideoOnlyStreamInfo? _video;

  VideoOnlyStreamInfo? get video => _video;

  set video(VideoOnlyStreamInfo? video) {
    _video = video;
    notifyListeners();
  }

  StreamMerge();
}

String bytesToString(int bytes) {
  final totalKiloBytes = bytes / 1024;
  final totalMegaBytes = totalKiloBytes / 1024;
  final totalGigaBytes = totalMegaBytes / 1024;

  String getLargestSymbol() {
    if (totalGigaBytes.abs() >= 1) {
      return 'GB';
    }
    if (totalMegaBytes.abs() >= 1) {
      return 'MB';
    }
    if (totalKiloBytes.abs() >= 1) {
      return 'KB';
    }
    return 'B';
  }

  num getLargestValue() {
    if (totalGigaBytes.abs() >= 1) {
      return totalGigaBytes;
    }
    if (totalMegaBytes.abs() >= 1) {
      return totalMegaBytes;
    }
    if (totalKiloBytes.abs() >= 1) {
      return totalKiloBytes;
    }
    return bytes;
  }

  return '${getLargestValue().toStringAsFixed(2)} ${getLargestSymbol()}';
}
