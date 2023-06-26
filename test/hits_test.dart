import 'package:flagship/hits/page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Test hits', () {
    test('Page', () {
      Page page = Page(location: "zzzz");
      page.clientId = "clientId";
      page.visitorId = "visitorId";
      expect(page.isValid(), false);

      Page page1 = Page(location: "https://www.google.com/");
      page1.clientId = "clientId";
      page1.visitorId = "visitorId";
      expect(page1.isValid(), true);

      Page page2 = Page(location: "123.121.222.111");
      page2.clientId = "clientId";
      page2.visitorId = "visitorId";
      expect(page2.isValid(), false);
    });
  });
}
