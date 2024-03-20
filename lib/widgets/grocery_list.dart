import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'flutter-prep-84353-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);

      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere((catItem) =>
                catItem.value.categoryName == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void removeItem(int index) async {
    var currItem = _groceryItems[index];

    setState(() {
      _groceryItems.remove(currItem);
    });

    final url = Uri.https(
      'flutter-prep-84353-default-rtdb.firebaseio.com',
      'shopping-list/${currItem.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Can\'t delete it, Something went wrong'),
        ),
      );
      setState(() {
        _groceryItems.insert(index, currItem);
      });
    }

    // ScaffoldMessenger.of(context).clearSnackBars;
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     duration: const Duration(seconds: 2),
    //     content: const Text('Item deleted'),
    //     action: SnackBarAction(
    //       label: 'Undo',
    //       onPressed: () {
    //         setState(() {
    //           _groceryItems.add(currItem);
    //         });
    //       },
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = const Center(
      child: Text(
        "You got no items yet",
        style: TextStyle(fontSize: 24),
      ),
    );

    if (_isLoading) {
      bodyContent = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      bodyContent = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            removeItem(index);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.categoryColor,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      bodyContent = Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 24),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
