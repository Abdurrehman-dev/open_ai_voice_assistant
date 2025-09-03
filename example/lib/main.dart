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
  bool isInisialized = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OpenAiAssistant.instance.init(
        apiKey:'Your api key',
      );
      await OpenAiAssistant.instance.start();
      setState(() {
        isInisialized = true;
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
      title: 'Open AI Voice Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            !isInisialized?Center(child: CircularProgressIndicator()):Center(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                height: 100,
                width: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
