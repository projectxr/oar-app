import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app/elements/text_input.dart';
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
  int copyCurrentMessageId = 0;
  String _path = "";
  bool _enabled = true;
  final ScrollController _scrollController = ScrollController();
  late List<String> _mySomething = [
    "You're a Young Inspired personal Assistant who loves to help!",
    "You're a Marketing Manager who has done well in the professional career, very helpful and knowledgeable!",
    "You're the best programmer in Rust and Flutter (Dart) and write neat code! You're here to help!"
  ];

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    //takePermission();
    LlmReady.rustSignalStream.listen((readyData) {
      if (readyData.message.ready) {
        LlmRequest(prompt: _mySomething[2]).sendSignalToRust();
        setState(() {
          _path = readyData.message.data;
        });
      }
    });
    LlmResult.rustSignalStream.listen((data) {
      if (data.message.messageId != copyCurrentMessageId) {
        setState(() {
          _enabled = true;
        });
      }
    });
  }

  Future<void> takePermission() async {
    await [
      Permission.manageExternalStorage,
      Permission.storage,
    ].request();
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
        home: SafeArea(
          child: Scaffold(
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
                          return Text("Loading usually takes a few minutes! $_path");
                        }
                        final llmResponse = rustSignal.message;

                        if (currentMessageId != llmResponse.messageId) {
                          currentMessageId = llmResponse.messageId;
                          setState(() {
                            _enabled = true;
                          });
                          messages.addAll({llmResponse.messageId: ""});
                        }

                        messages.update(
                            llmResponse.messageId, (currVal) => '$currVal${llmResponse.response}');
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: messages.entries
                              .map((element) => MarkdownBlock(
                                    data: element.value,
                                    config: Theme.of(context).brightness == Brightness.dark
                                        ? MarkdownConfig.darkConfig
                                        : MarkdownConfig.defaultConfig,
                                  ))
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
                  enabled: _enabled,
                  onPressedIcon: () {
                    LlmRequest(prompt: _promptController.text).sendSignalToRust();
                    _promptController.text = "";
                    setState(() {
                      _enabled = false;
                    });
                  },
                )
              ],
            ),
          ),
        ));
  }
}
