// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

import 'package:heron/src/data.dart';

typedef bool FilterData(Data data);

class SitemapBuilder {
  final Data site;

  SitemapBuilder(this.site);

  List<String> _urls = <String>[];

  void add(Data page) {
    _urls.add(page['url']);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'site': site.asMap,
        'urls': _urls..sort(),
      };
}

class AtomBuilder {
  final Data site;
  List<Map<String, dynamic>> _entries = [];

  AtomBuilder(this.site);

  void add(Data page, {String html, String text}) {
    assert((html != null && text == null) || (html == null && text != null));
    _entries.add(<String, dynamic>{
      'url': page['url'],
      'title': page['title'],
      'updated': page['updated'] ?? page['published'],
      'html': html,
      'text': text,
    });
  }

  Map<String, dynamic> toMap({int limit: 20}) {
    List<Map<String, dynamic>> entries = new List.from(_entries);
    entries.sort((Map<String, dynamic> m1, Map<String, dynamic> m2) =>
        -Comparable.compare(m1['updated'], m2['updated']));
    if (entries.length > limit) entries = entries.sublist(0, limit);
    return <String, dynamic>{
      'site': site.asMap,
      'entries': entries,
    };
  }
}
