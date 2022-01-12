import 'package:flutter/material.dart';

import 'helpers/sql_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sqflite',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.cyanAccent[900],
        )
      ),
      home: const MyHomePage(title: 'Flutter Sqflite'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // All journals
  List<Map<String, dynamic>> _journals = [];
  /*  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPosition; */

  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  Future<void> _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  Future<void> _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'] as String;
      _descriptionController.text = existingJournal['description'] as String;
    }

    await showModalBottomSheet(
      context: context,
      elevation: 5,
      builder: (_) => Container(
        padding: const EdgeInsets.all(15),
        width: double.infinity,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Description',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                // Save new journal
                if (id == null) {
                  await _addItem();
                }

                if (id != null) {
                  await _updateItem(id);
                }

                // Clear the text fields
                _titleController.text = '';
                _descriptionController.text = '';

                // Close the bottom sheet
                Navigator.of(context).pop();
              },
              child: Text(id == null ? 'Create New' : 'Update'),
            )
          ],
        ),
      ),
    );
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
      _titleController.text,
      _descriptionController.text,
    );
    await _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
      id,
      _titleController.text,
      _descriptionController.text,
    );
    await _refreshJournals();
  }

  void removedItem() {}

  // Delete an item
  // TODO: Adicionar o desmissible e action undo do redo the deleted action.
   Future<void> _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Successfully deleted a journal!',
        ),
      ),
    );
    await _refreshJournals();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) => _scrollToBottom(),
    );
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: const Text(
          'Sqlflite',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _journals.length,
              itemBuilder: (context, index) => Card(
                color: Colors.grey[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  title: Text(
                    _journals[index]['title'].toString(),
                  ),
                  subtitle: Text(
                    _journals[index]['description'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.black,
                          ),
                          onPressed: () => _showForm(
                            _journals[index]['id'] as int,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.black,
                          ),
                          onPressed: () => _deleteItem(
                            _journals[index]['id'] as int,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.add,
        ),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
