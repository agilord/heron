// Copyright (c) 2016-2017, Agilord. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:heron/heron.dart';
import 'package:stack_trace/stack_trace.dart';

Future<Null> main(List<String> arguments) async {
  await Chain.capture(() async {
    String basePath = arguments.isEmpty ? '.' : arguments.first;
    Heron heron = new Heron()
      ..pathConfig = new PathConfig.defaults(basePath);
    return await heron.process();
  }, onError: (error, Chain chain) {
    print(error.toString());
    print(chain.terse);
  });
}
