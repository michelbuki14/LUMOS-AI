# Hello Plugin — example

```dart
import 'package:lumos_sdk/lumos_sdk.dart';

class HelloAi implements AiPlugin {
  String get id => 'com.example.hello-ai';
  String get version => '0.1.0';
  Future<Map<String,dynamic>> infer(input) async => {'hello': 'lumos'};
}
void register(Registry r) => r.ai.register(HelloAi());
```

See `docs/plugin-guide.md`.
