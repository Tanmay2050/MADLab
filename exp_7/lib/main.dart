import 'package:flutter/material.dart'; 

 

void main() { 

  runApp(MyApp()); 

} 

 

class MyApp extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return MaterialApp( 

      title: 'Navigation & Gestures Demo', 

      theme: ThemeData(primarySwatch: Colors.teal), 

      initialRoute: '/', 

      routes: { 

        '/': (context) => HomeScreen(), 

        '/second': (context) => SecondScreen(), 

      }, 

    ); 

  } 

} 

 

class HomeScreen extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return Scaffold( 

      appBar: AppBar(title: Text('Home Page')), 

      body: Center( 

        child: GestureDetector( 

          onTap: () { 

            Navigator.pushNamed(context, '/second'); 

          }, 

          child: Container( 

            padding: EdgeInsets.all(20), 

            decoration: BoxDecoration( 

              color: Colors.teal, 

              borderRadius: BorderRadius.circular(10), 

            ), 

            child: Text( 

              'Go to Second Page (Tap Me)', 

              style: TextStyle(color: Colors.white, fontSize: 18), 

            ), 

          ), 

        ), 

      ), 

    ); 

  } 

} 

 

class SecondScreen extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return Scaffold( 

      appBar: AppBar(title: Text('Second Page')), 

      body: Center( 

        child: GestureDetector( 

          onDoubleTap: () { 

            Navigator.pop(context); 

          }, 

          child: Container( 

            padding: EdgeInsets.all(20), 

            decoration: BoxDecoration( 

              color: Colors.orange, 

              borderRadius: BorderRadius.circular(10), 

            ), 

            child: Text( 

              'Double Tap to Go Back', 

              style: TextStyle(color: Colors.white, fontSize: 18), 

            ), 

          ), 

        ), 

      ), 

    ); 

  } 

} 

 

 