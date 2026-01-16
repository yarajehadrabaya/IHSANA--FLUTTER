import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MocaApiService {
  // الروابط الأساسية للسبيسات المدمجة (تأكدي من مطابقتها لحسابك)
  static const String langUrl =
      "https://senior-moca-moca-language-test.hf.space";
  static const String visionUrl =
      "https://senior-moca-moca-vision-test.hf.space";
  static const String attentionUrl =
      "https://senior-moca-moca-attention-test.hf.space";
  static const String memoryUrl =
      "https://senior-moca-moca-memory-test.hf.space";
  static const String fluencyUrl =
      "https://senior-moca-moca-fluency-test.hf.space";
  static const String abstractUrl =
      "https://senior-moca-moca-abstraction-test.hf.space";
  static const String orientUrl =
      "https://senior-moca-moca-orientation-test.hf.space";

  // ---------------------------------------------------------
  // 1. قسم اللغة (Language) - سبيس مدمج
  // ---------------------------------------------------------

  // التسمية (Naming) - ترسل 3 ملفات
  Future<Map<String, dynamic>> checkNaming(List<String> audioPaths) async {
    return await _post(
      url: "$langUrl/naming",
      fieldName: "audios",
      filePaths: audioPaths,
    );
  }

  // الجملة الأولى (باسل) - ترسل ملف واحد ✅
  Future<Map<String, dynamic>> checkSentence1(String audioPath) async {
    return await _post(
      url: "$langUrl/sentence1",
      fieldName: "audio",
      filePaths: [audioPath],
    );
  }

  // ✅ دالة فحص التوصيل التتابعي (TMT) - ترسل ملف JSON
  Future<Map<String, dynamic>> checkTrails(String jsonPath) async {
    return await _post(
      url: "$visionUrl/trails", // الرابط الخاص بسبيس الرؤية الموحد
      fieldName:
          "patient_file", // اسم الحقل المتوقع في الـ FastAPI لسؤال التوصيل
      filePaths: [jsonPath],
    );
  }

  // الجملة الثانية (الهر) - ترسل ملف واحد ✅
  Future<Map<String, dynamic>> checkSentence2(String audioPath) async {
    return await _post(
      url: "$langUrl/sentence2",
      fieldName: "audio",
      filePaths: [audioPath],
    );
  }

  // ---------------------------------------------------------
  // 2. باقي الأقسام (الرؤية، الانتباه، إلخ)
  // ---------------------------------------------------------

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

  // التوجه (Orientation)
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
