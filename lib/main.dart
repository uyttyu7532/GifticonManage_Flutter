import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text('예롱 깊티'),
            ),
            body: Column(
              children: <Widget>[
                TabBar(
                  indicatorColor: Colors.pinkAccent,
                  labelColor: Colors.grey,
                  tabs: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('미사용'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('사용완료'),
                    ),
                  ],
                ),
                Expanded(
                  flex: 1,
                  child: TabBarView(
                    children: [TodoListPage(), TodoListPage()],
                  ),
                )
              ],
            )),
      ),
    );
  }
}

class Todo {
  bool isDone;
  String title;
  Timestamp expired;
  Timestamp used;

  Todo(this.title, {this.expired, this.used, this.isDone = false});
}

void _deleteTodo(DocumentSnapshot doc) {
  Firestore.instance.collection('todo').document(doc.documentID).delete();
}

void _toggleTodo(DocumentSnapshot doc) {
  Firestore.instance.collection("todo").document(doc.documentID).updateData({
    'isDone': !doc['isDone'],
  });
}

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  void _showDialog(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          title: new Text("정말로 삭제하시겠습니까?"),
          content: SingleChildScrollView(child: new Text("${doc["title"]}")),
          actions: <Widget>[
            new FlatButton(
              child: new Text("삭제"),
              onPressed: () {
                _deleteTodo(doc);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => AddPage()));
          },
          child: Icon(Icons.add),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
                // 스트림은 자료가 변경되었을 때 반응하여 화면을 다시 그려준다.
                stream: Firestore.instance
                    .collection('todo')
                    // .where('isDone', isEqualTo: false)
                    .orderBy("expired", descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  final documents = snapshot.data.documents;

                  // documents.sort((a, b) => b['isDone']
                  //     ? (a['expired'].compareTo(b['expired']) <= 0 // 사용완료
                  //         ? -1
                  //         : -2) // 오름차순
                  //     : (a['expired'].compareTo(b['expired']) <= 0 // 미사용
                  //         ? 1
                  //         : -3)); // 내림차순

                  // UI 반환
                  return Expanded(
                      child: ListView(
                    children:
                        documents.map((doc) => _buildItemWidget(doc)).toList(),
                  ));
                }),
          ],
        ),
      ),
    ); //
  }

  Widget _buildItemWidget(DocumentSnapshot doc) {
    //FireStore 문서는 DocumentSnapshot 클래스의 인스턴스
    final todo = Todo(doc["title"],
        expired: doc['expired'], used: doc['used'], isDone: doc['isDone']);
    return ListTile(
        onLongPress: () => {_showDialog(doc)},
        onTap: () => {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DetailPage(doc)))
            },
        title: Text(
          todo.title,
          style: todo.isDone
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  fontStyle: FontStyle.italic,
                )
              : null,
        ),
        subtitle: Text(
          DateFormat('yyyy/MM/dd').format(todo.expired.toDate()).toString() +
              " 까지",
        ),
        trailing: FlatButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            color: todo.isDone ? Colors.grey : Colors.pinkAccent,
            textColor: Colors.white,
            child: todo.isDone ? Text("사용완료") : Text("사용하기"),
            onPressed: () => {_toggleTodo(doc)}));
  }
}

class DetailPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const DetailPage(this.doc);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DocumentSnapshot>(
          // 스트림은 자료가 변경되었을 때 반응하여 화면을 다시 그려준다.
          stream: Firestore.instance
              .collection('todo')
              .document(widget.doc.documentID)
              .snapshots(),
          builder: (context, snapshot) {
            final document = snapshot.data;
            // UI 반환
            return _buildDetailWidget(document);
          }),
    );
  }

  Widget _buildDetailWidget(DocumentSnapshot doc) {
    //FireStore 문서는 DocumentSnapshot 클래스의 인스턴스
    final todo = Todo(doc["title"],
        expired: doc['expired'], used: doc['used'], isDone: doc['isDone']);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${todo.title}',
            style: TextStyle(fontSize: 22),
          ),
          Text(
              '유효기간: ${DateFormat('yyyy/MM/dd').format(todo.expired.toDate()).toString()}'),
          (todo.used != null) ? Text('사용날짜: ${todo.used}') : Text(""),
          FlatButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            color: todo.isDone ? Colors.grey : Colors.pinkAccent,
            textColor: Colors.white,
            onPressed: () => {_toggleTodo(doc)},
            child: todo.isDone ? Text("사용완료") : Text("사용하기"),
          ),
          SizedBox(
              width: 300,
              height: 300,
              child: Image.network('https://picsum.photos/250?image=9')),
        ],
      ),
    );
  }
}

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  var _todoController = TextEditingController();
  DateTime _selectedDate;

  void _addTodo(Todo todo) {
    Firestore.instance.collection('todo').add(
        {'title': todo.title, 'expired': todo.expired, 'isDone': todo.isDone});
    _todoController.text = "";
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text('기프티콘 추가하기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    decoration: new InputDecoration(
                                        contentPadding: const EdgeInsets.only(
                                            left: 14.0, bottom: 8.0, top: 8.0),
                                        border: new OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                            borderSide: new BorderSide(
                                                color: Colors.teal)),
                                        hintText: 'ex) 스타벅스 아메리카노'),
                                    controller: _todoController,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FlatButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                  color: Colors.pinkAccent,
                                  textColor: Colors.white,
                                  onPressed: () => {
                                    Navigator.pop(context),
                                    _addTodo(Todo(_todoController.text,
                                        expired: Timestamp
                                            .fromMillisecondsSinceEpoch(
                                                _selectedDate
                                                    .millisecondsSinceEpoch))),
                                    setState(() {
                                      _selectedDate = null;
                                    }),
                                  },
                                  child: Text("등록하기"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Future<DateTime> selectedDate = showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2050),
                                  builder:
                                      (BuildContext context, Widget child) {
                                    return Theme(
                                      data: ThemeData.light(),
                                      child: child,
                                    );
                                  });
                              selectedDate.then((date) => setState(() {
                                    _selectedDate = date;
                                  }));
                            },
                            child: Row(
                              children: [
                                IconButton(
                                  color: Colors.pinkAccent,
                                  icon: Icon(Icons.calendar_today_sharp),
                                  onPressed: () {
                                    Future<DateTime> selectedDate =
                                        showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2050),
                                            builder: (BuildContext context,
                                                Widget child) {
                                              return Theme(
                                                data: ThemeData.light(),
                                                child: child,
                                              );
                                            });
                                    selectedDate.then((date) => setState(() {
                                          _selectedDate = date;
                                        }));
                                  },
                                ),
                                if (_selectedDate != null)
                                  Text(
                                      '선택된 유효 기간: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}')
                                else
                                  Text('유효 기간 고르기'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Row(
                              children: [
                                IconButton(
                                  color: Colors.pinkAccent,
                                  icon: Icon(
                                      Icons.photo_size_select_actual_outlined),
                                  onPressed: () => {},
                                ),
                                Text('사진 고르기'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Image.network('https://picsum.photos/1000?image=5')
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    ); //
  }
}
