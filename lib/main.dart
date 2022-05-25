// dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

// packages
import 'package:flutter/material.dart';
import 'package:docking/docking.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_size/window_size.dart';


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
    return const MyHomePage(title: 'Pychart Editor');
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

class PychartFile {
    String name;
    String directoryPath;
    File file;

    PychartFile({required this.name, required this.directoryPath, required this.file});

    Future<File> write(String s) async {
        return file.writeAsString(s);
    }
}


class _MyHomePageState extends State<MyHomePage> {
    ThemeProvider theme = ThemeProvider.provider;
    EditorData data = EditorData();
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
    String? programOutput = "";
    String? programErrors = "";
    PychartFile ?currentFile;
    bool compileAsBytecode = false;

    @override
    void initState() {
        super.initState();
        _prefs.then((SharedPreferences prefs) {
            setState((){ 
                theme.init(prefs); 
                data.init(prefs);
                data.controller.text = "// Write your code here";
                compileAsBytecode = prefs.getBool('compile_as_bytecode') ?? false;
            });
        });
    }

    get output => Text(
        programOutput ?? (programErrors ?? ""),
        style: programErrors == null ? null: const TextStyle(color: Colors.red)
    );

    String getDirectoryFromFilePath(String path) {
        var i = path.length - 1;
        while (!(path[i] == '\\' || path[i] == '/') && i >= 0) {
            i--;
        }
        return path.substring(0, i == -1 ? 0 : i);
    }

    void onOpen() async {
        String? fileDirectory = "";
        String fileName = "";
        // If no file is selected, opens file explorer
        final result = await FilePicker.platform.pickFiles();
        if (result == null) return;

        PlatformFile platformFile = result.files.first;

        if ( platformFile.extension == 'pych')
        {
            fileDirectory = getDirectoryFromFilePath(platformFile.path ?? "${Directory.current}/");
            fileName = platformFile.name;

            // Open the file
            currentFile = PychartFile(
                    name: fileName,
                    directoryPath: fileDirectory,
                    file: File(platformFile.path!));
            // Save the contents to the file
            await currentFile!.write(data.controller.text);

            setState(() { 
                    SharedPreferences.getInstance().then((value) {
                        data.save(value);
                        });
                    });

            const snackBar = SnackBar(
                    content: Text('File saved successfuly', style: TextStyle(fontSize: 15.0, color: Colors.white)),
                    duration: Duration(seconds: 2), backgroundColor: Colors.green);
            _scaffoldKey.currentState!.showSnackBar(snackBar);
        }
        else
        {
            const snackBar = SnackBar(
                    content: Text('Error: File extension must be .pych', style: TextStyle(fontSize: 15.0, color: Colors.white)),
                    duration: Duration(seconds: 2), backgroundColor: Colors.red);
            _scaffoldKey.currentState!.showSnackBar(snackBar);
        }
    }

    void onSave() async {
        if (currentFile != null) {
            await currentFile!.write(data.controller.text);

            const snackBar = SnackBar(
                content: Text('File saved successfully', style: TextStyle(fontSize: 15.0, color: Colors.white)), 
                duration: Duration(seconds: 2), backgroundColor: Colors.green);
            _scaffoldKey.currentState?.showSnackBar(snackBar);
        } else {
            onOpen();
        }
    }

