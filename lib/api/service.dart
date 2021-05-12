import 'package:http/http.dart' as http;
import 'package:http/http.dart';

enum RequestType { Post, Get }

class Service {
  static Future<Response> sendHttpRequest(RequestType type, String urlString,
      Map<String, String> headers, Object data,
      {timeoutMs = 2000}) async {
    switch (type) {
      case RequestType.Post:
        {
          print("################# Post: $urlString #####################");
          print("################# Body of the post $data #################");
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
