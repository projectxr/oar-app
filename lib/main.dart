import 'dart:ui';
import 'package:app/elements/text_input.dart';
import 'package:flutter/material.dart';
import 'package:app/messages/generated.dart';
import 'package:app/messages/llm.pb.dart';
import 'package:markdown_widget/markdown_widget.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    LlmReady.rustSignalStream.listen((readyData) {
      if (readyData.message.ready) {
        LlmRequest(prompt: "Hello").sendSignalToRust();
      }
    });
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
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
                        llmResponse.messageId, (currVal) => '$currVal${llmResponse.response}');
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: messages.entries
                          .map((element) => MarkdownBlock(data: element.value))
                          .toList(),
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
