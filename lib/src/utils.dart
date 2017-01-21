// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

List<String> updatedFiles = [];

String getRelativePath(String baseDirectory, String path) {
  String relativePath = path.substring(baseDirectory.length);
  if (relativePath.startsWith('/')) relativePath = relativePath.substring(1);
  return relativePath;
}

Future setFileContent(String fileName, String content) async {
  try {
    File f = new File(fileName);
    if (f.existsSync()) {
      String oldContent = await f.readAsString();
      if (content == oldContent) return;
    }
    await f.parent.create(recursive: true);
    updatedFiles.add(fileName);
    print('Updating file: $fileName');
    await f.writeAsString(content);
  } catch (e) {
    print('Exception while processing: $fileName');
    rethrow;
  }
}

Future copyFile(File source, String targetPath) async {
  if (source.path.endsWith('.DS_Store')) return;
  File target = new File(targetPath);
  if (target.existsSync() &&
      target.lengthSync() == source.lengthSync() &&
      target.lastModifiedSync() == source.lastModifiedSync()) {
    return;
  }
  updatedFiles.add(targetPath);
  await target.parent.create(recursive: true);
  print('Copy file: $targetPath');
  await source.copy(target.path);
}

Future writeChangeLog(String logFile, String prefix) {
  String log = updatedFiles
      .where((f) => f.startsWith(prefix))
      .map((f) => f.substring(prefix.length))
      .map((f) => '$f\n')
      .join();
  return new File(logFile).writeAsString(log, mode: FileMode.APPEND);
}
