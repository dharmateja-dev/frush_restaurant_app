import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restaurant/constant/collection_name.dart';
import 'package:restaurant/constant/constant.dart';
import 'package:restaurant/models/story_model.dart';
import 'package:restaurant/utils/fire_store_utils.dart';

class AddStoryController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<StoryModel> storyModel = StoryModel().obs;
  final ImagePicker imagePicker = ImagePicker();

  RxList<dynamic> mediaFiles = <dynamic>[].obs;
  RxList<dynamic> thumbnailFile = <dynamic>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getStory();
    super.onInit();
  }

  RxDouble videoDuration = 0.0.obs;

  getStory() async {
    await FireStoreUtils.getStory(Constant.userModel!.vendorID.toString()).then(
      (value) {
        if (value != null) {
          storyModel.value = value;

          thumbnailFile.add(storyModel.value.videoThumbnail);
          for (var element in storyModel.value.videoUrl) {
            mediaFiles.add(element);
          }
        }
      },
    );
    await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc('story')
        .get()
        .then((value) {
      videoDuration.value =
          double.parse(value.data()!['videoDuration'].toString());
    });
    isLoading.value = false;
  }
}
/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/
