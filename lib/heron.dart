// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library heron;

import 'dart:io';

import 'package:intl/intl.dart' show DateFormat;
import 'package:intl/date_symbol_data_local.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yaml/yaml.dart' as yaml;

import 'src/archive.dart';
import 'src/config.dart';
import 'src/data.dart';
import 'src/static.dart';
import 'src/templates.dart';
import 'src/utils.dart';

void processConfig(String configFile) {
  String baseDir = new File(configFile).parent.path;
  config.buildRoot = '$baseDir/build';
  config.buildSite = '${config.buildRoot}/site';
  config.contentDir = '$baseDir/content';

  Map<String, dynamic> site =
      yaml.loadYaml(new File(configFile).readAsStringSync());

  templates.loadSync('$baseDir/template');

  List<Map<String, dynamic>> allContent = _processContent(site);
  processStatic('$baseDir/static');
  processArchives(site, allContent);

  writeChangeLogSync('${config.buildRoot}/change.log', '${config.buildSite}/');
}

List<Map<String, dynamic>> _processContent(Map<String, dynamic> site) {
  List<Map<String, dynamic>> allContent = [];
  for (var fse in new Directory(config.contentDir).listSync(recursive: true)) {
    if (fse.path.endsWith('/META.yaml') || fse.path == 'META.yaml') continue;
    if (fse is File) {
      Map<String, dynamic> pathmap =
          pathMetadata.getMetadata(site, config.contentDir, fse.path);
      pathmap.putIfAbsent(
          'path', () => getRelativePath(config.contentDir, fse.parent.path));

      String fileName = fse.path.split('/').last;
      if (fse.path.endsWith('.md')) {
        String fileBase = fileName.substring(0, fileName.length - 3);
        String contentSrc = fse.readAsStringSync();
        String metaSrc = '';
        if (contentSrc.startsWith('---\n')) {
          List<String> split = contentSrc.substring(4).split('\n---\n');
          if (split.length > 1) {
            metaSrc = split.first;
            contentSrc = split.sublist(1).join('\n---\n');
          }
        }
        Map<String, dynamic> metaMap =
            metaSrc.isNotEmpty ? new Map.from(yaml.loadYaml(metaSrc)) : {};
        pathmap.forEach((k, v) => metaMap.putIfAbsent(k, () => v));
        String url = metaMap['url'];
        if (url == null) {
          String base = metaMap['path'];
          if (!base.startsWith('/')) base = '/$base';
          if (!base.endsWith('/')) base = '$base/';
          if (fileBase != 'index') {
            url = '$base$fileBase.html';
          } else {
            url = base;
          }
          metaMap['url'] = url;
        }
        contentSrc = _convertContent(contentSrc, metaMap);
        metaMap['content'] = md.markdownToHtml(contentSrc);
        int wordCount = contentSrc.split(new RegExp('\\s+')).length;
        metaMap['content-readmin'] = (wordCount ~/ 180) + 1;
        _processExtends(metaMap);
        _datePreProcessor.processDateAttributes(metaMap);
        String outFile = url.endsWith('/') ? '${url}index.html' : url;
        String html = templates.render(new DataMap(metaMap));
        setFileContentSync('${config.buildSite}$outFile', html);
        metaMap['copy-to']?.forEach((target) {
          copyFileSync(new File('${config.buildSite}$outFile'),
              '${config.buildSite}$target');
        });
        allContent.add(metaMap);
      } else {
        copyFileSync(fse, '${config.buildSite}/${pathmap['path']}/$fileName');
      }
    }
  }
  return allContent;
}

String _convertContent(String src, Map metaMap) {
  bool indent = metaMap['markdown-indent-headers'] ?? false;
  if (indent) {
    return '\n\n$src'
        .replaceAll(new RegExp('\n\n#', multiLine: true), '\n\n##');
  }
  return src;
}

void _processExtends(Map map) {
  List extendsList = map['extend'];
  extendsList?.forEach((Map m) {
    String attr = m['attr'];
    var attrObject = map[attr];
    if (attrObject == null) return;
    if (attrObject is! List) {
      attrObject = [attrObject];
    }
    attrObject = attrObject.map((o) => o is Map ? o : {'key': o}).toList();

    String source = m['source'];
    Map sourceMap = map[source];

    attrObject.forEach((Map ko) {
      String key = ko['key'];
      Map keyMap = sourceMap[key];
      keyMap?.forEach((k, v) => ko[k] = v);
    });
    map[attr] = attrObject;
  });
}

_DatePreProcessor _datePreProcessor = new _DatePreProcessor();

class _DatePreProcessor {
  Set<String> _initalizedLocales = new Set();

  void processDateAttributes(Map map) {
    DataMap data = new DataMap(map);
    if (!_initalizedLocales.contains(data.lang)) {
      // TODO: await Future
      initializeDateFormatting(data.lang);
      _initalizedLocales.add(data.lang);
    }
    List<String> dateAttributes = data.dateAttributes;
    DateFormat localizedDateFormat =
        new DateFormat(data.datePattern, data.lang);
    DateFormat standardDateFormat = new DateFormat('yyyy-MM-dd');
    dateAttributes?.forEach((String key) {
      if (!map.containsKey(key)) return;
      if (map.containsKey('$key-localized')) return;
      String origin = map[key];
      DateTime dt = DateTime.parse(origin);
      map['$key-localized'] = localizedDateFormat.format(dt);
      map['$key-standard'] = standardDateFormat.format(dt);
    });
  }
}
