import 'package:test/test.dart';

import 'package:heron/heron.dart';

main() {
  group('template loading', () {
    test('missing template with friendly error message', () async {
      Templates templates = new Templates();
      await templates.loadDefaults();
      expect(() => templates.renderString('x', {}), throwsA((e) {
        String msg = e.toString();
        return msg.contains('Template not found: x.') &&
            msg.contains('atom-xml');
      }));
    });
  });
}
