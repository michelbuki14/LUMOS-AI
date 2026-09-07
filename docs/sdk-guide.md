# SDK Guide

`packages/sdk` — stable plugin SDK, semver.

```dart
import 'package:lumos_sdk/lumos_sdk.dart';

class MyRawPlugin implements RawPlugin {
  String get id => 'com.example.myraw';
  String get version => '1.0.0';
  Future<DecodedRaw> decode(bytes) async => ...;
}
void register(Registry r) => r.raw.register(MyRawPlugin());
```

Versioning: patch = fix, minor = additive, major = breaking (needs `MIGRATION.md`). All third-party deps Apache-2.0 compatible.

See `packages/sdk/README.md` and `docs/plugin-guide.md`.
