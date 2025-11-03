import 'package:flutter/material.dart'; 

 

void main() { 

  runApp(LayoutApp()); 

} 

 

class LayoutApp extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return MaterialApp( 

      title: 'Flutter Layout Example', 

      theme: ThemeData(primarySwatch: Colors.teal), 

      home: Scaffold( 

        appBar: AppBar( 

          title: Text('Layout Widgets'), 

        ), 

        body: Column( 

          children: [ 

            Container( 

              width: double.infinity, 

              height: 100, 

              color: Colors.amber, 

              alignment: Alignment.center, 

              child: Text( 

                'Header Section', 

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 

              ), 

            ), 

            Expanded( 

              child: Row( 

                children: [ 

                  Container( 

                    width: 100, 

                    color: Colors.blueAccent, 

                    child: Center( 

                      child: Text( 

                        'Side Menu', 

                        style: TextStyle(color: Colors.white), 

                      ), 

                    ), 

                  ), 

                  Expanded( 

                    child: Container( 

                      color: Colors.grey[200], 

                      child: Center( 

                        child: Text( 

                          'Main Content Area', 

                          style: TextStyle(fontSize: 18), 

                        ), 

                      ), 

                    ), 

                  ), 

                ], 

              ), 

            ), 

            Container( 

              width: double.infinity, 

              height: 60, 

              color: Colors.green, 

              alignment: Alignment.center, 

              child: Text( 

                'Footer Section', 

                style: TextStyle(fontSize: 18, color: Colors.white), 

              ), 

            ), 

          ], 

        ), 

      ), 

    ); 

  } 

} 