import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../flagship.dart';

enum RequestType { Post, Get }

class Service {
  static Future<Response> sendHttpRequest(RequestType type, String urlString,
      Map<String, String> headers, Object data,
      {timeoutMs = 2000}) async {
    switch (type) {
      case RequestType.Post:
        {
          Flagship.logger(
              Level.INFO, REQUEST_POST_BODY.replaceFirst("%s", "$data"));
          var url = Uri.parse(urlString);
          var response = await http
              .post(url, body: data, headers: headers)
              .timeout(Duration(milliseconds: timeoutMs));
          return response;
        }
      case RequestType.Get:
      default:
        return Response('error', 0);
    }
  }
}
