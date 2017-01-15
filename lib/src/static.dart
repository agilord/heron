// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:io';

import 'config.dart';
import 'utils.dart';

void processStatic(String staticDir) {
  for (var fse in new Directory(staticDir).listSync(recursive: true)) {
    if (fse is File) {
      String path = getRelativePath(staticDir, fse.path);
      copyFileSync(fse, '${config.buildSite}/$path');
    }
  }
}
