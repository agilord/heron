// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

// TODO: implement/apply better path handling
// e.g. file names that contain `/` or `\` are handled in a bad way
String getUnixPath(String path) => path.replaceAll(Platform.pathSeparator, '/');

String getPlatformPath(String path) =>
    path.replaceAll('/', Platform.pathSeparator);

String getRelativePath(FileSystemEntity file, String baseDir) {
  String path = getUnixPath(file.path);
  baseDir = getUnixPath(baseDir);
  if (!path.startsWith(baseDir)) {
    throw new Exception('Wrong base directory: $baseDir for $path');
  }
  String relativePath = path.substring(baseDir.length);
  if (relativePath.startsWith('/')) relativePath = relativePath.substring(1);
  return relativePath;
}

List<Directory> getParentDirs(File file, String baseDir) {
  String path = getUnixPath(file.path);
  baseDir = getUnixPath(baseDir);
  if (!path.startsWith(baseDir)) {
    throw new Exception('Wrong base directory: $baseDir for $path');
  }
  List<Directory> results = [];
  Directory dir = file.parent;
  while (dir != null) {
    results.add(dir);
    if (dir.path != baseDir) {
      dir = dir.parent;
    } else {
      dir = null;
    }
  }
  return results.reversed.toList();
}

class SiteOutput {
  final List<String> updatedFiles = [];

  final String siteDir;
  SiteOutput(this.siteDir);

  Future<Null> copyFileTo(File source, String relativePath) async {
    if (getUnixPath(source.path).endsWith('/.DS_Store')) return;
    String path = _removeSlash(relativePath);
    String targetPath = '$siteDir/$path';
    File target = new File(getPlatformPath(targetPath));
    if (target.existsSync() &&
        target.lengthSync() == source.lengthSync() &&
        target.lastModifiedSync() == source.lastModifiedSync()) {
      return;
    }
    updatedFiles.add(path);
    await target.parent.create(recursive: true);
    print('Copy file: $path');
    await source.copy(getPlatformPath(target.path));
  }

  Future<Null> copyAll(String directory) async {
    await new Directory(directory).list(recursive: true).asyncMap((fse) async {
      if (fse is File) {
        String path = getRelativePath(fse, directory);
        await copyFileTo(fse, path);
      }
    }).drain();
  }

  Future<Null> writeTextTo(String content, String relativePath) async {
    try {
      String path = _removeSlash(relativePath);
      String fileName = '$siteDir/$path';
      File target = new File(getPlatformPath(fileName));
      if (target.existsSync()) {
        String oldContent = await target.readAsString();
        if (content == oldContent) return;
      }
      await target.parent.create(recursive: true);
      updatedFiles.add(path);
      print('Updating file: $path');
      await target.writeAsString(content);
    } catch (e) {
      print('Exception while processing: $relativePath');
      rethrow;
    }
  }

  Future<Null> writeChangeLogTo(String logFile) async {
    String log = updatedFiles.map((String f) => '$f\n').join();
    await new File(getPlatformPath(logFile))
        .writeAsString(log, mode: FileMode.APPEND);
  }

  String _removeSlash(String path) {
    if (path.startsWith('/')) return path.substring(1);
    return path;
  }
}
