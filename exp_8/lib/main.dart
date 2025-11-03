import 'dart:convert'; 

import 'dart:io'; 

import 'package:flutter/material.dart'; 

import 'package:path_provider/path_provider.dart'; 

 

void main() { 

  runApp(MyApp()); 

} 

 

class MyApp extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return MaterialApp( 

      title: 'File Handling Demo', 

      theme: ThemeData(primarySwatch: Colors.teal), 

      home: FileDemoScreen(), 

    ); 

  } 

} 

 

class FileDemoScreen extends StatefulWidget { 

  @override 

  _FileDemoScreenState createState() => _FileDemoScreenState(); 

} 

 

class _FileDemoScreenState extends State<FileDemoScreen> { 

  TextEditingController _controller = TextEditingController(); 

  String _fileContent = ""; 

 

  // Get file directory 

  Future<File> getFile() async { 

    final directory = await getApplicationDocumentsDirectory(); 

    return File('${directory.path}/userdata.json'); 

  } 

 

  // Write data to file 

  Future<void> writeToFile(String data) async { 

    final file = await getFile(); 

    await file.writeAsString(jsonEncode({'user_input': data})); 

  } 

 

  // Read data from file 

  Future<void> readFromFile() async { 

    try { 

      final file = await getFile(); 

      String content = await file.readAsString(); 

      setState(() { 

        _fileContent = jsonDecode(content)['user_input']; 

      }); 

    } catch (e) { 

      setState(() { 

        _fileContent = "No data found!"; 

      }); 

    } 

  } 

 

  @override 

  Widget build(BuildContext context) { 

    return Scaffold( 

      appBar: AppBar(title: Text('File Handling & Libraries')), 

      body: Padding( 

        padding: const EdgeInsets.all(16.0), 

        child: Column( 

          children: [ 

            TextField( 

              controller: _controller, 

              decoration: InputDecoration( 

                labelText: "Enter some text", 

                border: OutlineInputBorder(), 

              ), 

            ), 

            SizedBox(height: 20), 

            ElevatedButton( 

              onPressed: () async { 

                await writeToFile(_controller.text); 

                _controller.clear(); 

              }, 

              child: Text("Save to File"), 

            ), 

            SizedBox(height: 10), 

            ElevatedButton( 

              onPressed: readFromFile, 

              child: Text("Read from File"), 

            ), 

            SizedBox(height: 20), 

            Text( 

              "File Content: $_fileContent", 

              style: TextStyle(fontSize: 16, color: Colors.black87), 

            ), 

          ], 

        ), 

      ), 

    ); 

  } 

} 

 

 

 