    void onRun() async {
        if (currentFile != null) {
            await currentFile!.write(data.controller.text);
        }
        final text = data.controller.text;
        if (kDebugMode) {
            print("\n$text");
        }

        List<String> args = ['pychart/main.py'];
        if (compileAsBytecode) args.add('--bytecode');
        args.addAll(['-run', text]);

        final result = await Process.run('./python/python.exe', args);

        if (kDebugMode) {
            var s = "\nRan program (python";
            for (final arg in args) {
                if (arg.contains('\n')) { 
                    s += " \$contents";
                    continue;
                }
                s += " $arg";
            }
            s += "):\n";
            s += "$text\n";
            s += "and got output:\n";
            s += "${result.stdout}";
            s += "with errors:\n";
            s += "${result.stderr}";

            print(s);
        }
        if (result.stdout != "") {
            programOutput = result.stdout;
            programErrors = null;
        } else if (result.stderr != "") {
            programErrors = result.stderr;
            programOutput = null;
        }
        setState(() { 
                SharedPreferences.getInstance().then((value){
                        data.save(value);
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
        setWindowTitle("Pychart Integrated Development Enviroment");

        return 
            MaterialApp(
                scaffoldMessengerKey: _scaffoldKey,
                debugShowCheckedModeBanner: false,
                theme: theme.material,
                home: Scaffold(
                    //resizeToAvoidBottomInset: false,
                    appBar: AppBar(
                        title: Text(widget.title),
                        actions: [
                            PopupMenuButton( 
                                icon: const Icon(Icons.settings),
                                onSelected: (int n){ 
                                    setState(() { 
                                        SharedPreferences.getInstance().then((prefs){
                                            compileAsBytecode = !compileAsBytecode;
                                            prefs.setBool('compile_as_bytecode', compileAsBytecode);
                                        });
                                    });
                                },
                                itemBuilder: (BuildContext ctx) => <PopupMenuEntry<int>>[
                                    CheckedPopupMenuItem<int>(
                                        checked: compileAsBytecode,
                                        value: 0,
                                        child: const Text("Compile as bytecode"),
                                    )
                                ]
                            ),
                            Tooltip( 
                                message: theme.isDarkMode ? 'light mode' : 'dark mode', 
                                child: IconButton(
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
                            ),
                            Tooltip( 
                                message: 'open', 
                                child: IconButton(
                                    icon: const Icon(Icons.upload_file),
                                    onPressed: onOpen
                                ),
                            ),
                            Tooltip( 
                                message: 'save', 
                                child: IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: onSave
                                )
                            ),
                            TextButton(  
                                onPressed: onRun,
                                child: const Text('Run', style: TextStyle(fontSize: 15.0, color: Colors.white))
                            ) 
                        ],
                        bottom: PreferredSize ( 
                            preferredSize: const Size.fromHeight(4.0),
                            child: Text('Opened file: ${currentFile?.name ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, color:Colors.white))
                        ),
                    ),
                    /*body: Container (
                        decoration: new BoxDecoration(
                            shape: BoxShape.rectangle,
                            border: new Border.all(
                            color: theme.material.primaryColorLight,
                            width: 12.0,
                            ),
                        ),
                        child: EditorWidget(data:data)
                    ), 
                    bottomSheet: Container(
                        decoration: new BoxDecoration(
                            shape: BoxShape.rectangle,
                            border: new Border.all(
                            color: theme.material.primaryColorLight,
                            width: 12.0,
                            ),
                        ),
                        constraints: BoxConstraints(maxHeight: 175),
                        child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Text('Console Output:\n' + consoleOutput)
                        ),
                        //child: Text('Console Output:\n' + consoleOutput), 
                        //color: Colors.grey[850],
                        height: 175,
                        width: double.infinity
                    ) */
                    body: SingleChildScrollView ( // to get rid of bottom overflow by x pixels error
                        child: Column (
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                Container (
                                    padding: const EdgeInsets.all(10.0),
                                    width: double.infinity,
                                    constraints: const BoxConstraints(maxHeight: 400),
                                    child: EditorWidget(data: data)
                                ),
                                Container (
                                    padding: const EdgeInsets.all(10.0),
                                    constraints: const BoxConstraints(maxHeight: 250),
                                    width:double.infinity,
                                    child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Column (
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children:<Widget>[
                                            const Text('Console Output:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            output
                                        ],)
                                    )
                                ) 
                            ]
                        )
                    )
                    /*Container (
                        child: Column (
                            children: [
                                Container (
                                    //margin: const EdgeInsets.only(bottom: 250.0),
                                    //constraints: BoxConstraints(minHeight: 700, maxHeight: 700),
                                    //alignment: Alignment.topCenter,	
                                    child: EditorWidget(data:data),
                                    //height: 700,
                                ),
                                Container(
                                    //padding: const EdgeInsets.only(top: 25.0),
                                    //margin: const EdgeInsets.only(top: 250.0),
                                    //alignment: Alignment.topLeft,
                                    //constraints: BoxConstraints(minHeight: 300, maxHeight: 300),
                                    child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Text('Console Output:\n' + consoleOutput)
                                    ),
                                    //height: 300,
                                    //width: double.infinity
                                )
                            ]
                        )
                    )*/
                )
            );
    }
}



