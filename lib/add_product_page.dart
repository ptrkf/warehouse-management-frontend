import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _locationController = TextEditingController();
  final _codeController = TextEditingController();
  final _dimensionsController = TextEditingController();
  
  // Kategorie z API
  List<Category> _availableCategories = [];
  List<int> _selectedCategoryIds = [];
  bool _isLoadingCategories = true;
  String? _categoryLoadError;
  
  bool _isLoading = false;

  final String _apiCategoryUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/categories';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _locationController.dispose();
    _codeController.dispose();
    _dimensionsController.dispose();
    super.dispose();
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
          _categoryLoadError = 'Błąd sieci podczas ładowania kategorii: $e';
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj nowy produkt'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading || _isLoadingCategories ? null : _saveProduct,
            child: Text(
              'ZAPISZ',
              style: TextStyle(
                color: _isLoading || _isLoadingCategories ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categoryLoadError != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sekcja: Podstawowe informacje
                        _buildSectionHeader('Podstawowe informacje', Icons.info),
                        const SizedBox(height: 12),
                        
                        // Nazwa produktu
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa produktu *',
                            hintText: 'np. Laptop Dell XPS 13',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory_2),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nazwa produktu jest wymagana';
                            }
                            if (value.trim().length < 3) {
                              return 'Nazwa musi mieć co najmniej 3 znaki';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Kod produktu
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Kod produktu',
                            hintText: 'np. DELL-XPS13-001',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),

                        // Kategorie z API
                        const Text(
                          'Kategorie (wymagane) *',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        
                        _availableCategories.isEmpty
                            ? const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Brak dostępnych kategorii. Dodaj kategorie w systemie.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : Card(
                                child: Column(
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
                              ),
                        const SizedBox(height: 16),

                        // Opis
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Opis',
                            hintText: 'Szczegółowy opis produktu...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sekcja: Magazyn
                        _buildSectionHeader('Informacje magazynowe', Icons.warehouse),
                        const SizedBox(height: 12),

                        // Stan początkowy
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stan początkowy *',
                            hintText: '0',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                            suffixText: 'szt.',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Wprowadź stan początkowy';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity < 0) {
                              return 'Wprowadź prawidłową liczbę (≥ 0)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Minimalny stan
                        TextFormField(
                          controller: _minStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimalny stan magazynowy *',
                            hintText: '5',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.warning_amber),
                            suffixText: 'szt.',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Wprowadź minimalny stan';
                            }
                            final minStock = int.tryParse(value);
                            if (minStock == null || minStock < 0) {
                              return 'Wprowadź prawidłową liczbę (≥ 0)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Lokalizacja
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Lokalizacja w magazynie *',
                            hintText: 'np. A-1-3 (Magazyn-Regał-Półka)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Lokalizacja jest wymagana';
                            }
                            // Prosta walidacja formatu lokalizacji (X-Y-Z)
                            if (!RegExp(r'^[A-Z]-\d+-\d+$').hasMatch(value.trim().toUpperCase())) {
                              return 'Format: A-1-3 (Magazyn-Regał-Półka)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Sekcja: Dodatkowe informacje
                        _buildSectionHeader('Dodatkowe informacje', Icons.straighten),
                        const SizedBox(height: 12),

                        // Wymiary
                        TextFormField(
                          controller: _dimensionsController,
                          decoration: const InputDecoration(
                            labelText: 'Wymiary',
                            hintText: 'np. 30x20x5 cm',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.straighten),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Przyciski akcji
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                child: const Text('ANULUJ'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('DODAJ PRODUKT'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Informacja o polach wymaganych
                        Text(
                          '* Pola wymagane',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _categoryLoadError!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoadingCategories = true;
                _categoryLoadError = null;
              });
              _fetchCategories();
            },
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.blue[200])),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sprawdź poprawność wszystkich pól'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Sprawdzenie czy wybrano kategorię
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz przynajmniej jedną kategorię'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await TokenService.getToken();
      
      // Przygotowanie wymiarów
      Map<String, int>? dimensions;
      if (_dimensionsController.text.trim().isNotEmpty) {
        // Można dodać parsing wymiarów, na razie domyślne wartości
        dimensions = {
          'x': 0,
          'y': 0,
          'z': 0,
        };
      }

      print('🚀 Sending product to API...');
      print('Name: ${_nameController.text.trim()}');
      print('Category IDs: $_selectedCategoryIds');

      final response = await http.post(
        Uri.parse('http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty 
              ? 'Brak opisu' 
              : _descriptionController.text.trim(),
          'categoryIds': _selectedCategoryIds,
          'dimensions': dimensions,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Produkt "${_nameController.text.trim()}" został dodany!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true); // Odśwież listę
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd podczas dodawania produktu (${response.statusCode})'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      print('❌ Error adding product: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd połączenia: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}