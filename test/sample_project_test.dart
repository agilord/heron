@TestOn('vm')
import 'dart:io';

import 'package:heron/src/data.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:heron/heron.dart' show PathConfig;
import 'package:markdown/markdown.dart' as md;

import 'utils.dart';

void main() {
  // TODO: should really be setUpAll, once dart-lang/scheduled_test#28 is fixed, replace
  PathConfig pathConfig;
  setUp(() {
    setupSandbox(cleanUpAfterTests: !EnvVars.NOCLEANUP);
    sampleProject.create();
    runHeron(inDirectory: sandboxPath)..shouldExit(0);
    pathConfig = new PathConfig.defaults();
  });

  test('static files copied', () {
    validateSandboxed(robotsTxt, pathConfig.siteOutput);
    validateSandboxed(runJs, pathConfig.siteOutput);
    validateSandboxed(styleCss, pathConfig.siteOutput);
  });

  test('contains html-head', () {
    var content = new MarkdownContent.parseSource(indexMd.textContents);
    expect(content.header, isNotNull);
  });
}
