@TestOn('vm')
import 'dart:io';
import 'package:heron/src/data.dart';
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';

void main() {
  group('Data', () {
    test('can invoke default constructor', () {
      expect(() => new Data(), returnsNormally);
    });

    test('default constructor creates empty data', () {
      var data = new Data();
      expect(data.asMap, allOf(hasLength(0)));
    });
    test('can invoke fromYaml constructor', () {
      expect(() => new Data.fromYaml(''), returnsNormally);
    });
    test('fromYaml parses yaml doc and sets vals', () {
      var yaml = '''
some: value
''';
      var data = new Data.fromYaml(yaml);
      expect(data.asMap, allOf(hasLength(1), containsPair('some', 'value')));
    });
    group('loading from file', () {
      List<File> fileList;
      setUp(() {
        schedule(() async {
          setupSandbox(cleanUpAfterTests: !EnvVars.NOCLEANUP);
          fileList = await d.dir('testData', [
            d.file('d.yaml', 'some: val'),
            d.file('d.yml', 'some: val'),
            d.file('d.json', '{"some":"val"}'),
            d.file('d.md', '---\nsome: val\n---\n'),
          ]).create();
        });
      });

      test('can load data from yaml', () {
        schedule(() {
          var data = Data.loadFile(fileList[0].path, mustExist: true);
          expect(
              data,
              completion(
                  asDataMap(allOf(hasLength(1), containsPair('some', 'val')))));
        });
      });

      test('can load data from yml', () {
        schedule(() {
          var data = Data.loadFile(fileList[1].path, mustExist: true);
          expect(
              data,
              completion(
                  asDataMap(allOf(hasLength(1), containsPair('some', 'val')))));
        });
      });
      test('can load data from json', () {
        schedule(() {
          var data = Data.loadFile(fileList[2].path, mustExist: true);
          expect(
              data,
              completion(
                  asDataMap(allOf(hasLength(1), containsPair('some', 'val')))));
        });
      });
      test('can load data from md', () {
        schedule(() {
          var data = Data.loadFile(fileList[3].path, mustExist: true);
          expect(
              data,
              completion(
                  asDataMap(allOf(hasLength(1), containsPair('some', 'val')))));
        });
      });
    });
  });
}

class _DataAsMapMatcher extends Matcher {
  final Matcher _matcher;

  const _DataAsMapMatcher([this._matcher]);

  @override
  Description describe(Description description) =>
      description.add('is Data that matches ').addDescriptionOf(_matcher);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Data) {
      return _matcher.matches(item.asMap, matchState);
    }
    return false;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    var matcher = matchState['matcher'];
    matcher.describeMismatch(
        item.asMap, mismatchDescription, matchState['state'], verbose);
    return mismatchDescription;
  }
}

Matcher asDataMap(Matcher matcher) =>
    new _DataAsMapMatcher(wrapMatcher(matcher));
