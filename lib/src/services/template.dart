import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:whatsapp/src/utils/exception.dart';
import 'package:whatsapp/src/utils/request.dart';
import 'package:whatsapp/src/utils/response/whatsapp_response.dart';

class TemplateService {
  final String accessToken;
  final String fromNumberId;
  final Request request;

  TemplateService(this.accessToken, this.fromNumberId, this.request);

  Future<WhatsAppResponse> sendTemplate(
      String phoneNumber,
      String template,
      String language,
      List<Map<String, dynamic>>? placeholder,
      List<Map<String, dynamic>>? headerParameters) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final Map<String, dynamic> body = {
      'messaging_product': 'whatsapp',
      'to': phoneNumber,
      'type': 'template',
      'template': {
        'name': template,
        'language': {'code': language},
        'components': []
      },
    };

    final components =
        body['template']['components'] as List<Map<String, dynamic>>;

    if (headerParameters != null && headerParameters.isNotEmpty) {
      components.add({
        'type': 'header',
        'parameters': headerParameters,
      });
    }

    if (placeholder != null && placeholder.isNotEmpty) {
      components.add({
        'type': 'body',
        'parameters': placeholder,
      });
    }

    var url = '$fromNumberId/messages';
    try {
      final http.Response response =
          await request.postWithResponse(url, headers, body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final WhatsAppResponse parsedResponse =
            WhatsAppResponse.fromJson(responseBody);
        return parsedResponse;
      } else {
        // Throw a more specific exception using the factory constructor
        throw WhatsAppException.fromResponse(response);
      }
    } on FormatException catch (e) {
      // Handle JSON decoding errors specifically
      throw JsonFormatException('Failed to parse JSON response: $e');
    } on http.ClientException catch (e) {
      // Handle network-related errors (e.g., no internet, timeout)
      throw NetworkException('Network error: $e');
    } on WhatsAppException {
      // Re-throw WhatsApp-specific exceptions.
      rethrow;
    } catch (e) {
      // Handle any other unexpected exceptions.
      throw WhatsAppException('An unexpected error occurred: $e');
    }
  }
}
