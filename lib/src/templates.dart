// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:io';

import 'package:mustache/mustache.dart' as mustache;

import 'data.dart';
import 'utils.dart';

final Templates templates = new Templates();

class Templates {
  Map<String, mustache.Template> _templates = {};

  void loadSync(String dir) {
    for (var fse in new Directory(dir).listSync()) {
      if (fse is File) {
        if (!fse.path.endsWith('.html')) continue;
        String path = getRelativePath(dir, fse.path);
        path = path.substring(0, path.length - 5);
        String content = fse.readAsStringSync();
        _templates[path] = new mustache.Template(content,
            lenient: true,
            name: path,
            htmlEscapeValues: true,
            partialResolver: _resolver);
      }
    }
  }

  String render(DataMap data) =>
      _resolver(data.template).renderString(data.asMap);

  mustache.Template _resolver(String templateName) => _templates[templateName];
}
