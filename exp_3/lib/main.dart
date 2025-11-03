import 'package:flutter/material.dart'; 

  

void main() { 

  runApp(MyApp()); 

} 

  

class MyApp extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return MaterialApp( 

      title: 'Flutter UI Example', 

      theme: ThemeData(primarySwatch: Colors.blue), 

      home: Scaffold( 

        appBar: AppBar(title: Text('Flutter UI')), 

        body: Center( 

          child: Column( 

            mainAxisAlignment: MainAxisAlignment.center, 

            children: [ 

              Text('Welcome to Flutter UI!', style: TextStyle(fontSize: 24)), 

              SizedBox(height: 20), 

              Container( 

                color: Colors.amber, 

                padding: EdgeInsets.all(16), 

                child: Text('This is a container widget'), 

              ), 

              SizedBox(height: 20), 

              ElevatedButton( 

                onPressed: () { 

                  print('Button Pressed!'); 

                }, 

                child: Text('Click Me'), 

              ), 

            ], 

          ), 

        ), 

      ), 

    ); 

  } 

} 
 