import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

void main() => runApp(ToDoApp());

class ToDoApp extends StatefulWidget {
  @override
  _ToDoAppState createState() => _ToDoAppState();
}

class _ToDoAppState extends State<ToDoApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
    _saveThemePreference(isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter To-Do List',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ToDoList(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}

class ToDoList extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  ToDoList({required this.isDarkMode, required this.toggleTheme});

  @override
  _ToDoListState createState() => _ToDoListState();
}


class _ToDoListState extends State<ToDoList> {
  List<Map<String, dynamic>> _toDoItems = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  String _selectedCategory = 'Personal';
  final List<String> _categories = ['Personal', 'Work', 'Shopping'];

  final Uuid _uuid = Uuid(); // Generates unique IDs for each task

  @override
  void initState() {
    super.initState();
    _loadToDoList();
  }

  Future<void> _loadToDoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      List<dynamic> decodedList = jsonDecode(tasksJson);
      setState(() {
        _toDoItems = List<Map<String, dynamic>>.from(
            decodedList.map((item) => item as Map<String, dynamic>));
      });
    }
  }

  Future<void> _saveToDoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksJson = jsonEncode(_toDoItems);
    await prefs.setString('tasks', tasksJson);
  }

  void _addToDoItem(String task, String category) {
    if (task.isNotEmpty && category.isNotEmpty) {
      setState(() {
        _toDoItems.add({
          'id': _uuid.v4(),
          'task': task,
          'category': category,
          'isCompleted': false,
        });
      });
      _controller.clear();
      _saveToDoList();
    }
  }

  void _toggleTaskCompletion(String taskId) {
    setState(() {
      final task = _toDoItems.firstWhere((item) => item['id'] == taskId);
      task['isCompleted'] = !task['isCompleted'];
    });
    _saveToDoList();
  }

  void _removeToDoItem(String taskId) {
    setState(() {
      _toDoItems.removeWhere((item) => item['id'] == taskId);
    });
    _saveToDoList();
  }

  void _toggleAllTasksCompletion(String category, bool isCompleted) {
    setState(() {
      for (var task
          in _toDoItems.where((item) => item['category'] == category)) {
        task['isCompleted'] = isCompleted;
      }
    });
    _saveToDoList();
  }

  Widget _buildToDoItem(Map<String, dynamic> task) {
    return ListTile(
      leading: Checkbox(
        value: task['isCompleted'],
        onChanged: (bool? value) {
          _toggleTaskCompletion(task['id']);
        },
      ),
      title: Text(
        task['task'],
        style: TextStyle(
          decoration: task['isCompleted']
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _removeToDoItem(task['id']),
      ),
    );
  }

  Widget _buildToDoList() {
    Map<String, List<Map<String, dynamic>>> categorizedTasks = {};
    for (var task in _toDoItems) {
      String category = task['category'];
      if (categorizedTasks[category] == null) {
        categorizedTasks[category] = [];
      }
      categorizedTasks[category]?.add(task);
    }

    List<Widget> taskWidgets = [];
    categorizedTasks.forEach((category, tasks) {
      bool allCompleted = tasks.every((task) => task['isCompleted']);
      taskWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  TextButton(
                    onPressed: () {
                      _toggleAllTasksCompletion(category, !allCompleted);
                    },
                    child: Text(allCompleted ? 'Uncheck All' : 'Check All'),
                  ),
                ],
              ),
              Column(
                children: tasks.map((task) => _buildToDoItem(task)).toList(),
              ),
            ],
          ),
        ),
      );
    });

    return ListView(
      children: taskWidgets.isEmpty
          ? [Center(child: Text('No tasks yet. Add a task!'))]
          : taskWidgets,
    );
  }

  void _addCategory(String category) {
    if (category.isNotEmpty && !_categories.contains(category)) {
      setState(() {
        _categories.add(category);
      });
      _categoryController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          Row(
            children: [
              Icon(widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.toggleTheme,
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 350,
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Enter task',
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add,
                          color: isDarkMode ? Colors.white : Colors.black),
                      onPressed: () {
                        _addToDoItem(_controller.text, _selectedCategory);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  items:
                      _categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black)),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _categoryController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Add new category',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _addCategory(_categoryController.text);
                },
                child: Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.blue,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: _buildToDoList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
