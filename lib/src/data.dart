// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import 'utils.dart';

final PathMetadata pathMetadata = new PathMetadata();

class DataMap {
  final Map _map = {};

  DataMap([Map map]) {
    this._map.addAll(map);
  }

  List<String> get dateAttributes => _map['date-attributes'] ?? const ['published', 'updated'];

  String get template => _map['template'] ?? 'page';

  String get lang => _map['lang'] ?? 'en';

  String get datePattern => _map['date-pattern'] ?? 'yyyy-MM-dd';

  Map get asMap => _map;

  DataMap fork([Map map]) {
    DataMap forked = new DataMap(this._map);
    if (map != null) {
      forked._map.addAll(map);
    }
    return forked;
  }
}

class PathMetadata {
  Map<String, Map<String, dynamic>> _maps = {};

  Future<Map<String, dynamic>> getMetadata(
      Map<String, dynamic> siteconfig, String baseDir, String path) async {
    List<String> paths = '/${getRelativePath(baseDir, path)}'.split('/')
      ..removeLast();
    Map<String, dynamic> map = {};
    _merge(map, siteconfig);
    for (int i = 0; i <= paths.length; i++) {
      String joined = paths.sublist(0, i).join('/');
      Map<String, dynamic> m = await _get('$baseDir/$joined');
      _merge(map, m);
    }
    return map;
  }

  Future<Map<String, dynamic>> _get(String p) async {
    Map<String, dynamic> m = _maps[p];
    if (m == null) {
      File f = new File('$p/META.yaml');
      if (f.existsSync()) {
        m = yaml.loadYaml(await f.readAsString());
        _maps[p] = m;
      }
    }
    return m;
  }

  void _merge(Map<String, dynamic> map, Map<String, dynamic> m) {
    if (m == null) return;
    map.addAll(m);
  }
}
