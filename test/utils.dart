library heron.test.utils;

import 'dart:async';
import 'dart:io';
import 'package:scheduled_test/descriptor.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:path/path.dart' as p;

import 'dart:mirrors';

export 'sample_descriptors.dart';

/// Produces the path to heron executable script
String get _heronPath => p.normalize(p.join(
    p.dirname(
        currentMirrorSystem().findLibrary(#heron.test.utils).uri.toFilePath()),
    '../'));

/// Schedules heron execution in sandbox
ScheduledProcess runHeron({Future inDirectory}) {
  if (inDirectory == null) {
    throw new ArgumentError.notNull('inDirectory');
  }
  String heronExec = p.join(_heronPath, 'bin', 'heron.dart');
  return new ScheduledProcess.start(
      Platform.resolvedExecutable, ['--checked', heronExec],
      workingDirectory: inDirectory, description: 'Executing heron');
}

Completer<String> _sandbox;

Future<String> get sandboxPath => _sandbox.future;

/// Creates a temporary directory the tests can spam into
///
/// if [cleanUpAfterTests] is `false`, the temporary directory created for sandbox
/// will not be deleted.
void setupSandbox({bool cleanUpAfterTests: true}) {
  _sandbox = new Completer<String>();
  schedule(() {
    String path =
        Directory.systemTemp.createTempSync('heron_test_project_').path;
    _sandbox.complete(path);
    d.defaultRoot = path;
  }, 'Creating sandbox');

  currentSchedule.onComplete.schedule(() {
    // clean up sandbox dir
    if (cleanUpAfterTests)
      sandboxPath.then((s) => new Directory(s).deleteSync(recursive: true));
    else {
      sandboxPath.then((s) => print('Sandbox directory not removed: `$s`'));
    }
  }, 'sandbox cleanup');
}

/// Schedules the validation for [desc] relative to [parent] in the sandbox
///
/// Let `s` be the the path of sandbox,`p` the `parent`, `n` the name of `desc`,
/// then validation will run against the path: `s/p/n`
Future validateSandboxed(Descriptor desc, String parent) => schedule(() async =>
    desc.validateNow(p.join(await sandboxPath, p.normalize(parent))));

/// Collection of enviroment variables that has a meaning to these tests
abstract class EnvVars {
  /// Should the sandbox directory be cleaned up after tests are ran
  ///
  /// Specify it with any value to set to true
  ///
  /// __Usage__:
  ///
  ///     # on win
  ///     set NOCLEANUP="" && pub run test
  ///     # on decent systems
  ///     (export NOCLEANUP="" && pub run test)
  ///
  static bool get NOCLEANUP => Platform.environment['NOCLEANUP'] != null;
}
