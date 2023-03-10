import 'dart:async';
import 'dart:io';

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
  Future<Response> sendHttpRequest(RequestType type, String urlString,
      Map<String, String> headers, Object? data,
      {timeoutMs = TIMEOUT}) async {
    var url = Uri.parse(urlString);
    switch (type) {
      case RequestType.Post:
        {
          Flagship.logger(Level.INFO, data.toString(), isJsonString: true);
          try {
            var response = await this
                .httpClient
                .post(url, body: data, headers: headers)
                .timeout(Duration(milliseconds: timeoutMs));
            return response;
          } on TimeoutException catch (e) {
            Flagship.logger(
                Level.INFO, REQUEST_TIMEOUT.replaceFirst("%s", urlString));
            return Response(e.toString(), 408);
          } on Error catch (e) {
            Flagship.logger(
                Level.INFO, REQUEST_ERROR.replaceFirst("%s", urlString));
            return Response(e.toString(), 400);
          } on SocketException catch (error) {
            Flagship.logger(
                Level.INFO, REQUEST_ERROR.replaceFirst("%s", error.toString()));
            return Response(error.toString(), 400);
          } on Exception catch (e) {
            return Response(e.toString(), 511);
          }
        }
      case RequestType.Get:
        try {
          var response = await this.httpClient.get(url, headers: headers);
          return response;
        } on Error catch (e) {
          return Response(e.toString(), 400);
        }
      default:
        return Response('Error', 400);
    }
  }
}

/// Refractor later with rich code errors
