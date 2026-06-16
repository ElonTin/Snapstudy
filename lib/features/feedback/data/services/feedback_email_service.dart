import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:snapstudy/core/env/env_config.dart';

/// Gửi feedback qua EmailJS API (không cần backend).
/// Tài liệu: https://www.emailjs.com/docs/rest-api/send/
class FeedbackEmailService {
  static const _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  final Dio _dio;

  FeedbackEmailService() : _dio = Dio();

  /// Gửi email feedback.
  ///
  /// [feedbackType] — loại phản hồi (Bug, Góp ý, Khen ngợi, Khác).
  /// [message] — nội dung chi tiết.
  /// [imageFiles] — tối đa 3 file ảnh đính kèm (tùy chọn).
  /// [platform] — tên nền tảng (iOS/Android/etc).
  Future<void> send({
    required String feedbackType,
    required String message,
    List<File> imageFiles = const [],
    String platform = 'unknown',
  }) async {
    if (!EnvConfig.isEmailJsConfigured) {
      throw Exception(
        'EmailJS chưa được cấu hình. Vui lòng thêm EMAILJS_SERVICE_ID, '
        'EMAILJS_TEMPLATE_ID và EMAILJS_PUBLIC_KEY vào file .env',
      );
    }

    // Chuyển ảnh sang base64 HTML để nhúng vào nội dung email
    final imagesHtml = await _buildImagesHtml(imageFiles);

    final payload = {
      'service_id': EnvConfig.emailJsServiceId,
      'template_id': EnvConfig.emailJsTemplateId,
      'user_id': EnvConfig.emailJsPublicKey,
      'template_params': {
        'feedback_type': feedbackType,
        'message': message,
        'images_html': imagesHtml,
        'platform': platform,
        'app_version': '1.0.0',
        'sent_at': DateTime.now().toIso8601String(),
      },
    };

    try {
      final response = await _dio.post(
        _apiUrl,
        data: jsonEncode(payload),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gửi email thất bại (HTTP ${response.statusCode}): ${response.data}',
        );
      }
    } on DioException catch (e) {
      debugPrint('[FeedbackEmail] DioException: ${e.message}');
      throw Exception(_friendlyError(e));
    }
  }

  /// Tải các file ảnh lên tmpfiles.org và trả về chuỗi HTML chứa link trực tiếp đến ảnh.
  Future<String> _buildImagesHtml(List<File> files) async {
    if (files.isEmpty) return '<p><em>Không có ảnh đính kèm.</em></p>';

    final buffer = StringBuffer();
    int index = 1;

    // Chạy tải lên song song để tối ưu hóa thời gian
    final uploadFutures = files.take(3).map((file) async {
      try {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
        });

        // Đặt timeout 15 giây cho mỗi ảnh tránh bị treo khi mạng yếu
        final response = await _dio.post(
          'https://tmpfiles.org/api/v1/upload',
          data: formData,
          options: Options(
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data['data'];
          if (data != null && data['url'] != null) {
            final rawUrl = data['url'] as String;
            // Chuyển URL preview thành URL xem trực tiếp (thêm /dl/ vào sau domain)
            // Ví dụ: https://tmpfiles.org/123/image.jpg -> https://tmpfiles.org/dl/123/image.jpg
            final directUrl = rawUrl.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
            return directUrl;
          }
        }
        return null;
      } catch (e) {
        debugPrint('[FeedbackEmail] Lỗi tải ảnh lên tmpfiles.org: $e');
        return null;
      }
    }).toList();

    final urls = await Future.wait(uploadFutures);

    for (final url in urls) {
      if (url != null) {
        buffer.write(
          '<div style="margin-bottom:16px;">'
          '<p style="margin:0 0 4px;font-size:13px;color:#555;">'
          '<strong>Ảnh đính kèm $index (Xem trực tiếp):</strong> <a href="$url" target="_blank">$url</a>'
          '</p>'
          '<img src="$url" style="max-width:100%;max-height:300px;border-radius:8px;border:1px solid #ddd;display:block;margin-top:6px;" />'
          '</div>',
        );
      } else {
        buffer.write(
          '<p style="color:#e53935;font-size:13px;"><em>[Lỗi] Không thể tải lên ảnh $index (Mạng yếu hoặc lỗi server tải ảnh tạm thời).</em></p>',
        );
      }
      index++;
    }

    return buffer.toString();
  }

  String _friendlyError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Hết thời gian kết nối. Kiểm tra mạng và thử lại.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Không có kết nối mạng. Vui lòng thử lại.';
    }
    return 'Gửi email thất bại: ${e.message ?? 'Lỗi không xác định'}';
  }
}
