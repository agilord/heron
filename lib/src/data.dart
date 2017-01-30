// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

class Data {
  Map<String, dynamic> _map;

  factory Data() => new Data.fromMap({});
  Data.fromMap(this._map);
  factory Data.fromYaml(String content) =>
      new Data.fromMap(yaml.loadYaml(content));

  factory Data.merge(Iterable<Data> list) {
    Data result = new Data();
    for (Data data in list) {
      _mergeOver(result._map, data._map);
    }
    return result;
  }

  static Future<Data> loadFile(String path, {bool mustExist: false}) async {
    File f = new File(path);
    if (f.existsSync()) {
      String content = await f.readAsString();
      if (content.trim().isEmpty) {
        return new Data();
      }
      if (path.endsWith('.yml') || path.endsWith('.yaml')) {
        return new Data.fromYaml(content);
      } else if (path.endsWith('.json')) {
        return new Data.fromMap(JSON.decode(content));
      } else if (path.endsWith('.md')) {
        return new MarkdownContent.parseSource(content).header;
      }
    } else if (mustExist) {
      throw new Exception('File does not exist: $path');
    } else {
      return new Data();
    }
    throw new Exception('Unhandled case for $path');
  }

  static Future<List<Data>> loadAll(Iterable<String> dirs, String file) async {
    List<Data> list = <Data>[];
    for (String dir in dirs) {
      Data d = await loadFile('$dir/$file');
      list.add(d);
    }
    return list;
  }

  static void _mergeOver(Map m1, Map m2) {
    if (m2 == null) return;
    m2.forEach((String key, dynamic value) {
      if (value is Map && m1[key] is Map) {
        Map v1 = m1[key];
        _mergeOver(v1, value);
      } else {
        m1[key] = value;
      }
    });
  }

  dynamic operator [](String key) => _map[key];
  void operator []=(String key, dynamic value) {
    _map[key] = value;
  }

  Map<String, dynamic> get asMap => _map;

  Data fork() => new Data.fromMap(JSON.decode(JSON.encode(_map)));

  dynamic putIfAbsent(String key, dynamic ifAbsent()) =>
      _map.putIfAbsent(key, ifAbsent);
}

class MarkdownContent {
  Data header;
  String markdown;

  MarkdownContent(this.header, this.markdown);

  factory MarkdownContent.parseSource(String source, {Data header}) {
    String meta = '';
    String body = source;
    // fixme: source should be trimmed or regexp be used to ignore leading whitespace
    // fixme: should allow arbitrary number of - over 2
    if (source.startsWith('---\n')) {
      List<String> split = source.substring(4).split('\n---\n');
      if (split.length > 1) {
        meta = split.first;
        body = split.sublist(1).join('\n---\n');
      }
    }
    Data data = meta.isNotEmpty ? new Data.fromYaml(meta) : new Data();
    if (header != null) {
      data = new Data.merge([header, data]);
    }
    return new MarkdownContent(data, body);
  }
}

abstract class PageDB {
  Future<Null> store(Data data);
  Future<Null> delete(String url);
  Stream<Data> list();
}

class MemoryPageDB implements PageDB {
  Map<String, Data> _pages = {};

  @override
  Future<Null> store(Data data) async {
    _pages[data['url']] = data;
  }

  @override
  Future<Null> delete(String url) async {
    _pages.remove(url);
  }

  @override
  Stream<Data> list() async* {
    for (Data data in _pages.values) {
      yield data;
    }
  }
}
