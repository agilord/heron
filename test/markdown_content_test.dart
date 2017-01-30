import 'package:heron/src/data.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownContent', () {
    test('can parse empty source', () {
      var src = '';
      expect(() {
        return new MarkdownContent.parseSource(src);
      },
          allOf(
            returnsNormally,
            isNotNull,
          ));
    });

    test('empty source field check', () {
      var src = '';
      var content = new MarkdownContent.parseSource(src);
      expect(content.header.asMap, allOf(isNotNull, hasLength(0)));
      expect(content.markdown, '');
    });

    test('can parse header', () {
      var src = '''
---
field: value
---
      ''';
      var content = new MarkdownContent.parseSource(src);
      expect(content.header.asMap,
          allOf(hasLength(1), containsPair('field', 'value')));
    });

    test('can parse header with WS chars in front', () {
      var src = '''
  ---
field: value
---
      ''';
      var content = new MarkdownContent.parseSource(src);
      expect(content.header.asMap,
          allOf(hasLength(1), containsPair('field', 'value')));
    });

    test('allows starting meta with more than 3 ---', () {
      var src = '''
-----
field: value
---
      ''';
      var content = new MarkdownContent.parseSource(src);
      expect(content.header.asMap,
          allOf(hasLength(1), containsPair('field', 'value')));
    });

    test('allows ending meta with more than 3 ---', () {
      var src = '''
---
field: value
-----
      ''';
      var content = new MarkdownContent.parseSource(src);
      expect(content.header.asMap,
          allOf(hasLength(1), containsPair('field', 'value')));
    });

    test('optional header is merged', () {
      test('can parse header with WS chars in front', () {
        var src = '''
---
field: value
---
      ''';
        var data = new Data.fromMap(<String, String>{'another': 'keyvalue'});
        var content = new MarkdownContent.parseSource(src, header: data);
        expect(
            content.header.asMap,
            allOf(hasLength(2), containsPair('field', 'value'),
                containsPair('another', 'keyvalue')));
      });
    });
  });
}
