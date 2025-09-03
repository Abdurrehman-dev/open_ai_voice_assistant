# OpenAI Voice Assistant 🎙️🤖

[![pub package](https://img.shields.io/pub/v/open_ai_voice_assistant.svg)](https://pub.dev/packages/open_ai_voice_assistant)
[![likes](https://img.shields.io/pub/likes/open_ai_voice_assistant?logo=dart)](https://pub.dev/packages/open_ai_voice_assistant/score)
[![pub points](https://img.shields.io/pub/points/open_ai_voice_assistant?logo=dart)](https://pub.dev/packages/open_ai_voice_assistant/score)

A Flutter package that brings **real-time voice conversation with OpenAI models** using **WebRTC**.
It handles microphone input, audio output, and data channel messaging to create a seamless AI voice assistant experience.

---

## ✨ Features

* 🎤 Real-time voice input and AI response
* 🔊 Configurable voice & speed
* ⚡ Ephemeral key authentication with OpenAI Realtime API
* 📱 Android & iOS support with proper audio session handling
* 🔌 Simple singleton API (`OpenAiAssistant.instance`)

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  open_ai_voice_assistant: ^0.0.1
```

Run:

```bash
flutter pub get
```

---

## 🚀 Usage

```dart
import 'package:flutter/material.dart';
import 'package:open_ai_voice_assistant/open_ai_voice_assistant.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OpenAiAssistant.instance.init(
        apiKey: 'YOUR_API_KEY', // 🔑 Replace with your OpenAI API Key
      );
      await OpenAiAssistant.instance.start();
      setState(() {
        isInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    OpenAiAssistant.instance.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAI Voice Assistant',
      home: Scaffold(
        body: Center(
          child: isInitialized
              ? Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
```

---

## ⚙️ Setup

### Android

Add permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### iOS

In `ios/Podfile` set platform:

```ruby
platform :ios, '14.0'

# ADD THIS SECTION
target.build_configurations.each do |config|
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
    '$(inherited)',
    'AUDIO_SESSION_MICROPHONE=1'
  ]
  config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
end
```

Add permissions in `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Required to connect to Bluetooth audio devices.</string>
<key>NSCameraUsageDescription</key>
<string>Camera needed for realtime communication.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need microphone access for conversation with AI</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition will be used to transcribe your voice commands for AI assistant.</string>
```

---

## 📌 Example

Check the [`example/`](example/) folder for a full Flutter demo app.

---

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

👉 Would you like me to also add **badges for supported platforms** (Android, iOS, Web) at the top of the README so it looks more professional on pub.dev?
