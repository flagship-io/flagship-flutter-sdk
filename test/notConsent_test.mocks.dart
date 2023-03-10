// Mocks generated by Mockito 5.3.2 from annotations
// in flagship/test/notConsent_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:flagship/api/service.dart' as _i3;
import 'package:http/http.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeClient_0 extends _i1.SmartFake implements _i2.Client {
  _FakeClient_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeResponse_1 extends _i1.SmartFake implements _i2.Response {
  _FakeResponse_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [Service].
///
/// See the documentation for Mockito's code generation for more information.
class MockService extends _i1.Mock implements _i3.Service {
  MockService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.Client get httpClient => (super.noSuchMethod(
        Invocation.getter(#httpClient),
        returnValue: _FakeClient_0(
          this,
          Invocation.getter(#httpClient),
        ),
      ) as _i2.Client);
  @override
  set httpClient(_i2.Client? _httpClient) => super.noSuchMethod(
        Invocation.setter(
          #httpClient,
          _httpClient,
        ),
        returnValueForMissingStub: null,
      );
  @override
  _i4.Future<_i2.Response> sendHttpRequest(
    _i3.RequestType? type,
    String? urlString,
    Map<String, String>? headers,
    Object? data, {
    dynamic timeoutMs = 2000,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendHttpRequest,
          [
            type,
            urlString,
            headers,
            data,
          ],
          {#timeoutMs: timeoutMs},
        ),
        returnValue: _i4.Future<_i2.Response>.value(_FakeResponse_1(
          this,
          Invocation.method(
            #sendHttpRequest,
            [
              type,
              urlString,
              headers,
              data,
            ],
            {#timeoutMs: timeoutMs},
          ),
        )),
      ) as _i4.Future<_i2.Response>);
}
