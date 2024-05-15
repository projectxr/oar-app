import 'dart:ui';
import 'package:app/elements/text_input.dart';
import 'package:app/utils/const.dart';
import 'package:flutter/material.dart';
import 'package:app/messages/generated.dart';
import 'package:app/messages/llm.pb.dart';

void main() async {
  await initializeRust();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late TextEditingController _promptController;
  late Map<int, String> messages = Map.from({0: ""});
  int currentMessageId = 0;

  @override
  void initState() {
    super.initState();
    print("HELLO 123");
    _promptController = TextEditingController();
  }

  final _appLifecycleListener = AppLifecycleListener(
    onExitRequested: () async {
      await finalizeRust();
      return AppExitResponse.exit;
    },
  );

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: MediaQuery.platformBrightnessOf(context),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: StreamBuilder(
                  stream: LlmResult.rustSignalStream,
                  builder: (context, snapshot) {
                    final rustSignal = snapshot.data;
                    if (rustSignal == null) {
                      return const Text("Processing");
                    }
                    final llmResponse = rustSignal.message;
                    if (currentMessageId != llmResponse.messageId) {
                      currentMessageId = llmResponse.messageId;
                      messages.putIfAbsent(llmResponse.messageId, () => "");
                    }

                    messages.update(
                        llmResponse.messageId, (currVal) => '$currVal ${llmResponse.response}');
                    return Column(
                      children: messages.entries.map((element) => Text(element.value)).toList(),
                    );
                  },
                ),
              ),
            ),
            TextInput(
              inputController: _promptController,
              fieldName: 'Prompt',
              icon: Icons.send,
              onPressedIcon: () {
                LlmRequest(prompt: _promptController.text).sendSignalToRust();
                _promptController.text = "";
              },
            )
          ],
        ),
      ),
    );
  }
}
