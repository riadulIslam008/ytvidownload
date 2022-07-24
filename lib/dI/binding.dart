import 'package:get/get.dart';
import 'package:ytdownloader/controller/controller.dart';

class Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AlertBoxController>(() => AlertBoxController(), fenix: true);
  }
}
