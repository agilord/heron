/// Collection of descriptors to set up a project programmatically
///
/// Directory structure described here:
///
///     ./src
///     ├── content
///     │   ├── index.md
///     │   ├── PAGE.yaml
///     │   └── SITE.yaml
///     ├── PAGE.yaml
///     ├── SITE.yaml
///     ├── static
///     │   ├── robots.txt
///     │   ├── run.js
///     │   └── style.css
///     └── template
///     └── page.html
///
/// __Usage__:
///
///     sampleProject.create();
///
library heron.test.sample_descriptors;

import 'package:scheduled_test/descriptor.dart' as d;

d.DirectoryDescriptor get sampleProject {
  return d.dir('src', [
    d.dir('content',
        [indexMd, d.file('PAGE.yaml', ''), d.file('SITE.yaml', 'root: /')]),
    d.dir('static', [robotsTxt, runJs, styleCss]),
    d.dir('template', [pageHtml]),
    d.file('PAGE.yaml', 'article: false\nsitemap: false'),
    d.file(
        'SITE.yaml',
        '''
url: 'https://example.com'
name: 'Test project'

styles:
  - href: style.css

scripts:
  - href: run.js
      ''')
  ]);
}

d.FileDescriptor get robotsTxt => d.file('robots.txt', '');

d.Descriptor get pageHtml => d.file(
    'page.html',
    '''
<!DOCTYPE html>
<html>
    <head>
        {{> html-head}}
    </head>
    <body>
        {{#page.article}}
        <h1>{{page.title}}</h1>
        {{/page.article}}
        {{{content.html}}}
    </body>
</html>
''');

d.Descriptor get runJs => d.file(
    'run.js',
    '''
(function() {
    console.log('ran');
})();
''');

d.Descriptor get styleCss => d.file(
    'style.css',
    '''
body {
    background-color: lightgray;
}
''');

d.FileDescriptor get indexMd => d.file(
    'index.md',
    '''
 ---
title: 'Test page'
url: /
article: false
---

## Do more

with static site generation in Dart.
''');
