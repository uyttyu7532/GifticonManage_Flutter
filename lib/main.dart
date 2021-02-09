

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할 일 관리',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TodoListPage(),
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

var _todoController = TextEditingController();

void _addTodo(Todo todo) {
  // setState(() {
  //   _items.add(todo);
  //   _todoController.text = "";
  // });
  Firestore.instance.collection('todo').add(
      {'title': todo.title, 'expired': todo.expired, 'isDone': todo.isDone});
  _todoController.text = "";
}

void _deleteTodo(DocumentSnapshot doc) {
  // setState(() {
  //   _items.remove(todo);
  // });
  Firestore.instance.collection('todo').document(doc.documentID).delete();
}

void _toggleTodo(DocumentSnapshot doc) {
  // setState(() {
  //   todo.isDone = !todo.isDone;
  // });
  Firestore.instance.collection("todo").document(doc.documentID).updateData({
    'isDone': !doc['isDone'],
  });
}

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  // final _items = <Todo>[];

  DateTime _selectedDate;

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
        title: Text('예롱 기프티콘'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    color: Colors.pinkAccent,
                    icon: Icon(Icons.calendar_today_sharp),
                    onPressed: () {
                      Future<DateTime> selectedDate = showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2050),
                          builder: (BuildContext context, Widget child) {
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
                ),
                Expanded(
                    child: Column(
                  children: [
                    Column(
                      children: [
                        TextField(
                          controller: _todoController,
                        ),
                        if (_selectedDate != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                '선택된 유효 기간: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}'),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('유효 기간을 선택해주세요'),
                          )
                      ],
                    ),
                  ],
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    color: Colors.pinkAccent,
                    icon: Icon(Icons.add),
                    onPressed: () => {
                      _addTodo(Todo(_todoController.text,
                          expired: Timestamp.fromMillisecondsSinceEpoch(
                              _selectedDate.millisecondsSinceEpoch))),
                      setState(() {
                        _selectedDate = null;
                      })
                    },
                  ),
                )
              ],
            ),
            StreamBuilder<QuerySnapshot>(
                // 스트림은 자료가 변경되었을 때 반응하여 화면을 다시 그려준다.
                stream: Firestore.instance
                    .collection('todo')
                    // .orderBy('isDone', descending: false)
                    // .orderBy("expired", descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  final documents = snapshot.data.documents;

                  documents.sort((a, b) => b['isDone']
                      ? (a['expired'].compareTo(b['expired']) <= 0
                          ? -1
                          : -2) // 오름차순
                      : (a['expired'].compareTo(b['expired']) <= 0
                          ? 2
                          : 1)); // 내림차순

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_sharp),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          SizedBox(
              width: 300,
              height: 300,
              child: Image.network('https://picsum.photos/250?image=9')),
          FlatButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            color: todo.isDone ? Colors.grey : Colors.pinkAccent,
            textColor: Colors.white,
            onPressed: () => {_toggleTodo(doc)},
            child: todo.isDone ? Text("사용완료") : Text("사용하기"),
          ),
        ],
      ),
    );
  }
}
