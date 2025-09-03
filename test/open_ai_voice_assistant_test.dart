import 'package:flutter_test/flutter_test.dart';

import 'package:open_ai_voice_assistant/open_ai_voice_assistant.dart';

void main() {
  test('check functions', () async{
    final result = await OpenAiAssistant.instance.init(apiKey: 'Your api key');
    final key = result?['client_secret']['value'];
    expect(key, isA<String?>());
  });
}
