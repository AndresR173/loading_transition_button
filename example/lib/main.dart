import 'package:flutter/material.dart';
import 'package:loading_transition_button/loading_transition_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key key}) : super(key: key);
  final _controller = LoadingButtonController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            width: double.infinity,
            color: Colors.black26,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 44,
                  width: 300,
                  child: LoadingButton(
                    color: Colors.blue,
                    onSubmit: () => print('onSubmit'),
                    controller: _controller,
                    minWidth: 44,
                    child: Text('Hit me!'),
                  ),
                ),
                SizedBox(height: 100),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RaisedButton(
                      onPressed: () => _controller.startLoadingAnimation(),
                      child: Text('Start'),
                    ),
                    RaisedButton(
                      onPressed: () => _controller.stopLoadingAnimation(),
                      child: Text('Stop'),
                    ),
                    RaisedButton(
                      onPressed: () => _controller.onError(),
                      child: Text('Error'),
                    ),
                    RaisedButton(
                      onPressed: () => _controller.moveToScreen(
                          context: context, page: SearchPage()),
                      child: Text('Next screen'),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    ));
  }
}

class SearchPage extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pink,
        title: TextField(
          decoration: InputDecoration.collapsed(hintText: "Search"),
        ),
      ),
    );
  }
}
