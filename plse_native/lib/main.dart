import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class Organization {
  String website, address, city, name, phone, resources, zip;

  Organization(List lst) {
    this.name = lst[0];
    this.website = lst[1];
    this.phone = lst[2];
    this.address = lst[3];
    this.city = lst[4];
    this.zip = lst[5].toString();
    this.resources = lst[6];
  }

  @override
  String toString() {
    return this.name;
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'PLSE Resources by State'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Future<String> loadAsset(String path) async {
  return await rootBundle.loadString(path);
}

Future<HashMap> loadCSV() async {
  return loadAsset('assets/out-of-state-res.csv').then((output) {
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter().convert(output);

    // print(rowsAsListOfValues.sublist(1));
    HashMap<String, List<Organization>> map = HashMap();

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      String key = rowsAsListOfValues[i][0];
      if (rowsAsListOfValues[i].sublist(1)[0] == "N/A") {
        continue;
      }
      Organization item = Organization(rowsAsListOfValues[i].sublist(1));
      if (!map.containsKey(key)) {
        map[key] = List<Organization>();
      }

      map[key].add(item);
    }
    return map;
  });
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
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
    // return FutureBuilder<HashMap<dynamic, dynamic>>(
    //   future: loadCSV,
    //   builder: (BuildContext context, AsyncSnapshot<String> snapshot){

    //   });

    return FutureBuilder<HashMap>(
      future: loadCSV(), // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Text('Press button to start.');
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Text('Awaiting result...');
          case ConnectionState.done:
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            // return Scaffold(body: Text('Result: ${snapshot.data}'));
            return ResourcesScreen(
              data: snapshot.data,
            );
        }
        return null; // unreachable
      },
    );
    //   )
    //     appBar: AppBar(
    //       // Here we take the value from the MyHomePage object that was created by
    //       // the App.build method, and use it to set our appbar title.
    //       title: Text(widget.title),
    //     ),
    //     body: Center(
    //       // Center is a layout widget. It takes a single child and positions it
    //       // in the middle of the parent.
    //       child: ListView(
    //         // Column is also layout widget. It takes a list of children and
    //         // arranges them vertically. By default, it sizes itself to fit its
    //         // children horizontally, and tries to be as tall as its parent.
    //         //
    //         // Invoke "debug painting" (press "p" in the console, choose the
    //         // "Toggle Debug Paint" action from the Flutter Inspector in Android
    //         // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
    //         // to see the wireframe for each widget.
    //         //
    //         // Column has various properties to control how it sizes itself and
    //         // how it positions its children. Here we use mainAxisAlignment to
    //         // center the children vertically; the main axis here is the vertical
    //         // axis because Columns are vertical (the cross axis would be
    //         // horizontal).
    //         // mainAxisAlignment: MainAxisAlignment.center,
    //         children: <Widget>[
    //           Text(
    //             'You have pushed the button this many times:',
    //           ),
    //           Text(
    //             '$_counter',
    //             style: Theme.of(context).textTheme.display1,
    //           ),
    //         ],
    //       ),
    //     ),
    //     floatingActionButton: FloatingActionButton(
    //       onPressed: _incrementCounter,
    //       tooltip: 'Increment',
    //       child: Icon(Icons.add),
    //     ), // This trailing comma makes auto-formatting nicer for build methods.
    //   );
    // }
  }
}

class ResourcesScreen extends StatelessWidget {
  HashMap data;

  ResourcesScreen({this.data});

  @override
  Widget build(BuildContext context) {
    var keys = data.keys.toList();
    keys.sort();
    return Scaffold(
      appBar: AppBar(title: Text("PLSE Resources")),
      body: ListView.builder(
          itemCount: keys.length,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: Text(keys.elementAt(index)),
              children: <Widget>[
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: data[keys.elementAt(index)].length,
                  itemBuilder: (context, innerIndex) {
                    var item = data[keys.elementAt(index)][innerIndex];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              org: item,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(item.name),
                      ),
                    );
                    // return ListTile(
                    //   title: data[data.keys.elementAt(index)][innerIndex].name,
                    // );
                  },
                )
              ],
            );
          }),
    );
  }
}

class DetailScreen extends StatelessWidget {
  Organization org;

  DetailScreen({this.org});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(org.name),
      ),
      body: Card(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              ListTile(
                  title: Text(org.name),
                  subtitle: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Text(org.address),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text('${org.city} ${org.zip}'),
                      SizedBox(
                        height: 10.0,
                      ),
                      Linkify(
                        onOpen: (link) async {
                          if (await canLaunch(link.url)) {
                            await launch(link.url);
                          } else {
                            throw 'Could not launch $link';
                          }
                        },
                        text: org.website,
                      ),
                      // Text(org.website),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(org.phone),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(org.resources),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
