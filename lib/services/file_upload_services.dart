import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // اختيار صورة من المعرض
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<String?> uploadImage({
    required XFile imageFile,
    required String userId,
    required String fileType,
  }) async {
    try {
      if (!isValidImageFile(imageFile)) {
        throw Exception('نوع الملف غير مدعوم');
      }

      final file = File(imageFile.path);
      if (!isValidFileSize(file)) {
        throw Exception('حجم الملف كبير جداً. الحد الأقصى 10MB');
      }

      final fileName = '${fileType}_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final fullFileName = '$fileName$fileExtension';

      final bool isTemp = userId.startsWith('temp_');

      Reference storageRef;
      if (isTemp) {
        storageRef = _storage
            .ref()
            .child('pharmacy_requests_uploads')
            .child(userId)
            .child(fileType)
            .child(fullFileName);
      } else {
        storageRef = _storage
            .ref()
            .child('pharmacies')
            .child(userId)
            .child('documents')
            .child(fileType)
            .child(fullFileName);
      }

      final UploadTask uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: $progress%');
      });

      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('File uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('فشل التحميل: ${snapshot.state}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // حذف ملف من Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      if (fileUrl.isNotEmpty && fileUrl.startsWith('http')) {
        Reference ref = _storage.refFromURL(fileUrl);
        await ref.delete();
        print('File deleted successfully: $fileUrl');
      }
    } catch (e) {
      print('Error deleting file: $e');
      throw e;
    }
  }

  // التحقق من صحة ملف الصورة
  bool isValidImageFile(XFile? file) {
    if (file == null) return false;

    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    String extension = path.extension(file.path).toLowerCase();

    return validExtensions.contains(extension);
  }

  // التحقق من حجم الملف
  bool isValidFileSize(File file, {int maxSizeInMB = 10}) {
    try {
      final sizeInBytes = file.lengthSync();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      return sizeInMB <= maxSizeInMB;
    } catch (e) {
      return false;
    }
  }
}