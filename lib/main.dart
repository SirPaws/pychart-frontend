// dart
import 'dart:async';

// packages
import 'package:flutter/material.dart';
import 'package:docking/docking.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// app 
import 'themeprovider.dart';
import 'editor.dart';
import 'flowchart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MyHomePage(title: 'Some Cool Editor Thingy');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class DockingSpace extends DockingParentArea {
    DockingSpace._(List<DockingArea> children) : super(children);

    factory DockingSpace(List<DockingArea> children) {
        return DockingSpace._(children);
    }
    
    @override
    DockingAreaType get type => DockingAreaType.item;
}


class _MyHomePageState extends State<MyHomePage> {
    ThemeProvider theme = ThemeProvider.provider;
    EditorData data = EditorData();
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

    @override
    void initState() {
        super.initState();
        _prefs.then((SharedPreferences prefs) {
            setState((){ 
                theme.init(prefs); 
                data.init(prefs);
            });
        });
    }

    @override
    Widget build(BuildContext context) {
        // This method is rerun every time setState is called, for instance as done
        // by the _incrementCounter method above.
        //
        // The Flutter framework has been optimized to make rerunning build methods
        // fast, so that you can just rebuild anything that needs updating rather
        // than having to individually change instances of widgets.
        return 
            MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: theme.material,
                home: Scaffold(
                    appBar: AppBar(
                        title: Text(widget.title),
                        actions: [
                            IconButton(
                                icon: const Icon(Icons.dark_mode),
                                onPressed: () { 
                                    setState(() { 
                                        theme.toggle();
                                        SharedPreferences.getInstance().then((value){
                                            theme.save(value);
                                        });
                                    });
                                }
                            )
                        ]
                    ),
                    body: TabbedViewTheme(
                        data: theme.tabbedView,

                        child: //Container(
                            // padding: const EdgeInsets.all(16),
                            /* child: */ Docking(
                                layout: DockingLayout(root: DockingRow([EditorWindow(widget: widget, data: data), FlowChartView(widget)]))
                            )
                        // )
                    )
                )
            );
  }
}



