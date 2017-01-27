// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mustache/mustache.dart' as mustache;
import 'package:resource/resource.dart' show Resource;

import 'package:heron/src/io_utils.dart' show getRelativePath;

/// Renders the template as String.
typedef String StringRenderer(Map values);

class Templates {
  Map<String, mustache.Template> _templates = {};

  Future<Null> loadDefaults() async {
    await _loadDefault('html-head');
    await _loadDefault('atom-xml');
    await _loadDefault('sitemap-xml');
  }

  void addRenderer(String name, StringRenderer renderer) {
    _templates[name] = new _MustacheAdapter(name, renderer);
  }

  Future<Null> loadDirectory(String dir) async {
    for (FileSystemEntity fse in new Directory(dir).listSync()) {
      if (fse is File) {
        if (!fse.path.endsWith('.html')) continue;
        String name = getRelativePath(fse, dir);
        name = name.substring(0, name.length - 5);
        String content = await fse.readAsString();
        _addTemplate(name, content);
      }
    }
  }

  String renderString(String template, Map data) =>
      _resolver(template).renderString(data);

  Future<Null> _loadDefault(String name) async {
    String resourcePath = 'package:heron/templates/$name.html';
    String content = await new Resource(resourcePath).readAsString();
    _addTemplate(name, content);
  }

  void _addTemplate(String name, String content) {
    _templates[name] = new mustache.Template(content,
        lenient: true,
        name: name,
        htmlEscapeValues: true,
        partialResolver: _resolver);
  }

  mustache.Template _resolver(String templateName) {
    if (!_templates.containsKey(templateName)) {
      List<String> templates = new List.from(_templates.keys)..sort();
      throw new Exception('Template not found: $templateName.\n'
          'Loaded templates: $templates.');
    }
    return _templates[templateName];
  }
}

class _MustacheAdapter implements mustache.Template {
  @override
  final String name;

  @override
  final String source;

  final StringRenderer stringRenderer;

  _MustacheAdapter(this.name, this.stringRenderer, {this.source: '[callback]'});

  @override
  void render(dynamic values, StringSink sink) {
    sink.write(renderString(values));
  }

  @override
  String renderString(dynamic values) => this.stringRenderer(values);
}
