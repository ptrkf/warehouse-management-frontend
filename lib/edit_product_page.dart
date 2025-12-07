import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

class EditProductPage extends StatefulWidget {
  final int productId;
  final String? initialName;
  final String? initialCategory;
  final Map<String, int>? initialDimensions;

  const EditProductPage({
    super.key,
    required this.productId,
    this.initialName,
    this.initialCategory,
    this.initialDimensions,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  int? _dimX;
  int? _dimY;
  int? _dimZ;

  List<Category> _availableCategories = [];
  List<int> _selectedCategoryIds = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _categoryLoadError;

  final String _apiProductUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/products';
  final String _apiCategoryUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/categories';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    
    if (widget.initialDimensions != null) {
      _dimX = widget.initialDimensions!['x'];
      _dimY = widget.initialDimensions!['y'];
      _dimZ = widget.initialDimensions!['z'];
    }
    
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            
            // Jeśli mamy nazwę kategorii, znajdź jej ID
            if (widget.initialCategory != null && _selectedCategoryIds.isEmpty) {
              final matchingCategory = _availableCategories.where(
                (cat) => cat.name.toLowerCase() == widget.initialCategory!.toLowerCase()
              ).firstOrNull;
              
              if (matchingCategory != null) {
                _selectedCategoryIds = [matchingCategory.id];
              }
            }
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

      setState(() => _isSaving = true);
      
      final Map<String, dynamic> productData = {
        'name': _nameController.text,
        'dimensions': {
          'x': _dimX,
          'y': _dimY,
          'z': _dimZ,
        },
        'categoryIds': _selectedCategoryIds,
      };

      final token = await TokenService.getToken();
      if (token == null) {
        setState(() => _isSaving = false);
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
        final response = await http.put(
          Uri.parse('$_apiProductUrl/${widget.productId}'),
          headers: headers,
          body: json.encode(productData),
        );

        setState(() => _isSaving = false);

        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produkt zaktualizowany pomyślnie!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Zwracamy true, żeby odświeżyć listę
        } else {
          String errorMessage = 'Błąd aktualizacji: ${response.statusCode}';
          
          // Próbujemy zdekodować błąd z odpowiedzi
          try {
            final errorData = json.decode(response.body);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {
            // Ignorujemy błędy parsowania
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd sieci: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    // Pokazujemy dialog potwierdzenia
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Usuń produkt'),
          ],
        ),
        content: Text('Czy na pewno chcesz usunąć produkt "${_nameController.text}"?\n\nTa akcja jest nieodwracalna!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('USUŃ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    final token = await TokenService.getToken();
    if (token == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Błąd: Wymagane jest zalogowanie.')),
      );
      return; 
    }

    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      // Uwaga: API może nie mieć DELETE endpointu - sprawdź w Swaggerze
      final response = await http.delete(
        Uri.parse('$_apiProductUrl/${widget.productId}'),
        headers: headers,
      );

      setState(() => _isSaving = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produkt usunięty pomyślnie!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Zwracamy true, żeby odświeżyć listę
      } else {
        String errorMessage = 'Błąd usuwania: ${response.statusCode}';
        
        if (response.statusCode == 404) {
          errorMessage = 'Funkcja usuwania nie jest dostępna.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Brak uprawnień do usunięcia produktu.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd sieci: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edytuj Produkt'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isSaving ? null : _deleteProduct,
            tooltip: 'Usuń produkt',
          ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categoryLoadError != null
              ? Center(
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
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa Produktu',
                            hintText: 'Np. Laptop X-100',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory_2),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nazwa jest wymagana.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Wymiary (w milimetrach):',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(child: _buildDimensionField('X', _dimX, (val) => _dimX = val)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildDimensionField('Y', _dimY, (val) => _dimY = val)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildDimensionField('Z', _dimZ, (val) => _dimZ = val)),
                          ],
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'Kategorie (wymagane):',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        
                        Card(
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

                        const SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: _isSaving ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'ZAPISZ ZMIANY',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildDimensionField(String label, int? initialValue, Function(int?) onSave) {
    return TextFormField(
      initialValue: initialValue?.toString(),
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
      onChanged: (value) {
        onSave(int.tryParse(value));
      },
    );
  }
}