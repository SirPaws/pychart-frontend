// dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

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


class _MyHomePageState extends State<MyHomePage> {
    ThemeProvider theme = ThemeProvider.provider;
    EditorData data = EditorData();
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    String consoleOutput = "";
    String? fileDirectory = "";
    String fileName = "";
    final _scaffoldKey = new GlobalKey<ScaffoldState>();
    

    @override
    void initState() {
        super.initState();
        _prefs.then((SharedPreferences prefs) {
            setState((){ 
                theme.init(prefs); 
                data.init(prefs);
                data.controller.text = "// Write your code here";
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
                debugShowCheckedModeBanner: false,
                theme: theme.material,
                home: Scaffold(
                    key: _scaffoldKey,
                    //resizeToAvoidBottomInset: false,
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
                            ),
                            IconButton(
                                icon: const Icon(Icons.upload_file),
                                onPressed: () async { 
                                    final result = await FilePicker.platform.pickFiles();

                                    if ( result != null)
                                    {
                                        PlatformFile platformFile = result.files.first;

                                        if ( platformFile.extension == 'pych')
                                        {
                                            fileDirectory = platformFile.path;
                                            //fileDirectory = fileDirectory!.replaceAll('\\','/');
                                            // Subtract the file name from the file directory
                                            for (var i = 0; i < fileDirectory!.length; i++) {
                                                if ( fileDirectory![fileDirectory!.length - i - 1] == '\\')
                                                {
                                                    fileDirectory = fileDirectory!.substring(0, fileDirectory!.length - i - 1);
                                                    break;
                                                }
                                            }
                                            // Set the file name
                                            fileName = platformFile.name;
                                            // Set the current directory to the directory of the file
                                            if ( Directory.current != fileDirectory)
                                            {
                                                Directory.current = fileDirectory;
                                            }
                                            // Open the file
                                            File file = File(fileName);
                                            // Get the contents of the file
                                            final contents = await file.readAsString();
                                            
                                            // Set the Editor contents
                                            data.controller.text = contents;
                                            setState(() { 
                                                SharedPreferences.getInstance().then((value) {
                                                data.save(value);
                                                });
                                            });

                                            final snackBar = SnackBar(content: new Text('File uploaded successfuly', style: TextStyle(fontSize: 15.0, color: Colors.white)), duration: new Duration(seconds: 2), backgroundColor: Colors.green);
                                            _scaffoldKey.currentState!.showSnackBar(snackBar);
                                        }
                                        else
                                        {
                                            final snackBar = SnackBar(content: new Text('Error: File extension must be .pych', style: TextStyle(fontSize: 15.0, color: Colors.white)), duration: new Duration(seconds: 2), backgroundColor: Colors.red);
                                            _scaffoldKey.currentState!.showSnackBar(snackBar);
                                        }
                                    }
                                }
                            ),
                            IconButton(
                                icon: const Icon(Icons.save),
                                onPressed: () async
                                { 
                                    if ( fileName != "")
                                    {
                                        if ( Directory.current != fileDirectory)
                                        {
                                            Directory.current = fileDirectory;
                                        }
                                        // Open the file
                                        File file = File(fileName);
                                        await file.writeAsString(data.controller.text);

                                        final snackBar = SnackBar(content: new Text('File saved successfully', style: TextStyle(fontSize: 15.0, color: Colors.white)), duration: new Duration(seconds: 2), backgroundColor: Colors.green);
                                        _scaffoldKey.currentState!.showSnackBar(snackBar);
                                    }
                                    // If no file is selected, opens file explorer
                                    else
                                    {
                                        final result = await FilePicker.platform.pickFiles();

                                        if ( result != null)
                                        {
                                            PlatformFile platformFile = result.files.first;

                                            if ( platformFile.extension == 'pych')
                                            {
                                                fileDirectory = platformFile.path;
                                                //fileDirectory = fileDirectory!.replaceAll('\\','/');
                                                // Subtract the file name from the file directory
                                                for (var i = 0; i < fileDirectory!.length; i++) {
                                                    if ( fileDirectory![fileDirectory!.length - i - 1] == '\\')
                                                    {
                                                        fileDirectory = fileDirectory!.substring(0, fileDirectory!.length - i - 1);
                                                        break;
                                                    }
                                                }
                                                // Set the file name
                                                fileName = platformFile.name;
                                                // Set the current directory to the directory of the file
                                                if ( Directory.current != fileDirectory)
                                                {
                                                    Directory.current = fileDirectory;
                                                }
                                                // Open the file
                                                File file = File(fileName);
                                                // Save the contents to the file
                                                await file.writeAsString(data.controller.text);
                                                
                                                setState(() { 
                                                    SharedPreferences.getInstance().then((value) {
                                                    data.save(value);
                                                    });
                                                });

                                                final snackBar = SnackBar(content: new Text('File saved successfuly', style: TextStyle(fontSize: 15.0, color: Colors.white)), duration: new Duration(seconds: 2), backgroundColor: Colors.green);
                                                _scaffoldKey.currentState!.showSnackBar(snackBar);
                                            }
                                            else
                                            {
                                                final snackBar = SnackBar(content: new Text('Error: File extension must be .pych', style: TextStyle(fontSize: 15.0, color: Colors.white)), duration: new Duration(seconds: 2), backgroundColor: Colors.red);
                                                _scaffoldKey.currentState!.showSnackBar(snackBar);
                                            }
                                        }

                                        //final snackBar = SnackBar(content: new Text('Unable to save file', style: TextStyle(fontSize: 15.0, color: Colors.white)), duration: new Duration(seconds: 2), backgroundColor: Colors.red);
                                        //_scaffoldKey.currentState!.showSnackBar(snackBar);
                                    }
                                } 
                            ),
                            FlatButton(  
                                child: Text('Compile', style: TextStyle(fontSize: 15.0, color: Colors.white)),
                                onPressed: () {}
                            ),
                            FlatButton(  
                                child: Text('Run', style: TextStyle(fontSize: 15.0, color: Colors.white),),  
                                onPressed: () async {
                                    if ( fileName != "")
                                    {
                                        // First save the contents to the file
                                        if ( Directory.current != fileDirectory)
                                        {
                                            Directory.current = fileDirectory;
                                        }
                                        // Open the file
                                        File workingFile = File(fileName);
                                        await workingFile.writeAsString(data.controller.text);

                                        // The directories will be replaced with pychart code directory such as compiler/pychart etc.
                                        Directory.current = new Directory('D:/Bilkent/2021-2022 Spring (RUC)/Courses/Subject Module In Computer Science/Code/pychart');
                                        final Directory directory = await getApplicationDocumentsDirectory();
                                        final File file = File('D:/Bilkent/2021-2022 Spring (RUC)/Courses/Subject Module In Computer Science/Code/pychart/test.pych');
                                        await file.writeAsString(data.controller.text);
                                        var result = await Process.run('python', ['main.py', 'test.pych']);
                                        consoleOutput = result.stdout;
                                        setState(() { 
                                            SharedPreferences.getInstance().then((value){
                                                data.save(value);
                                            });
                                        });
                                    }
                                    else
                                    {
                                        final snackBar = SnackBar(content: new Text('Error: Please upload a file to run', style: TextStyle(fontSize: 15.0, color: Colors.white)), duration: new Duration(seconds: 2), backgroundColor: Colors.red);
                                        _scaffoldKey.currentState!.showSnackBar(snackBar);
                                    }
                                }) 
                        ],
                        bottom: PreferredSize ( child: Container (child:Text('Opened file: ' + fileName, style: TextStyle(fontWeight: FontWeight.bold, color:Colors.white))), preferredSize: Size.fromHeight(4.0))
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
                        child:Column (
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                Container (
                                    padding: EdgeInsets.all(10.0),
                                    width:double.infinity,
                                    child:EditorWidget(data:data),
                                    constraints: BoxConstraints(maxHeight: 400)
                                ),
                                Container (
                                    padding: EdgeInsets.all(10.0),
                                    constraints: BoxConstraints(maxHeight: 250),
                                    width:double.infinity,
                                    child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Column (
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children:<Widget>[
                                            Text('Console Output:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Text(consoleOutput)
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



