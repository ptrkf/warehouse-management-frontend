import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/token_service.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  int? _dimX;
  int? _dimY;
  int? _dimZ;

  List<Category> _availableCategories = [];
  List<int> _selectedCategoryIds = [];
  bool _isLoadingCategories = true;
  String? _categoryLoadError;

  final String _apiProductUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/products';
  final String _apiCategoryUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/categories';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final token = await TokenService.getToken();

    if (token == null) {
      if (mounted) {
        setState(() {
          _categoryLoadError = "Brak tokena autoryzacji.";
          _isLoadingCategories = false;
        });
      }
      return;
    }

    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(_apiCategoryUrl), headers: headers);
      
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          setState(() {
            _availableCategories = jsonList.map((item) => Category.fromJson(item)).toList();
            _isLoadingCategories = false;
          });
        } else {
          setState(() {
            _categoryLoadError = 'Nie udało się załadować kategorii: ${response.statusCode}';
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryLoadError = 'Błąd sieci podczas ładowania kategorii.';
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wybierz przynajmniej jedną kategorię.')),
        );
        return;
      }
      
      final Map<String, dynamic> productData = {
        'name': _name,
        'dimensions': {
          'x': _dimX,
          'y': _dimY,
          'z': _dimZ,
        },
        'categoryIds': _selectedCategoryIds,
      };

      final token = await TokenService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd: Wymagane jest zalogowanie.')),
        );
        return; 
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      try {
        final response = await http.post(
          Uri.parse(_apiProductUrl),
          headers: headers,
          body: json.encode(productData),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produkt dodany pomyślnie!')),
          );
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd dodawania: ${response.statusCode} - ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd sieci: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj Nowy Produkt'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nazwa Produktu',
                  hintText: 'Np. Laptop X-100',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nazwa jest wymagana.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 20),

              const Text('Wymiary (w milimetrach):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _buildDimensionField('X', (val) => _dimX = val)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDimensionField('Y', (val) => _dimY = val)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDimensionField('Z', (val) => _dimZ = val)),
                ],
              ),
              const SizedBox(height: 30),

              const Text('Kategorie (wymagane):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _categoryLoadError != null
                      ? Text(_categoryLoadError!, style: const TextStyle(color: Colors.red))
                      : Column(
                          children: _availableCategories.map((category) {
                            return CheckboxListTile(
                              title: Text(category.name),
                              value: _selectedCategoryIds.contains(category.id),
                              onChanged: (bool? isChecked) {
                                setState(() {
                                  if (isChecked == true) {
                                    _selectedCategoryIds.add(category.id);
                                  } else {
                                    _selectedCategoryIds.remove(category.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'DODAJ PRODUKT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDimensionField(String label, Function(int?) onSave) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Wym.';
        }
        if (int.tryParse(value) == null) {
          return 'Liczba.';
        }
        return null;
      },
      onSaved: (value) {
        onSave(int.tryParse(value ?? ''));
      },
    );
  }
}