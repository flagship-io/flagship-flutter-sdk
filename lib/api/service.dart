import 'dart:async';

import 'package:flagship/flagship_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../flagship.dart';

enum RequestType { Post, Get }

class Service {
  http.Client httpClient;

  Service(this.httpClient);

  Future<Response> sendHttpRequest(RequestType type, String urlString, Map<String, String> headers, Object data,
      {timeoutMs = TIMEOUT}) async {
    switch (type) {
      case RequestType.Post:
        {
          Flagship.logger(Level.INFO, REQUEST_POST_BODY.replaceFirst("%s", "$data"));
          var url = Uri.parse(urlString);
          try {
            var response = await this
                .httpClient
                .post(url, body: data, headers: headers)
                .timeout(Duration(milliseconds: timeoutMs));
            return response;
          } on TimeoutException catch (e) {
            Flagship.logger(Level.INFO, REQUEST_TIMEOUT.replaceFirst("%s", urlString));
            return Response('$e', 408);
          } on Error catch (e) {
            Flagship.logger(Level.INFO, REQUEST_ERROR.replaceFirst("%s", urlString));
            return Response("$e", 400);
          }
        }
      case RequestType.Get:
      default:
        return Response('Error', 400);
    }
  }
}
