// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'config.dart';
import 'utils.dart';

Future processStatic(String staticDir) async {
  new Directory(staticDir).list(recursive: true).asyncMap((fse) async {
    if (fse is File) {
      String path = getRelativePath(staticDir, fse.path);
      await copyFile(fse, '${config.buildSite}/$path');
    }
  });
}
