import 'package:flutter/material.dart'; 

import 'package:fl_chart/fl_chart.dart'; 

 

void main() { 

  runApp(MyApp()); 

} 

 

class MyApp extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return MaterialApp( 

      title: 'Icons, Images & Charts Demo', 

      theme: ThemeData(primarySwatch: Colors.teal), 

      home: HomeScreen(), 

    ); 

  } 

} 

 

class HomeScreen extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return Scaffold( 

      appBar: AppBar( 

        title: Text('Flutter UI Elements'), 

        centerTitle: true, 

      ), 

      body: SingleChildScrollView( 

        child: Column( 

          children: [ 

            // ICON SECTION 

            Padding( 

              padding: const EdgeInsets.all(16.0), 

              child: Row( 

                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 

                children: const [ 

                  Icon(Icons.home, color: Colors.blue, size: 40), 

                  Icon(Icons.favorite, color: Colors.red, size: 40), 

                  Icon(Icons.settings, color: Colors.grey, size: 40), 

                ], 

              ), 

            ), 

 

            // IMAGE SECTION 

            Padding( 

              padding: const EdgeInsets.all(16.0), 

              child: Column( 

                children: [ 

                  Text("Flutter Logo from Asset", style: TextStyle(fontSize: 18)), 

                  SizedBox(height: 10), 

                  Image.asset('assets/flutter_logo.png', height: 100), 

                  SizedBox(height: 20), 

                  Text("Image from Network", style: TextStyle(fontSize: 18)), 

                  SizedBox(height: 10), 

                  Image.network( 

                    'https://flutter.dev/images/flutter-logo-sharing.png', 

                    height: 100, 

                  ), 

                ], 

              ), 

            ), 

 

            // CHART SECTION 

            Padding( 

              padding: const EdgeInsets.all(16.0), 

              child: Column( 

                children: [ 

                  Text("Simple Bar Chart", style: TextStyle(fontSize: 18)), 

                  SizedBox(height: 200, child: SimpleBarChart()), 

                ], 

              ), 

            ), 

          ], 

        ), 

      ), 

    ); 

  } 

} 

 

class SimpleBarChart extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return BarChart( 

      BarChartData( 

        alignment: BarChartAlignment.spaceAround, 

        barGroups: [ 

          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: Colors.blue)]), 

          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 7, color: Colors.orange)]), 

          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 6, color: Colors.green)]), 

        ], 

        titlesData: FlTitlesData(show: false), 

        borderData: FlBorderData(show: false), 

      ), 

    ); 

  } 

} 

 

 

 

 