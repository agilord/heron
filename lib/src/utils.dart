// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:io';

List<String> updatedFiles = [];

String getRelativePath(String baseDirectory, String path) {
  String relativePath = path.substring(baseDirectory.length);
  if (relativePath.startsWith('/')) relativePath = relativePath.substring(1);
  return relativePath;
}

void setFileContentSync(String fileName, String content) {
  try {
    File f = new File(fileName);
    if (f.existsSync()) {
      String oldContent = f.readAsStringSync();
      if (content == oldContent) return;
    }
    f.parent.createSync(recursive: true);
    updatedFiles.add(fileName);
    print('Updating file: $fileName');
    f.writeAsStringSync(content);
  } catch (e) {
    print('Exception while processing: $fileName');
    rethrow;
  }
}

void copyFileSync(File source, String targetPath) {
  if (source.path.endsWith('.DS_Store')) return;
  File target = new File(targetPath);
  if (target.existsSync() &&
      target.lengthSync() == source.lengthSync() &&
      target.lastModifiedSync() == source.lastModifiedSync()) {
    return;
  }
  updatedFiles.add(targetPath);
  target.parent.createSync(recursive: true);
  print('Copy file: $targetPath');
  source.copySync(target.path);
}

void writeChangeLogSync(String logFile, String prefix) {
  String log = updatedFiles
      .where((f) => f.startsWith(prefix))
      .map((f) => f.substring(prefix.length))
      .map((f) => '$f\n')
      .join();
  new File(logFile).writeAsString(log, mode: FileMode.APPEND);
}
