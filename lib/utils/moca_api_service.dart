import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart'; // ✅ ضروري لحفظ ملفات الهاردوير مؤقتاً

class MocaApiService {
  // الروابط الأساسية للسبيسات المدمجة
  static const String langUrl =
      "https://senior-moca2-moca-language-test.hf.space";
  static const String visionUrl =
      "https://senior-moca2-moca-vision-test.hf.space";
  static const String attentionUrl =
      "https://senior-moca2-moca-attention-test.hf.space";
  static const String memoryUrl =
      "https://senior-moca2-moca-memory-test.hf.space";
  static const String fluencyUrl =
      "https://senior-moca2-moca-fluency-test.hf.space";
  static const String abstractUrl =
      "https://senior-moca2-moca-abstraction-test.hf.space";
  static const String orientUrl =
      "https://senior-moca2-moca-orientation-test.hf.space";

  // ---------------------------------------------------------
  // 🚀 الجزء الجديد: التعامل مع الهاردوير (الرازبيري باي)
  // ---------------------------------------------------------

  /// هذه الدالة تجلب الملف من الرازبيري وترسله فوراً للـ API المطلوب
  /// [rpiIp]: عنوان الرازبيري (مثلاً 192.168.1.15)
  /// [taskType]: نوع المهمة "image" أو "audio"
  /// [targetApi]: الدالة التي تريد مناداتها بعد استلام الملف (مثلاً checkClock)
  Future<Map<String, dynamic>> processHardwareTask({
    required String rpiIp,
    required String taskType,
    required String functionName,
    String? extraParam, // لبعض الدوال مثل checkAttention تحتاج نوع الاختبار
  }) async {
    try {
      // 1. طلب الملف من الرازبيري باي
      String hwEndpoint = taskType == "image" ? "/get-image" : "/get-audio";
      var hwResponse = await http.get(
        Uri.parse('http://$rpiIp:8000$hwEndpoint'),
      );

      if (hwResponse.statusCode == 200) {
        // 2. حفظ الملف المستلم مؤقتاً في ذاكرة الموبايل
        final dir = await getTemporaryDirectory();
        String fileName = taskType == "image"
            ? "hw_capture.jpg"
            : "hw_record.wav";
        File tempFile = File('${dir.path}/$fileName');
        await tempFile.writeAsBytes(hwResponse.bodyBytes);

        // 3. توجيه الملف المستلم إلى الـ API المناسب في Hugging Face
        switch (functionName) {
          case 'checkClock':
            return await checkVision(tempFile.path, "clock");
          case 'checkCube':
            return await checkVision(tempFile.path, "cube");
          case 'checkNaming':
            return await checkNaming([tempFile.path]);
          case 'checkAttention':
            return await checkAttention(tempFile.path, extraParam ?? "");
          case 'checkMemory':
            return await checkMemory(tempFile.path);
          case 'checkFluency':
            return await checkFluency(tempFile.path);
          default:
            return {"score": 0, "analysis": "مهمة غير معروفة"};
        }
      } else {
        return {"score": 0, "analysis": "الرازبيري باي لم يستجب بشكل صحيح"};
      }
    } catch (e) {
      return {"score": 0, "analysis": "فشل الاتصال بالهاردوير: $e"};
    }
  }

  // ---------------------------------------------------------
  // 1. قسم اللغة (Language)
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> checkNaming(List<String> audioPaths) async {
    return await _post(
      url: "$langUrl/naming",
      fieldName: "audios",
      filePaths: audioPaths,
    );
  }

  Future<Map<String, dynamic>> checkSentence1(String audioPath) async {
    return await _post(
      url: "$langUrl/sentence1",
      fieldName: "audio",
      filePaths: [audioPath],
    );
  }

  Future<Map<String, dynamic>> checkSentence2(String audioPath) async {
    return await _post(
      url: "$langUrl/sentence2",
      fieldName: "audio",
      filePaths: [audioPath],
    );
  }

  // ---------------------------------------------------------
  // 2. باقي الأقسام
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> checkTrails(String jsonPath) async {
    return await _post(
      url: "$visionUrl/trails",
      fieldName: "patient_file",
      filePaths: [jsonPath],
    );
  }

  Future<Map<String, dynamic>> checkVision(String path, String endpoint) async {
    return await _post(
      url: "$visionUrl/$endpoint",
      fieldName: "image",
      filePaths: [path],
      isImg: true,
    );
  }

  Future<Map<String, dynamic>> checkAttention(String path, String type) async {
    return await _post(
      url: "$attentionUrl/$type",
      fieldName: "audio",
      filePaths: [path],
    );
  }

  Future<Map<String, dynamic>> checkMemory(String path) async {
    return await _post(
      url: "$memoryUrl/check-memory",
      fieldName: "audio",
      filePaths: [path],
    );
  }

  Future<Map<String, dynamic>> checkFluency(String path) async {
    return await _post(
      url: "$fluencyUrl/check-fluency",
      fieldName: "audio",
      filePaths: [path],
    );
  }

  Future<Map<String, dynamic>> checkAbstraction(
    String path,
    int pairNum,
  ) async {
    String endpoint = pairNum == 1 ? "/pair1-transport" : "/pair2-measurement";
    return await _post(
      url: "$abstractUrl$endpoint",
      fieldName: "audio",
      filePaths: [path],
    );
  }

  Future<Map<String, dynamic>> checkOrientation({
    required String place,
    required String city,
    required List<String> audioPaths,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$orientUrl/check-orientation"),
      );
      request.fields['expected_place'] = place;
      request.fields['expected_city'] = city;
      List<String> keys = [
        'audio_weekday',
        'audio_month',
        'audio_year',
        'audio_place',
        'audio_city',
      ];
      for (int i = 0; i < audioPaths.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(keys[i], audioPaths[i]),
        );
      }
      var response = await http.Response.fromStream(await request.send());
      return json.decode(response.body);
    } catch (e) {
      return {"score": 0, "analysis": "خطأ في الاتصال: $e"};
    }
  }

  // 🛠️ دالة مساعدة عامة لإرسال الطلبات
  Future<Map<String, dynamic>> _post({
    required String url,
    required String fieldName,
    required List<String> filePaths,
    bool isImg = false,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      for (var path in filePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            path,
            contentType: isImg
                ? MediaType('image', 'jpeg')
                : MediaType('audio', 'wav'),
          ),
        );
      }
      var res = await http.Response.fromStream(await request.send());
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        return {"score": 0, "analysis": "خطأ سيرفر: ${res.statusCode}"};
      }
    } catch (e) {
      return {"score": 0, "analysis": "خطأ اتصال: $e"};
    }
  }
}
