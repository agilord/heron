// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:mustache/mustache.dart' as mustache;

import 'config.dart';
import 'data.dart';
import 'templates.dart';
import 'utils.dart';

Future processArchives(
    Map<String, dynamic> site, List<Map<String, dynamic>> allContent) async {
  if (site['archives'] != null) {
    for (Map archive in site['archives']) {
      List<Map<String, dynamic>> content = allContent;
      if (archive.containsKey('filter')) {
        Map filter = archive['filter'];
        content = content
            .where((map) => filter.keys.every((k) => map[k] == filter[k]))
            .toList();
      }
      var getMeta = (url) => pathMetadata.getMetadata(
          site, config.contentDir, '${config.contentDir}${url}index.html');
      await _doArchive(archive, 'sitemap', content, getMeta);
      await _doArchive(archive, 'page', content, getMeta);
      await _doArchive(archive, 'atom', content, getMeta);
    }
  }
}

Future _doArchive(Map archive, String type, List<Map<String, dynamic>> content,
    Future<Map> getMeta(url)) async {
  if (archive.containsKey(type)) {
    Map<String, List<Map>> groups = _group(content, archive[type]);
    for (String url in groups.keys) {
      List<Map> list = groups[url];
      list.sort((a, b) => a['url'].compareTo(b['url']));
      list.sort(
          (a, b) => (b['published'] ?? '').compareTo(a['published'] ?? ''));
      Map map = {
        'template': archive['$type-template'] ?? '$type',
        'items': list,
        'url': url
      };
      archive['vars']?.forEach((k, v) {
        map.putIfAbsent(k, () => v);
      });
      (await getMeta(url))?.forEach((k, v) {
        map.putIfAbsent(k, () => v);
      });
      String xml = templates.render(new DataMap(map));
      String outFile = url.endsWith('/') ? '${url}index.html' : url;
      await setFileContent('${config.buildSite}$outFile', xml);
    }
  }
}

Map<String, List<Map>> _group(List<Map> contents, String template) {
  Map<String, List> sitemaps = {};
  var t = new mustache.Template(template);
  contents.forEach((map) {
    var s = t.renderString(map);
    if (s.startsWith('/')) {
      sitemaps.putIfAbsent(s, () => []);
      sitemaps[s].add(map);
    }
  });
  return sitemaps;
}
