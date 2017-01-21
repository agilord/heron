// Copyright (c) 2016-2017, Agilord. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library heron;

import 'dart:async';
import 'dart:io';

import 'package:markdown/markdown.dart' as md;

import 'package:heron/src/data.dart';
import 'package:heron/src/templates.dart';
import 'package:heron/src/io_utils.dart';

export 'package:heron/src/archives.dart';
export 'package:heron/src/data.dart';
export 'package:heron/src/templates.dart';
export 'package:heron/src/io_utils.dart';

class PathConfig {
  String rootOutput;
  String siteOutput;
  String siteConfigFile;
  String pageConfigFile;
  String contentDir;
  String staticDir;
  String templateDir;

  PathConfig();
  PathConfig.defaults([String basePath = '.']) {
    rootOutput = '$basePath/build';
    siteOutput = '$rootOutput/site';
    String inputRoot = '$basePath/src';
    contentDir = '$inputRoot/content';
    staticDir = '$inputRoot/static';
    templateDir = '$inputRoot/template';
    pageConfigFile = '$inputRoot/PAGE.yaml';
    siteConfigFile = '$inputRoot/SITE.yaml';
  }
}

class PageContext {
  Data site;
  Data page;
  Data content;
}

class Heron {
  PathConfig pathConfig;
  PageDB pageDB;
  SiteOutput siteOutput;
  Templates templates;
  Data siteData;
  Data pageData;

  Future<Null> init() async {
    pathConfig ??= new PathConfig.defaults();
    siteOutput ??= new SiteOutput(pathConfig.siteOutput);
    pageDB ??= new MemoryPageDB();
    if (templates == null) {
      templates = new Templates();
      await templates.loadDefaults();
      await templates.loadDirectory(pathConfig.templateDir);
    }
    siteData ??= await Data.loadFile(pathConfig.siteConfigFile);
    pageData ??= await Data.loadFile(pathConfig.pageConfigFile);
  }

  Future<Data> mergePageData(List<Directory> dirs, Data pageData) async {
    List<Data> list =
        await Data.loadAll(dirs.map((Directory d) => d.path), 'PAGE.yaml');
    list.insert(0, pageData);
    return new Data.merge(list);
  }

  Future<Data> mergeSiteData(List<Directory> dirs, Data siteData) async {
    List<Data> list =
        await Data.loadAll(dirs.map((Directory d) => d.path), 'SITE.yaml');
    list.insert(0, siteData);
    return new Data.merge(list);
  }

  Future<Null> preProcess(PageContext context) async {
    Data page = context.page;

    page.putIfAbsent('url', () {
      String fileBase = page['path'].split('/').last;
      fileBase = fileBase.substring(0, fileBase.length - 3);
      String dir = page['dir'];
      if (!dir.startsWith('/')) dir = '/$dir';
      if (!dir.endsWith('/')) dir = '$dir/';
      if (fileBase != 'index') return '$dir$fileBase.html';
      return dir;
    });

    page.putIfAbsent('outputFile', () {
      String url = page['url'];
      return url.endsWith('/') ? '${url}index.html' : url;
    });

    page.putIfAbsent('readmin', () {
      int wordCount =
          context.content['markdown'].split(new RegExp('\\s+')).length;
      return (wordCount ~/ 180) + 1;
    });

    String descr = page['description'] ?? page['descr'];
    if (descr != null) {
      page['description'] = descr.replaceAll(new RegExp('\\s+'), ' ').trim();
    }
  }

  Future<Null> postProcess(PageContext context) async {}

  Future<Null> renderPage(PageContext context) async {
    String template = context.page['template'] ?? 'page';
    String text = templates.renderString(template, <String, dynamic>{
      'site': context.site.asMap,
      'page': context.page.asMap,
      'content': context.content.asMap,
    });
    await siteOutput.writeTextTo(text, context.page['outputFile']);
  }

  Future<Data> preProcessStatic(Data page, File file) async {
    String path = file.path;
    String fileName = path.split('/').last;
    if (fileName == 'PAGE.yaml') return null;
    if (fileName == 'SITE.yaml') return null;
    return page;
  }

  Future<Null> generateContent() => new Future<Null>.value();

  Future<Null> generateArchives() => new Future<Null>.value();

  Future<Null> writeChangeLog() async {
    await siteOutput.writeChangeLogTo('${pathConfig.rootOutput}/change.log');
  }

  Future<Null> process() async {
    await init();

    await siteOutput.copyAll(pathConfig.staticDir);

    await new Directory(pathConfig.contentDir)
        .list(recursive: true, followLinks: true)
        .asyncMap((FileSystemEntity fse) async {
      if (fse is File) {
        List<Directory> dirs = getParentDirs(fse, pathConfig.contentDir);
        String relativeDir = getRelativePath(dirs.last, pathConfig.contentDir);
        PageContext context = new PageContext();
        context.site = await mergeSiteData(dirs, siteData.fork());
        context.page = await mergePageData(dirs, pageData.fork());
        String relativePath = getRelativePath(fse, pathConfig.contentDir);
        context.page.putIfAbsent('path', () => relativePath);
        context.page.putIfAbsent('dir', () => relativeDir);
        if (relativePath.endsWith('.md')) {
          String source = await fse.readAsString();
          MarkdownContent mc =
              new MarkdownContent.parseSource(source, header: context.page);
          context.page = mc.header;
          context.content = new Data.fromMap(<String, dynamic>{
            'markdown': mc.markdown,
          });
          await preProcess(context);
          if (context.page == null || context.content == null) return;
          context.content['html'] =
              md.markdownToHtml(context.content['markdown']);
          await postProcess(context);
          if (context.page == null || context.content == null) return;
          await renderPage(context);
          await pageDB.store(context.page);
        } else {
          context.page = await preProcessStatic(context.page, fse);
          if (context.page != null) {
            await siteOutput.copyFileTo(fse, context.page['path']);
          }
        }
      }
    }).drain();

    await generateContent();

    await generateArchives();

    await writeChangeLog();
  }
}
