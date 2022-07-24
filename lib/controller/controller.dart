import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:ytdownloader/Models/query_video.dart';
import 'package:ytdownloader/View/Video_Stream_Info/stream_info.dart';

class AlertBoxController extends GetxController {
  
  final YoutubeExplode youtubeExplode = YoutubeExplode();
  final StreamMerge streamMerge = StreamMerge();
  final String _url = Get.arguments[0];


  StreamManifest? streamManifest;
  List<StreamInfo>? filteredList;
  QueryVideo? video;

// Make an Obserable emun
  Rx<Filter> filter = Filter.all.obs;

  @override
  void onInit() {
    videoInfo();
    super.onInit();
  }

  Future<void> videoInfo() async {
    await youtubeExplode.videos.get(_url).then((Video value) async {
      video = QueryVideo(value.title, value.id.value, value.author,
          value.duration!, value.thumbnails.highResUrl);

      streamManifest =
          await youtubeExplode.videos.streamsClient.getManifest(video!.id);
      filteredList = filterStream(streamManifest!, filter.value);
      update();
    }).catchError((fun, test) {
      Get.snackbar("Error Message", "Query Error");
    });
  }
}

enum Filter {
  all,
  videoAudio,
  audio,
  video,
}
